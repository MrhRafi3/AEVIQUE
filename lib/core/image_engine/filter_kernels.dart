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

  /// Vibrance boosts less-saturated colors more than already-saturated colors,
  /// preserving natural skin tones from over-saturation.
  static void applyVibrance(img.Image image, double vibrance) {
    if (vibrance == 0.0) return;

    final factor = vibrance / 100.0;
    for (final pixel in image) {
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;

      final maxVal = math.max(r, math.max(g, b));
      final minVal = math.min(r, math.min(g, b));
      final sat = maxVal == 0 ? 0.0 : (maxVal - minVal) / maxVal;

      // Higher weight for lower saturation
      final satWeight = (1.0 - sat).clamp(0.0, 1.0);
      final amt = factor * satWeight * 1.25;

      final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      pixel.r = (r + (r - lum) * amt).round().clamp(0, 255);
      pixel.g = (g + (g - lum) * amt).round().clamp(0, 255);
      pixel.b = (b + (b - lum) * amt).round().clamp(0, 255);
    }
  }

  /// Clarity enhances local contrast in the midtones with halo-prevention.
  static void applyClarity(img.Image image, double clarity) {
    if (clarity == 0.0) return;

    final factor = (clarity / 100.0) * 0.7;
    for (final pixel in image) {
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;

      // Midtone bell curve: peak at 128
      final midWeight = 1.0 - ((lum - 128.0).abs() / 128.0).clamp(0.0, 1.0);
      final delta = (lum - 128.0) * factor * midWeight;

      pixel.r = (r + delta).round().clamp(0, 255);
      pixel.g = (g + delta).round().clamp(0, 255);
      pixel.b = (b + delta).round().clamp(0, 255);
    }
  }

  /// Applies unsharp mask sharpening
  static void applySharpening(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final factor = (strength / 100.0) * 1.5;
    // Create copy for blurred reference
    final blurred = img.copyResize(
      image,
      width: math.max(16, image.width ~/ 2),
      height: math.max(16, image.height ~/ 2),
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

        final rx = math.max(0, x - offset);
        final rPixel = copy.getPixel(rx, y);
        target.r = rPixel.r;

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

  /// Soft diffusion mist glow
  static void applyGlow(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final factor = (strength / 100.0) * 0.65;
    final glowDown = img.copyResize(
      image,
      width: math.max(32, image.width ~/ 4),
      height: math.max(32, image.height ~/ 4),
    );
    final glowUp = img.copyResize(
      glowDown,
      width: image.width,
      height: image.height,
    );

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final g = glowUp.getPixel(x, y);

        p.r = (p.r + g.r * factor).round().clamp(0, 255);
        p.g = (p.g + g.g * factor).round().clamp(0, 255);
        p.b = (p.b + g.b * factor).round().clamp(0, 255);
      }
    }
  }

  /// Optical lens blur / bokeh simulation
  static void applyLensBlur(img.Image image, double strength) {
    if (strength <= 0.0) return;

    final radius = ((strength / 100.0) * 8.0).round().clamp(1, 12);
    final w = image.width;
    final h = image.height;

    // Fast 2D separable box blur
    final copy = img.Image.from(image);

    // Horizontal pass
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var rSum = 0;
        var gSum = 0;
        var bSum = 0;
        var count = 0;
        final xMin = math.max(0, x - radius);
        final xMax = math.min(w - 1, x + radius);
        for (var kx = xMin; kx <= xMax; kx++) {
          final p = copy.getPixel(kx, y);
          rSum += p.r.toInt();
          gSum += p.g.toInt();
          bSum += p.b.toInt();
          count++;
        }
        final target = image.getPixel(x, y);
        target.r = (rSum ~/ count).clamp(0, 255);
        target.g = (gSum ~/ count).clamp(0, 255);
        target.b = (bSum ~/ count).clamp(0, 255);
      }
    }

    // Vertical pass
    final hCopy = img.Image.from(image);
    for (var y = 0; y < h; y++) {
      final yMin = math.max(0, y - radius);
      final yMax = math.min(h - 1, y + radius);
      for (var x = 0; x < w; x++) {
        var rSum = 0;
        var gSum = 0;
        var bSum = 0;
        var count = 0;
        for (var ky = yMin; ky <= yMax; ky++) {
          final p = hCopy.getPixel(x, ky);
          rSum += p.r.toInt();
          gSum += p.g.toInt();
          bSum += p.b.toInt();
          count++;
        }
        final target = image.getPixel(x, y);
        target.r = (rSum ~/ count).clamp(0, 255);
        target.g = (gSum ~/ count).clamp(0, 255);
        target.b = (bSum ~/ count).clamp(0, 255);
      }
    }
  }

  /// 8-channel HSL color mixer
  static void applyHslMixer(img.Image image, HslAdjustments hsl) {
    if (hsl.isIdentity) return;

    final bands = [
      (hsl.red, 0.0, 35.0),
      (hsl.orange, 30.0, 28.0),
      (hsl.yellow, 60.0, 38.0),
      (hsl.green, 120.0, 48.0),
      (hsl.aqua, 180.0, 42.0),
      (hsl.blue, 240.0, 42.0),
      (hsl.purple, 280.0, 32.0),
      (hsl.magenta, 320.0, 32.0),
    ];

    double hueDiff(double h1, double h2) {
      final d = (h1 - h2).abs() % 360.0;
      return d > 180.0 ? 360.0 - d : d;
    }

    for (final pixel in image) {
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;

      final maxVal = math.max(r, math.max(g, b));
      final minVal = math.min(r, math.min(g, b));
      final delta = maxVal - minVal;

      var l = (maxVal + minVal) * 0.5;
      if (delta < 1e-4) continue; // Achromatic / neutral gray

      final s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal);

      double h;
      if ((maxVal - r).abs() < 1e-5) {
        h = ((g - b) / delta) % 6.0;
      } else if ((maxVal - g).abs() < 1e-5) {
        h = (b - r) / delta + 2.0;
      } else {
        h = (r - g) / delta + 4.0;
      }
      h = (h * 60.0) % 360.0;
      if (h < 0.0) h += 360.0;

      var totalWeight = 0.0;
      var dH = 0.0;
      var dS = 0.0;
      var dL = 0.0;

      for (final band in bands) {
        final adj = band.$1;
        final center = band.$2;
        final width = band.$3;
        final dist = hueDiff(h, center);
        if (dist < width) {
          final w = 0.5 * (1.0 + math.cos(math.pi * dist / width));
          totalWeight += w;
          dH += (adj.hue * 0.45) * w;
          dS += (adj.saturation / 100.0) * w;
          dL += (adj.luminance / 100.0 * 0.5) * w;
        }
      }

      if (totalWeight < 1e-4) continue;

      final norm = 1.0 / math.max(1.0, totalWeight);
      final finalH = ((h + dH * norm) % 360.0 + 360.0) % 360.0;
      final finalS = (s * (1.0 + dS * norm)).clamp(0.0, 1.0);
      final finalL = (l + dL * norm).clamp(0.0, 1.0);

      // Convert HSL back to RGB
      final c = (1.0 - (2.0 * finalL - 1.0).abs()) * finalS;
      final xVal = c * (1.0 - ((finalH / 60.0) % 2.0 - 1.0).abs());
      final m = finalL - c * 0.5;

      double rPrime, gPrime, bPrime;
      if (finalH < 60.0) {
        rPrime = c; gPrime = xVal; bPrime = 0.0;
      } else if (finalH < 120.0) {
        rPrime = xVal; gPrime = c; bPrime = 0.0;
      } else if (finalH < 180.0) {
        rPrime = 0.0; gPrime = c; bPrime = xVal;
      } else if (finalH < 240.0) {
        rPrime = 0.0; gPrime = xVal; bPrime = c;
      } else if (finalH < 300.0) {
        rPrime = xVal; gPrime = 0.0; bPrime = c;
      } else {
        rPrime = c; gPrime = 0.0; bPrime = xVal;
      }

      pixel.r = ((rPrime + m) * 255.0).round().clamp(0, 255);
      pixel.g = ((gPrime + m) * 255.0).round().clamp(0, 255);
      pixel.b = ((bPrime + m) * 255.0).round().clamp(0, 255);
    }
  }
}
