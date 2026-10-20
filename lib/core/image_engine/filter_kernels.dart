import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/edit_state.dart';

class FilterKernels {
  /// Adjusts image saturation and applies B&W monochrome conversion
  static void applySaturationAndBw(
    img.Image image,
    double saturation, // -100 .. 100
    bool bwMode,
  ) {
    if (saturation == 0.0 && !bwMode) return;

    final satFactor = bwMode
        ? 0.0
        : ((saturation + 100.0) / 100.0).clamp(0.0, 3.0);

    for (final pixel in image) {
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;

      // Rec. 709 Luminance weights
      final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b);

      if (bwMode) {
        final gray = lum.round().clamp(0, 255);
        pixel.r = gray;
        pixel.g = gray;
        pixel.b = gray;
      } else {
        pixel.r = (lum + (r - lum) * satFactor).round().clamp(0, 255);
        pixel.g = (lum + (g - lum) * satFactor).round().clamp(0, 255);
        pixel.b = (lum + (b - lum) * satFactor).round().clamp(0, 255);
      }
    }
  }

  /// Applies unsharp mask sharpening
  static void applySharpening(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final factor = (strength / 100.0) * 1.5;
    // Create copy for blurred reference
    final blurred = img.copyResize(
      image,
      width: image.width ~/ 2,
      height: image.height ~/ 2,
    );
    final upscaled = img.copyResize(
      blurred,
      width: image.width,
      height: image.height,
    );

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final orig = image.getPixel(x, y);
        final blurPix = upscaled.getPixel(x, y);

        final newR = (orig.r + (orig.r - blurPix.r) * factor).round().clamp(
          0,
          255,
        );
        final newG = (orig.g + (orig.g - blurPix.g) * factor).round().clamp(
          0,
          255,
        );
        final newB = (orig.b + (orig.b - blurPix.b) * factor).round().clamp(
          0,
          255,
        );

        orig.r = newR;
        orig.g = newG;
        orig.b = newB;
      }
    }
  }

  /// Enhances local midtone micro-contrast (structure)
  static void applyStructure(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final factor = (strength / 100.0) * 0.8;
    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        final p = image.getPixel(x, y);
        final pLeft = image.getPixel(x - 1, y);
        final pRight = image.getPixel(x + 1, y);
        final pUp = image.getPixel(x, y - 1);
        final pDown = image.getPixel(x, y + 1);

        final avgR = (pLeft.r + pRight.r + pUp.r + pDown.r) * 0.25;
        final avgG = (pLeft.g + pRight.g + pUp.g + pDown.g) * 0.25;
        final avgB = (pLeft.b + pRight.b + pUp.b + pDown.b) * 0.25;

        p.r = (p.r + (p.r - avgR) * factor).round().clamp(0, 255);
        p.g = (p.g + (p.g - avgG) * factor).round().clamp(0, 255);
        p.b = (p.b + (p.b - avgB) * factor).round().clamp(0, 255);
      }
    }
  }

  /// Radial vignette falloff
  static void applyVignette(img.Image image, VignetteAdjustments v) {
    if (v.isIdentity) return;

    final w = image.width;
    final h = image.height;
    final cx = v.centerX * w;
    final cy = v.centerY * h;
    final maxDist = math.sqrt(cx * cx + cy * cy);
    final rad = (v.radius / 100.0) * maxDist;
    final feather = math.max(1.0, (v.feather / 100.0) * maxDist);
    final intensity = (v.amount / 100.0);

    for (var y = 0; y < h; y++) {
      final dy = y - cy;
      for (var x = 0; x < w; x++) {
        final dx = x - cx;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist > rad) {
          final t = ((dist - rad) / feather).clamp(0.0, 1.0);
          final factor = (1.0 + intensity * t * t).clamp(0.0, 2.0);

          final p = image.getPixel(x, y);
          p.r = (p.r * factor).round().clamp(0, 255);
          p.g = (p.g * factor).round().clamp(0, 255);
          p.b = (p.b * factor).round().clamp(0, 255);
        }
      }
    }
  }

  /// Photographic film grain synthesis
  static void applyFilmGrain(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final intensity = (strength / 100.0) * 38.0;
    // Fast pseudo-random generator
    var rngSeed = 1337;
    int nextRng() {
      rngSeed = (rngSeed * 1664525 + 1013904223) & 0x7FFFFFFF;
      return (rngSeed >> 16) & 0xFF;
    }

    for (final pixel in image) {
      final noise = ((nextRng() - 128) / 128.0) * intensity;
      pixel.r = (pixel.r + noise).round().clamp(0, 255);
      pixel.g = (pixel.g + noise).round().clamp(0, 255);
      pixel.b = (pixel.b + noise).round().clamp(0, 255);
    }
  }

  /// Highlight bloom glow
  static void applyBloom(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final factor = (strength / 100.0) * 0.7;
    // Downscale to extract glow
    final glowDown = img.copyResize(
      image,
      width: math.max(32, image.width ~/ 4),
      height: math.max(32, image.height ~/ 4),
    );
    for (final p in glowDown) {
      final lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
      if (lum < 160) {
        p.r = 0;
        p.g = 0;
        p.b = 0;
      }
    }
    final glowUp = img.copyResize(
      glowDown,
      width: image.width,
      height: image.height,
    );

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final g = glowUp.getPixel(x, y);

        // Screen blend
        p.r = (p.r + g.r * factor).round().clamp(0, 255);
        p.g = (p.g + g.g * factor).round().clamp(0, 255);
        p.b = (p.b + g.b * factor).round().clamp(0, 255);
      }
    }
  }

  /// Chromatic aberration color fringing
  static void applyChromaticAberration(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final offset = math.max(1, ((strength / 100.0) * 12.0).round());
    final copy = img.Image.from(image);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final target = image.getPixel(x, y);

        // Sample red from left
        final rx = math.max(0, x - offset);
        final rPixel = copy.getPixel(rx, y);
        target.r = rPixel.r;

        // Sample blue from right
        final bx = math.min(image.width - 1, x + offset);
        final bPixel = copy.getPixel(bx, y);
        target.b = bPixel.b;
      }
    }
  }

  /// Vintage film tone and lifted blacks
  static void applyVintage(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final factor = strength / 100.0;
    for (final p in image) {
      // Lift blacks (fade)
      p.r = (p.r * (1.0 - factor * 0.15) + factor * 35).round().clamp(0, 255);
      p.g = (p.g * (1.0 - factor * 0.1) + factor * 25).round().clamp(0, 255);
      p.b = (p.b * (1.0 - factor * 0.25) + factor * 15).round().clamp(0, 255);
    }
  }

  /// Moody drama contrast
  static void applyDrama(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final factor = strength / 100.0;
    for (final p in image) {
      final lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
      final diff = lum - 128.0;
      final mult = (1.0 + factor * 0.75 * (diff / 128.0));
      p.r = (p.r * mult).round().clamp(0, 255);
      p.g = (p.g * mult).round().clamp(0, 255);
      p.b = (p.b * mult).round().clamp(0, 255);
    }
  }
}
