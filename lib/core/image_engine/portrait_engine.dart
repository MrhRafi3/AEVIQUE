import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/edit_state.dart';

class PortraitEngine {
  /// Applies portrait retouching (blemish removal, edge-preserving skin smoothing,
  /// and radiant skin tone brightening) to [image].
  static void applyPortrait(img.Image image, PortraitAdjustments portrait) {
    if (portrait.isIdentity) return;

    // 1. Local Blemish Removal (Tap-to-heal inpainting)
    if (portrait.blemishes.isNotEmpty) {
      for (final spot in portrait.blemishes) {
        healBlemish(image, spot);
      }
    }

    // 2. Edge-Preserving Skin Smoothing
    if (portrait.skinSmooth > 0.0) {
      applySkinSmooth(image, portrait.skinSmooth);
    }

    // 3. Radiant Skin Tone Brightening
    if (portrait.skinBrighten.abs() > 0.001) {
      applySkinBrighten(image, portrait.skinBrighten);
    }
  }

  /// Removes a localized blemish/pimple by inpainting surrounding skin texture and color gradients.
  static void healBlemish(img.Image image, BlemishSpot spot) {
    final cx = (spot.x * image.width).round().clamp(0, image.width - 1);
    final cy = (spot.y * image.height).round().clamp(0, image.height - 1);
    final radius = (spot.radius * image.width).round().clamp(4, 50);
    final radiusSq = radius * radius;
    final outerRadius = (radius * 1.45).round();
    final outerRadiusSq = outerRadius * outerRadius;

    // First pass: accumulate mean color and luminance of surrounding healthy skin ring
    double sumR = 0, sumG = 0, sumB = 0;
    int ringCount = 0;

    final minX = math.max(0, cx - outerRadius);
    final maxX = math.min(image.width - 1, cx + outerRadius);
    final minY = math.max(0, cy - outerRadius);
    final maxY = math.min(image.height - 1, cy + outerRadius);

    for (int y = minY; y <= maxY; y++) {
      final dy = y - cy;
      final dySq = dy * dy;
      for (int x = minX; x <= maxX; x++) {
        final dx = x - cx;
        final dSq = dx * dx + dySq;
        if (dSq > radiusSq && dSq <= outerRadiusSq) {
          final p = image.getPixel(x, y);
          sumR += p.r;
          sumG += p.g;
          sumB += p.b;
          ringCount++;
        }
      }
    }

    if (ringCount == 0) return;

    final avgR = sumR / ringCount;
    final avgG = sumG / ringCount;
    final avgB = sumB / ringCount;

    // Second pass: heal the blemish by smoothly blending inward from boundary rays and ring mean
    for (int y = minY; y <= maxY; y++) {
      final dy = y - cy;
      final dySq = dy * dy;
      for (int x = minX; x <= maxX; x++) {
        final dx = x - cx;
        final dSq = dx * dx + dySq;
        if (dSq <= radiusSq) {
          final dist = math.sqrt(dSq);
          final t = (dist / radius).clamp(0.0, 1.0);

          // Sample directional boundary pixel along this ray
          final angle = math.atan2(dy.toDouble(), dx.toDouble());
          final bx = (cx + math.cos(angle) * (radius + 2)).round().clamp(
            0,
            image.width - 1,
          );
          final by = (cy + math.sin(angle) * (radius + 2)).round().clamp(
            0,
            image.height - 1,
          );
          final bPix = image.getPixel(bx, by);

          // Interpolate ray boundary color with overall ring average
          final healedR = bPix.r * 0.45 + avgR * 0.55;
          final healedG = bPix.g * 0.45 + avgG * 0.55;
          final healedB = bPix.b * 0.45 + avgB * 0.55;

          // Smooth hermite falloff towards center
          // At center (dist=0), blend weight is 1.0; at perimeter (dist=radius), weight is 0.0
          final w = math.cos(t * math.pi * 0.5);
          final blendWeight = (w * w).clamp(0.0, 1.0);

          final p = image.getPixel(x, y);
          p.r = (p.r * (1.0 - blendWeight) + healedR * blendWeight).clamp(
            0,
            255,
          );
          p.g = (p.g * (1.0 - blendWeight) + healedG * blendWeight).clamp(
            0,
            255,
          );
          p.b = (p.b * (1.0 - blendWeight) + healedB * blendWeight).clamp(
            0,
            255,
          );
        }
      }
    }
  }

