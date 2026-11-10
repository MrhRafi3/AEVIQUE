import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../native_engine/lumafix_ffi.dart';
import 'filter_kernels.dart';

/// Represents the output of on-device subject segmentation.
class SubjectSegmentationResult {
  final Uint8List maskBytes;
  final int width;
  final int height;

  const SubjectSegmentationResult({
    required this.maskBytes,
    required this.width,
    required this.height,
  });

  /// Returns the 8-bit alpha value [0 .. 255] for coordinate (x, y).
  int getPixelAlpha(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0;
    return maskBytes[y * width + x];
  }
}

/// On-Device Human Subject Auto-Selection Service.
///
/// Multi-tiered architecture:
/// 1. Hardware-Accelerated Apple Vision Neural Engine on macOS & iOS (`VNGeneratePersonSegmentationRequest`)
/// 2. Portable Native C++ Saliency & Skin Chrominance Segmentation on Android & Linux
/// 3. Pure Dart On-Device Segmentation Fallback for headless environments & tests
///
/// 100% on-device. Zero cloud APIs, zero external network communication.
class SubjectSegmentationService {
  /// Segments the primary human subject from [image] on-device.
  static Future<SubjectSegmentationResult> segmentSubject(
    img.Image image, {
    int? targetWidth,
    int? targetHeight,
  }) async {
    final outW = targetWidth ?? image.width;
    final outH = targetHeight ?? image.height;

    // 1. Try Native Engine (Apple Vision or Native C++)
    if (LumaFixNativeEngine.isAvailable &&
        LumaFixNativeEngine.engineMode != EngineMode.dartOnly) {
      try {
        final engine = LumaFixNativeEngine.instance;
        if (engine != null) {
          final totalPixels = image.width * image.height;
          final rgbaBytes = Uint8List(totalPixels * 4);
          var idx = 0;
          for (final pixel in image) {
            rgbaBytes[idx] = pixel.r.toInt();
            rgbaBytes[idx + 1] = pixel.g.toInt();
            rgbaBytes[idx + 2] = pixel.b.toInt();
            rgbaBytes[idx + 3] = pixel.a.toInt();
            idx += 4;
          }

          final maskBytes = engine.segmentPersonRgba8(
            rgbaBytes: rgbaBytes,
            width: image.width,
            height: image.height,
            outWidth: outW,
            outHeight: outH,
          );

          return SubjectSegmentationResult(
            maskBytes: maskBytes,
            width: outW,
            height: outH,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LUMAFIX-VISION] Native segmentation fallback to Dart: $e');
        }
      }
    }

    // 2. Pure Dart On-Device Segmentation Fallback
    return _segmentDartFallback(image, outW, outH);
  }

  static SubjectSegmentationResult _segmentDartFallback(
    img.Image image,
    int outW,
    int outH,
  ) {
    final inW = image.width;
    final inH = image.height;
    final skinMap = Float32List(outW * outH);
    final maskBytes = Uint8List(outW * outH);

    double sumX = 0.0;
    double sumY = 0.0;
    double totalSkin = 0.0;

    for (var y = 0; y < outH; y++) {
      final srcY = ((y * inH) / outH).floor().clamp(0, inH - 1);
      final rowOffset = y * outW;
      for (var x = 0; x < outW; x++) {
        final srcX = ((x * inW) / outW).floor().clamp(0, inW - 1);
        final pixel = image.getPixel(srcX, srcY);
        final r = (pixel.r / 255.0).clamp(0.0, 1.0);
        final g = (pixel.g / 255.0).clamp(0.0, 1.0);
        final b = (pixel.b / 255.0).clamp(0.0, 1.0);

        final prob = FilterKernels.computeSkinProbability(r, g, b);
        skinMap[rowOffset + x] = prob;
        if (prob > 0.2) {
          sumX += x * prob;
          sumY += y * prob;
          totalSkin += prob;
        }
      }
    }

    final cx = totalSkin > 10.0 ? (sumX / totalSkin) : (outW * 0.5);
    final cy = totalSkin > 10.0 ? (sumY / totalSkin) : (outH * 0.4);

    final sigmaX = outW * 0.32;
    final sigmaY = outH * 0.38;

    for (var y = 0; y < outH; y++) {
      var dy = (y - cy) / sigmaY;
      if (dy > 0.0) dy *= 0.65; // Asymmetric torso extension downwards
      final rowOffset = y * outW;
      for (var x = 0; x < outW; x++) {
        final dx = (x - cx) / sigmaX;
        final spatialPrior = math.exp(-0.5 * (dx * dx + dy * dy));

        final skinProb = skinMap[rowOffset + x];
        final subjectScore = spatialPrior * 0.55 + skinProb * 0.70;

        if (subjectScore > 0.25) {
          final alpha = ((subjectScore - 0.25) / 0.25).clamp(0.0, 1.0);
          maskBytes[rowOffset + x] = (alpha * 255.0).round().clamp(0, 255);
        } else {
          maskBytes[rowOffset + x] = 0;
        }
      }
    }

    return SubjectSegmentationResult(
      maskBytes: maskBytes,
      width: outW,
      height: outH,
    );
  }
}
