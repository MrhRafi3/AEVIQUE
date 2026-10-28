import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/edit_state.dart';
import '../native_engine/aevique_ffi.dart';
import 'filter_kernels.dart';
import 'lut_generator.dart';
import 'portrait_engine.dart';

class PreprocessedImageBundle {
  final img.Image previewImage;
  final img.Image thumbnailImage;
  final Uint8List originalPreviewBytes;
  final Uint8List? rawPreviewRgba8;

  const PreprocessedImageBundle({
    required this.previewImage,
    required this.thumbnailImage,
    required this.originalPreviewBytes,
    this.rawPreviewRgba8,
  });
}

/// Result of rendering an editing preview frame, either via native raw RGBA or Dart fallback JPEG.
class PreviewFrame {
  final ui.Image? uiImage;
  final Uint8List? jpegBytes;
  final bool isNative;
  final double renderLatencyMs;

  const PreviewFrame.native({
    required ui.Image this.uiImage,
    this.renderLatencyMs = 0.0,
  })  : jpegBytes = null,
        isNative = true;

  const PreviewFrame.fallback({
    required Uint8List this.jpegBytes,
    this.renderLatencyMs = 0.0,
  })  : uiImage = null,
        isNative = false;

  void dispose() {
    uiImage?.dispose();
  }
}

class ImagePipeline {
  /// Decodes and downscales source bytes once into a cached preview and thumbnail bundle.
  static Future<PreprocessedImageBundle> prepareImageBundle(
    Uint8List sourceBytes, {
    int maxPreviewDimension = 1200,
    int thumbnailDimension = 80,
  }) async {
    return compute(
      _isolatePrepareBundle,
      _PrepareBundleTask(
        bytes: sourceBytes,
        maxPreviewDimension: maxPreviewDimension,
        thumbnailDimension: thumbnailDimension,
      ),
    );
  }

  /// Asynchronously processes source image bytes through the non-destructive edit pipeline.
  /// Used for full-resolution rendering on export.
  static Future<Uint8List> processImage(
    Uint8List sourceBytes,
    EditState state, {
    int? maxDimension,
    int jpegQuality = 92,
    bool outputPng = false,
  }) async {
    if (AeviqueNativeEngine.engineMode == EngineMode.nativeOnly) {
      if (!AeviqueNativeEngine.isAvailable) {
        throw StateError(
          'EngineMode.nativeOnly requested but native library is unavailable or not loaded.',
        );
      }
      if (!isNativePhase3Compatible(state)) {
        throw UnsupportedError(
          'EngineMode.nativeOnly requested but EditState contains adjustments unsupported by native image core.',
        );
      }
    }

    return compute(
      _isolateProcessEntry,
      _PipelineTask(
        bytes: sourceBytes,
        state: state,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
        outputPng: outputPng,
        customLibraryPath: AeviqueNativeEngine.activeLibraryPath,
        engineMode: AeviqueNativeEngine.engineMode,
      ),
    );
  }

  /// Rapidly processes an in-memory preview image for slider interactivity.
  static Future<Uint8List> processPreviewFast(
    img.Image previewBase,
    EditState state, {
    int jpegQuality = 88,
  }) async {
    if (state.isIdentity) {
      // Identity state requires zero pixel changes - fast return
      return Uint8List.fromList(img.encodeJpg(previewBase, quality: 95));
    }

    return compute(
      _isolateProcessFastEntry,
      _FastPipelineTask(
        image: previewBase,
        state: state,
        jpegQuality: jpegQuality,
      ),
    );
  }

  /// Checks whether an EditState is purely composed of Phase 1 native adjustments
  /// (Exposure, Contrast, Saturation) with no other effects, curves, portrait, or filters.
  static bool isNativePhase1Compatible(EditState state) {
    if (state.filterId != null || state.presetName != null) return false;
    if (!state.details.isIdentity) return false;
    if (!state.curves.isIdentity) return false;
    if (!state.vignette.isIdentity) return false;
    if (!state.geometry.isIdentity) return false;
    if (!state.effects.isIdentity) return false;
    if (!state.portrait.isIdentity) return false;

    final t = state.tune;
    if (t.brightness != 0.0 ||
        t.vibrance != 0.0 ||
        t.ambiance != 0.0 ||
        t.highlights != 0.0 ||
        t.shadows != 0.0 ||
        t.whites != 0.0 ||
        t.blacks != 0.0 ||
        t.warmth != 0.0 ||
        t.tint != 0.0 ||
        t.clarity != 0.0) {
      return false;
    }

    return true;
  }

