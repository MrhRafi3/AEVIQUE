import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/edit_state.dart';
import 'filter_kernels.dart';
import 'lut_generator.dart';

class ImagePipeline {
  /// Asynchronously processes source image bytes through the non-destructive edit pipeline.
  /// If [maxDimension] is provided, the image is downscaled for rapid preview editing.
  static Future<Uint8List> processImage(
    Uint8List sourceBytes,
    EditState state, {
    int? maxDimension,
    int jpegQuality = 90,
    bool outputPng = false,
  }) async {
    // For small or moderate workloads, compute asynchronously
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

  /// Synchronously processes an image through the full pipeline
  static img.Image processRawImage(
    img.Image source,
    EditState state, {
    int? maxDimension,
  }) {
    var working = img.Image.from(source);

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

    // 3. Optional downscale for fast interactive preview rendering
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

    // 4. Tone Adjustments & Curves via LUT
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

    // 5. Saturation & B/W
    FilterKernels.applySaturationAndBw(
      working,
      state.tune.saturation,
      state.effects.bwMode,
    );

    // 6. Photographic Style Effects
    FilterKernels.applyVintage(working, state.effects.vintage);
    FilterKernels.applyDrama(working, state.effects.drama);
    FilterKernels.applyBloom(working, state.effects.bloom);
    FilterKernels.applyChromaticAberration(
      working,
      state.effects.chromaticAberration,
    );
    FilterKernels.applyFilmGrain(working, state.effects.grain);

    // 7. Vignette
    FilterKernels.applyVignette(working, state.vignette);

    // 8. Details (Sharpening and Structure)
    FilterKernels.applyStructure(working, state.details.structure);
    FilterKernels.applySharpening(working, state.details.sharpening);

    return working;
  }
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
    this.jpegQuality = 90,
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