  /// Edge-preserving bilateral skin smoothing.
  /// Detects human skin tones using YCbCr color modeling and preserves sharp facial edges
  /// (eyes, eyelashes, eyebrows, lips, hair) through gradient exclusion and range-weighted bilateral filtering.
  static void applySkinSmooth(img.Image image, double smoothAmount) {
    if (smoothAmount <= 0.0) return;

    final width = image.width;
    final height = image.height;
    final strength = (smoothAmount / 100.0).clamp(0.0, 1.0);

    // Make an unmodified copy to sample original unblurred pixels
    final source = img.Image.from(image);

    // Compute luminance map to detect edges quickly
    final lumaMap = List<int>.filled(width * height, 0);
    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final p = source.getPixel(x, y);
        lumaMap[rowOffset + x] = (0.2989 * p.r + 0.5870 * p.g + 0.1140 * p.b)
            .round();
      }
    }

    const radius = 2; // 5x5 window for fast interactive performance
    const double sigmaRange = 28.0;
    const double twoSigmaRangeSq = 2.0 * sigmaRange * sigmaRange;

    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final p = source.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();

        // 1. Human skin classification in YCbCr space
        final yVal = lumaMap[rowOffset + x];
        final cb = (-0.1687 * r - 0.3313 * g + 0.5000 * b + 128.0).round();
        final cr = (0.5000 * r - 0.4187 * g - 0.0813 * b + 128.0).round();

        // Skin confidence factor S in [0.0, 1.0]
        double skinFactor = 0.0;
        if (cb >= 75 && cb <= 138 && cr >= 130 && cr <= 180 && r > (g - 8)) {
          // Soft radial falloff from typical skin center (Cb=108, Cr=154)
          final dCb = (cb - 108.0) / 32.0;
          final dCr = (cr - 154.0) / 26.0;
          final dNorm = dCb * dCb + dCr * dCr;
          if (dNorm < 1.0) {
            skinFactor = 1.0 - dNorm;
          }
        }

        if (skinFactor <= 0.02) continue; // Skip non-skin pixels entirely

        // 2. Facial Edge Exclusion (eyes, lips, brows, nostrils, hair)
        // Check horizontal and vertical gradients
        final lumaLeft = x > 0 ? lumaMap[rowOffset + x - 1] : yVal;
        final lumaRight = x < width - 1 ? lumaMap[rowOffset + x + 1] : yVal;
        final lumaUp = y > 0 ? lumaMap[(y - 1) * width + x] : yVal;
        final lumaDown = y < height - 1 ? lumaMap[(y + 1) * width + x] : yVal;

        final gradX = (lumaRight - lumaLeft).abs();
        final gradY = (lumaDown - lumaUp).abs();
        final gradMag = gradX + gradY;

        // If gradient is strong (eye/eyebrow/lip boundary), reduce smoothing to preserve detail
        final edgeSuppression = (1.0 - (gradMag / 48.0)).clamp(0.0, 1.0);
        final effectiveBlend = skinFactor * edgeSuppression * strength;

        if (effectiveBlend <= 0.01) continue;

        // 3. Bilateral spatial smoothing over 5x5 window
        double weightSum = 0.0;
        double rSum = 0.0, gSum = 0.0, bSum = 0.0;

        for (int dy = -radius; dy <= radius; dy++) {
          final ny = (y + dy).clamp(0, height - 1);
          final nRow = ny * width;
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = (x + dx).clamp(0, width - 1);
            final np = source.getPixel(nx, ny);
            final nLuma = lumaMap[nRow + nx];

            final lumaDiff = (yVal - nLuma).toDouble();
            final rangeWeight = math.exp(
              -(lumaDiff * lumaDiff) / twoSigmaRangeSq,
            );

            rSum += np.r * rangeWeight;
            gSum += np.g * rangeWeight;
            bSum += np.b * rangeWeight;
            weightSum += rangeWeight;
          }
        }

        if (weightSum > 0.0) {
          final targetPixel = image.getPixel(x, y);
          final smoothR = rSum / weightSum;
          final smoothG = gSum / weightSum;
          final smoothB = bSum / weightSum;

          targetPixel.r =
              (r * (1.0 - effectiveBlend) + smoothR * effectiveBlend)
                  .round()
                  .clamp(0, 255);
          targetPixel.g =
              (g * (1.0 - effectiveBlend) + smoothG * effectiveBlend)
                  .round()
                  .clamp(0, 255);
          targetPixel.b =
              (b * (1.0 - effectiveBlend) + smoothB * effectiveBlend)
                  .round()
                  .clamp(0, 255);
        }
      }
    }
  }

  /// Radiant skin tone brightening targeting facial midtones without blowing out highlights.
  static void applySkinBrighten(img.Image image, double brightenAmount) {
    if (brightenAmount.abs() <= 0.001) return;

    // Amount scaled: -50.0..+50.0 maps to -25.0..+25.0 luminance delta
    final boost = (brightenAmount / 50.0) * 25.0;

    for (final pixel in image) {
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // Convert to YCbCr
      final y = 0.2989 * r + 0.5870 * g + 0.1140 * b;
      final cb = -0.1687 * r - 0.3313 * g + 0.5000 * b + 128.0;
      final cr = 0.5000 * r - 0.4187 * g - 0.0813 * b + 128.0;

      // Soft skin mask
      if (cb >= 75 && cb <= 140 && cr >= 130 && cr <= 180 && r > (g - 8)) {
        final dCb = (cb - 108.0) / 32.0;
        final dCr = (cr - 154.0) / 26.0;
        final dNorm = dCb * dCb + dCr * dCr;
        if (dNorm < 1.0) {
          final skinWeight = 1.0 - dNorm;
          // Midtone bell curve: sin(pi * y / 255.0) peaks at 128, 0 at 0 and 255
          final midtoneFactor = math.sin((y / 255.0).clamp(0.0, 1.0) * math.pi);
          final deltaY = boost * midtoneFactor * skinWeight;

          pixel.r = (r + deltaY).round().clamp(0, 255);
          pixel.g = (g + deltaY).round().clamp(0, 255);
          pixel.b = (b + deltaY).round().clamp(0, 255);
        }
      }
    }
  }
}