  /// Checks whether an EditState is supported by Phase 3 advanced native tone engine
  /// (Exposure, Contrast, Saturation, Brightness, Warmth, Tint, Highlights, Shadows,
  /// Whites, Blacks, Ambiance, and Tone Curves).
  static bool isNativePhase3Compatible(EditState state) {
    if (state.filterId != null || state.presetName != null) return false;
    if (!state.details.isIdentity) return false;
    if (!state.vignette.isIdentity) return false;
    if (!state.geometry.isIdentity) return false;
    if (!state.effects.isIdentity) return false;
    if (!state.portrait.isIdentity) return false;

    final t = state.tune;
    // Vibrance and Clarity are deferred to Phase 4/5
    if (t.vibrance != 0.0 || t.clarity != 0.0) {
      return false;
    }

    return true;
  }

  /// Alias for the latest native engine compatibility check.
  static bool isNativeCompatible(EditState state) => isNativePhase3Compatible(state);

  /// Asynchronously decodes raw RGBA8 bytes directly into a GPU-backed [ui.Image],
  /// bypassing any intermediate JPEG compression.
  static Future<ui.Image> decodeRgbaPixels(
    Uint8List rgbaBytes,
    int width,
    int height,
  ) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgbaBytes,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        completer.complete(image);
      },
    );
    return completer.future;
  }

  /// Renders a preview frame using the native C++ engine with direct raw RGBA GPU decoding
  /// if compatible and available, otherwise falling back seamlessly to the Dart pipeline with JPEG output.
  static Future<PreviewFrame> renderPreviewFrame({
    required img.Image previewBase,
    required Uint8List? rawPreviewRgba8,
    required EditState state,
    int jpegQuality = 90,
  }) async {
    final sw = Stopwatch()..start();

    // Check if eligible for native Phase 3 RGBA fast path
    if (AeviqueNativeEngine.isAvailable &&
        rawPreviewRgba8 != null &&
        isNativePhase3Compatible(state)) {
      try {
        final engine = AeviqueNativeEngine.instance;
        if (engine != null) {
          final processedRgba = engine.processRgba8(
            rgbaBytes: rawPreviewRgba8,
            width: previewBase.width,
            height: previewBase.height,
            exposure: state.tune.exposure,
            contrast: state.tune.contrast,
            saturation: state.tune.saturation,
            brightness: state.tune.brightness,
            warmth: state.tune.warmth,
            tint: state.tune.tint,
            highlights: state.tune.highlights,
            shadows: state.tune.shadows,
            whites: state.tune.whites,
            blacks: state.tune.blacks,
            ambiance: state.tune.ambiance,
            curves: state.curves,
            inPlace: false,
          );

          final uiImage = await decodeRgbaPixels(
            processedRgba,
            previewBase.width,
            previewBase.height,
          );
          sw.stop();
          return PreviewFrame.native(
            uiImage: uiImage,
            renderLatencyMs: sw.elapsedMicroseconds / 1000.0,
          );
        }
      } catch (e) {
        if (AeviqueNativeEngine.engineMode == EngineMode.nativeOnly) {
          rethrow;
        }
        // Fall back gracefully to Dart on any native error in auto mode
      }
    }

    if (AeviqueNativeEngine.engineMode == EngineMode.nativeOnly) {
      if (!AeviqueNativeEngine.isAvailable) {
        throw StateError(
          'EngineMode.nativeOnly requested but native library is unavailable or not loaded.',
        );
      }
      if (rawPreviewRgba8 == null) {
        throw StateError(
          'EngineMode.nativeOnly requested but rawPreviewRgba8 buffer is null.',
        );
      }
      if (!isNativePhase3Compatible(state)) {
        throw UnsupportedError(
          'EngineMode.nativeOnly requested but EditState contains adjustments unsupported by native image core.',
        );
      }
    }

    // Fallback: Pure Dart isolate pipeline (returns encoded JPEG)
    final jpegBytes = await processPreviewFast(
      previewBase,
      state,
      jpegQuality: jpegQuality,
    );
    sw.stop();
    return PreviewFrame.fallback(
      jpegBytes: jpegBytes,
      renderLatencyMs: sw.elapsedMicroseconds / 1000.0,
    );
  }

  /// Synchronously processes an image through the full pipeline
  static img.Image processRawImage(
    img.Image source,
    EditState state, {
    int? maxDimension,
  }) {
    var working = img.Image.from(source);

    // Fast path: if state is completely neutral, return copy untouched
    if (state.isIdentity && maxDimension == null) {
      return working;
    }

    // 1. Geometry: Rotation and Flips
    if (state.geometry.rotationQuarterTurns % 4 != 0) {
      final angle = (state.geometry.rotationQuarterTurns % 4) * 90;
      working = img.copyRotate(working, angle: angle);
    }
    if (state.geometry.flipHorizontal) {
      working = img.flipHorizontal(working);
    }
    if (state.geometry.flipVertical) {
      working = img.flipVertical(working);
    }

    // 2. Geometry: Crop
    if (state.geometry.hasCrop) {
      final x = (state.geometry.cropLeft * working.width).round().clamp(
        0,
        working.width - 1,
      );
      final y = (state.geometry.cropTop * working.height).round().clamp(
        0,
        working.height - 1,
      );
      final w =
          ((state.geometry.cropRight - state.geometry.cropLeft) * working.width)
              .round()
              .clamp(1, working.width - x);
      final h =
          ((state.geometry.cropBottom - state.geometry.cropTop) *
                  working.height)
              .round()
              .clamp(1, working.height - y);

      working = img.copyCrop(working, x: x, y: y, width: w, height: h);
    }

    // 3. Optional downscale
    if (maxDimension != null &&
        (working.width > maxDimension || working.height > maxDimension)) {
      if (working.width >= working.height) {
        final targetH = (working.height * (maxDimension / working.width))
            .round();
        working = img.copyResize(
          working,
          width: maxDimension,
          height: math.max(1, targetH),
        );
      } else {
        final targetW = (working.width * (maxDimension / working.height))
            .round();
        working = img.copyResize(
          working,
          width: math.max(1, targetW),
          height: maxDimension,
        );
      }
    }

    // 4. Portrait Retouching (Blemish healing, edge-preserving skin smooth, radiant midtone brightening)
    if (!state.portrait.isIdentity) {
      PortraitEngine.applyPortrait(working, state.portrait);
    }

    // 5. Tone Adjustments & Curves via LUT (only if modified)
    if (!state.tune.isIdentity || !state.curves.isIdentity) {
      final luts = LutGenerator.generate(state.tune, state.curves);
      final rLut = luts.rLut;
      final gLut = luts.gLut;
      final bLut = luts.bLut;

      for (final pixel in working) {
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        pixel.r = rLut[r];
        pixel.g = gLut[g];
        pixel.b = bLut[b];
      }
    }

    // 5. Vibrance (preserves skin tones) & Clarity (local midtone contrast)
    if (state.tune.vibrance != 0.0) {
      FilterKernels.applyVibrance(working, state.tune.vibrance);
    }
    if (state.tune.clarity != 0.0) {
      FilterKernels.applyClarity(working, state.tune.clarity);
    }

    // 6. Global Saturation & B/W
    if (state.tune.saturation != 0.0 || state.effects.bwMode) {
      FilterKernels.applySaturationAndBw(
        working,
        state.tune.saturation,
        state.effects.bwMode,
      );
    }

    // 7. Photographic Style Effects (only if active)
    if (state.effects.vintage != 0.0) {
      FilterKernels.applyVintage(working, state.effects.vintage);
    }
    if (state.effects.drama != 0.0) {
      FilterKernels.applyDrama(working, state.effects.drama);
    }
    if (state.effects.bloom != 0.0) {
      FilterKernels.applyBloom(working, state.effects.bloom);
    }
    if (state.effects.chromaticAberration != 0.0) {
      FilterKernels.applyChromaticAberration(
        working,
        state.effects.chromaticAberration,
      );
    }
    if (state.effects.grain != 0.0) {
      FilterKernels.applyFilmGrain(working, state.effects.grain);
    }

    // 8. Vignette
    if (!state.vignette.isIdentity) {
      FilterKernels.applyVignette(working, state.vignette);
    }

    // 9. Details (Structure & Sharpening)
    if (state.details.structure != 0.0) {
      FilterKernels.applyStructure(working, state.details.structure);
    }
    if (state.details.sharpening != 0.0) {
      FilterKernels.applySharpening(working, state.details.sharpening);
    }

    return working;
  }

  /// Inspects magic headers to identify image format (JPEG, PNG, HEIC/HEIF, WebP).
  static String identifyFormat(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'png';
    }
    if (bytes.length >= 12) {
      final header = String.fromCharCodes(bytes.sublist(4, 12));
      if (header.contains('ftyp')) {
        return 'heic';
      }
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      final webp = String.fromCharCodes(bytes.sublist(8, 12));
      if (riff == 'RIFF' && webp == 'WEBP') {
        return 'webp';
      }
    }
    return 'unknown';
  }
}

