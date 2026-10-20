import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/edit_state.dart';
import 'filter_kernels.dart';
import 'lut_generator.dart';

class PreprocessedImageBundle {
  final img.Image previewImage;
  final img.Image thumbnailImage;
  final Uint8List originalPreviewBytes;

  const PreprocessedImageBundle({
    required this.previewImage,
    required this.thumbnailImage,
    required this.originalPreviewBytes,
  });
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
    return compute(
      _isolateProcessEntry,
      _PipelineTask(
        bytes: sourceBytes,
        state: state,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
        outputPng: outputPng,
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

    // 4. Tone Adjustments & Curves via LUT (only if modified)
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
    throw Exception('Failed to decode image');
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

  return PreprocessedImageBundle(
    previewImage: preview,
    thumbnailImage: thumb,
    originalPreviewBytes: origPreviewBytes,
  );
}

class _PipelineTask {
  final Uint8List bytes;
  final EditState state;
  final int? maxDimension;
  final int jpegQuality;
  final bool outputPng;

  _PipelineTask({
    required this.bytes,
    required this.state,
    this.maxDimension,
    this.jpegQuality = 92,
    this.outputPng = false,
  });
}

Uint8List _isolateProcessEntry(_PipelineTask task) {
  final decoded = img.decodeImage(task.bytes);
  if (decoded == null) {
    throw Exception('Failed to decode image data');
  }

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