class _PrepareBundleTask {
  final Uint8List bytes;
  final int maxPreviewDimension;
  final int thumbnailDimension;

  _PrepareBundleTask({
    required this.bytes,
    required this.maxPreviewDimension,
    required this.thumbnailDimension,
  });
}

PreprocessedImageBundle _isolatePrepareBundle(_PrepareBundleTask task) {
  final decoded = img.decodeImage(task.bytes);
  if (decoded == null) {
    final format = ImagePipeline.identifyFormat(task.bytes);
    if (format == 'heic') {
      throw Exception(
        'HEIC/HEIF images require JPEG or PNG conversion before editing.',
      );
    }
    throw Exception('Failed to decode image data (detected format: $format).');
  }

  // Generate downscaled preview
  img.Image preview;
  if (decoded.width > task.maxPreviewDimension ||
      decoded.height > task.maxPreviewDimension) {
    if (decoded.width >= decoded.height) {
      final h = (decoded.height * (task.maxPreviewDimension / decoded.width))
          .round();
      preview = img.copyResize(
        decoded,
        width: task.maxPreviewDimension,
        height: math.max(1, h),
      );
    } else {
      final w = (decoded.width * (task.maxPreviewDimension / decoded.height))
          .round();
      preview = img.copyResize(
        decoded,
        width: math.max(1, w),
        height: task.maxPreviewDimension,
      );
    }
  } else {
    preview = decoded;
  }

  // Generate tiny thumbnail for live filter carousel previews
  final thumb = img.copyResize(
    preview,
    width: task.thumbnailDimension,
    height: task.thumbnailDimension,
  );

  final origPreviewBytes = Uint8List.fromList(
    img.encodeJpg(preview, quality: 95),
  );

  final rgbaPreview = preview.convert(numChannels: 4);
  final rawRgba = rgbaPreview.toUint8List();

  return PreprocessedImageBundle(
    previewImage: preview,
    thumbnailImage: thumb,
    originalPreviewBytes: origPreviewBytes,
    rawPreviewRgba8: rawRgba,
  );
}

class _PipelineTask {
  final Uint8List bytes;
  final EditState state;
  final int? maxDimension;
  final int jpegQuality;
  final bool outputPng;
  final String? customLibraryPath;
  final EngineMode engineMode;

  _PipelineTask({
    required this.bytes,
    required this.state,
    this.maxDimension,
    this.jpegQuality = 92,
    this.outputPng = false,
    this.customLibraryPath,
    this.engineMode = EngineMode.auto,
  });
}

Uint8List _isolateProcessEntry(_PipelineTask task) {
  // 1. Initialize native engine state in the background isolate
  if (task.engineMode != EngineMode.dartOnly) {
    AeviqueNativeEngine.tryLoad(customLibraryPath: task.customLibraryPath);
    AeviqueNativeEngine.engineMode = task.engineMode;
  } else {
    AeviqueNativeEngine.engineMode = EngineMode.dartOnly;
  }

  // 2. Decode the image
  final decoded = img.decodeImage(task.bytes);
  if (decoded == null) {
    throw Exception('Failed to decode image data');
  }

  // 3. Strict nativeOnly validation
  if (task.engineMode == EngineMode.nativeOnly) {
    if (!AeviqueNativeEngine.isAvailable) {
      throw StateError(
        'EngineMode.nativeOnly requested but native library is unavailable or not loaded in export isolate.',
      );
    }
    if (!ImagePipeline.isNativePhase3Compatible(task.state)) {
      throw UnsupportedError(
        'EngineMode.nativeOnly requested but EditState contains adjustments unsupported by native image core.',
      );
    }
  }

  // 4. Native Full-Resolution Export Fast Path
  if (AeviqueNativeEngine.isAvailable &&
      ImagePipeline.isNativePhase3Compatible(task.state)) {
    try {
      final engine = AeviqueNativeEngine.instance;
      if (engine != null) {
        var working = decoded;

        // Downscale if requested
        if (task.maxDimension != null &&
            (working.width > task.maxDimension! || working.height > task.maxDimension!)) {
          if (working.width >= working.height) {
            final targetH = (working.height * (task.maxDimension! / working.width)).round();
            working = img.copyResize(
              working,
              width: task.maxDimension!,
              height: math.max(1, targetH),
            );
          } else {
            final targetW = (working.width * (task.maxDimension! / working.height)).round();
            working = img.copyResize(
              working,
              width: math.max(1, targetW),
              height: task.maxDimension!,
            );
          }
        }

        // Use 4 channels for PNG (or images with alpha), 3 channels for standard JPEG export
        final numChannels = (task.outputPng || (working.numChannels == 4 && working.hasAlpha)) ? 4 : 3;
        final rawBytes = (working.numChannels == numChannels)
            ? working.toUint8List()
            : working.convert(numChannels: numChannels).toUint8List();

        // Process in-place through native C++ tone & curves engine
        final processedBytes = engine.processRgba8(
          rgbaBytes: rawBytes,
          width: working.width,
          height: working.height,
          exposure: task.state.tune.exposure,
          contrast: task.state.tune.contrast,
          saturation: task.state.tune.saturation,
          brightness: task.state.tune.brightness,
          warmth: task.state.tune.warmth,
          tint: task.state.tune.tint,
          highlights: task.state.tune.highlights,
          shadows: task.state.tune.shadows,
          whites: task.state.tune.whites,
          blacks: task.state.tune.blacks,
          ambiance: task.state.tune.ambiance,
          curves: task.state.curves,
          inPlace: true,
          numChannels: numChannels,
        );

        final resultImage = img.Image.fromBytes(
          width: working.width,
          height: working.height,
          bytes: processedBytes.buffer,
          numChannels: numChannels,
          order: (numChannels == 4) ? img.ChannelOrder.rgba : img.ChannelOrder.rgb,
        );

        if (task.outputPng) {
          return Uint8List.fromList(img.encodePng(resultImage));
        } else {
          return Uint8List.fromList(
            img.encodeJpg(resultImage, quality: task.jpegQuality),
          );
        }
      }
    } catch (e) {
      if (task.engineMode == EngineMode.nativeOnly) {
        rethrow;
      }
      // In auto mode, fall through to Dart fallback
    }
  }

  // 5. Dart Fallback Pipeline
  final processed = ImagePipeline.processRawImage(
    decoded,
    task.state,
    maxDimension: task.maxDimension,
  );

  if (task.outputPng) {
    return Uint8List.fromList(img.encodePng(processed));
  } else {
    return Uint8List.fromList(
      img.encodeJpg(processed, quality: task.jpegQuality),
    );
  }
}

class _FastPipelineTask {
  final img.Image image;
  final EditState state;
  final int jpegQuality;

  _FastPipelineTask({
    required this.image,
    required this.state,
    required this.jpegQuality,
  });
}

Uint8List _isolateProcessFastEntry(_FastPipelineTask task) {
  final processed = ImagePipeline.processRawImage(task.image, task.state);
  return Uint8List.fromList(
    img.encodeJpg(processed, quality: task.jpegQuality),
  );
}
