import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/mask_model.dart';

/// Engine responsible for calculating and rendering selective masks
/// (Brush, Linear Gradient, Radial Gradient) with tone adjustments and rubylith overlays.
class MaskEngine {
  /// Calculates normalized mask alpha [0.0 .. 1.0] for a coordinate (px, py) on an image of (w, h).
  static double calculateMaskAlpha(
    SelectiveMask mask,
    double px,
    double py,
    int width,
    int height,
  ) {
    if (!mask.isVisible) return 0.0;
    double rawAlpha = 0.0;
    final normX = px / width;
    final normY = py / height;
    final minDim = math.min(width, height).toDouble();

    switch (mask.type) {
      case MaskType.brush:
        if (mask.brushPoints.isEmpty) return 0.0;
        var minDist = double.infinity;
        var effectiveRadiusPx = 0.04 * minDim;
        var effectiveFeather = 0.5;

        for (int i = 0; i < mask.brushPoints.length; i++) {
          final pt = mask.brushPoints[i];
          final pX = pt.x * width;
          final pY = pt.y * height;
          final rPx = pt.radius * minDim;

          if (i > 0) {
            final prev = mask.brushPoints[i - 1];
            final segX = prev.x * width;
            final segY = prev.y * height;
            final dist = _distanceToSegment(px, py, segX, segY, pX, pY);
            if (dist < minDist) {
              minDist = dist;
              effectiveRadiusPx = rPx;
              effectiveFeather = pt.feather;
            }
          } else {
            final dx = px - pX;
            final dy = py - pY;
            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist < minDist) {
              minDist = dist;
              effectiveRadiusPx = rPx;
              effectiveFeather = pt.feather;
            }
          }
        }

        final featherDist = effectiveRadiusPx * effectiveFeather.clamp(0.01, 1.0);
        final innerRadius = effectiveRadiusPx - featherDist;

        if (minDist <= innerRadius) {
          rawAlpha = 1.0;
        } else if (minDist < effectiveRadiusPx) {
          rawAlpha = 1.0 - ((minDist - innerRadius) / featherDist).clamp(0.0, 1.0);
        } else {
          rawAlpha = 0.0;
        }
        break;

      case MaskType.linearGradient:
        final sx = mask.linearData.startX;
        final sy = mask.linearData.startY;
        final ex = mask.linearData.endX;
        final ey = mask.linearData.endY;

        final vx = ex - sx;
        final vy = ey - sy;
        final lenSq = vx * vx + vy * vy;
        if (lenSq < 1e-6) {
          rawAlpha = 0.0;
        } else {
          final t = ((normX - sx) * vx + (normY - sy) * vy) / lenSq;
          rawAlpha = t.clamp(0.0, 1.0);
        }
        break;

      case MaskType.radialGradient:
        final cx = mask.radialData.centerX;
        final cy = mask.radialData.centerY;
        final rx = mask.radialData.radiusX.clamp(0.01, 2.0);
        final ry = mask.radialData.radiusY.clamp(0.01, 2.0);
        final feather = mask.radialData.feather.clamp(0.01, 1.0);

        final dx = (normX - cx) / rx;
        final dy = (normY - cy) / ry;
        final dist = math.sqrt(dx * dx + dy * dy);

        final inner = 1.0 - feather;
        if (dist <= inner) {
          rawAlpha = 1.0;
        } else if (dist < 1.0) {
          rawAlpha = 1.0 - ((dist - inner) / feather).clamp(0.0, 1.0);
        } else {
          rawAlpha = 0.0;
        }
        break;
    }

    if (mask.inverted) {
      rawAlpha = 1.0 - rawAlpha;
    }

    return (rawAlpha * mask.opacity).clamp(0.0, 1.0);
  }

  static double _distanceToSegment(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final lenSq = dx * dx + dy * dy;
    if (lenSq < 1e-6) {
      final ddx = px - x1;
      final ddy = py - y1;
      return math.sqrt(ddx * ddx + ddy * ddy);
    }

    final t = (((px - x1) * dx + (py - y1) * dy) / lenSq).clamp(0.0, 1.0);
    final projX = x1 + t * dx;
    final projY = y1 + t * dy;
    final ddx = px - projX;
    final ddy = py - projY;
    return math.sqrt(ddx * ddx + ddy * ddy);
  }

  /// Applies all selective masks to [image] in-place.
  /// If [showOverlay] is true, renders the rubylith visual preview overlay.
  static void applyMasks(
    img.Image image,
    List<SelectiveMask> masks, {
    bool showOverlay = false,
  }) {
    if (masks.isEmpty) return;

    final w = image.width;
    final h = image.height;

    for (final mask in masks) {
      if (!mask.isVisible || mask.opacity <= 0.0) continue;
      final tone = mask.adjustments;
      final hasAdjustments = !tone.isIdentity;

      if (!hasAdjustments && !showOverlay) continue;

      final expFactor = math.pow(2.0, tone.exposure / 50.0).toDouble();
      final contrastFactor = 1.0 + (tone.contrast / 100.0) * 0.8;
      final satFactor = ((tone.saturation + 100.0) / 100.0).clamp(0.0, 3.0);
      final warmthOffset = (tone.warmth / 100.0) * 35.0;

      for (var y = 0; y < h; y++) {
        final py = y.toDouble();
        for (var x = 0; x < w; x++) {
          final px = x.toDouble();
          final alpha = calculateMaskAlpha(mask, px, py, w, h);
          if (alpha <= 1e-4) continue;

          final pixel = image.getPixel(x, y);
          final rOrig = pixel.r.toDouble();
          final gOrig = pixel.g.toDouble();
          final bOrig = pixel.b.toDouble();

          var r = rOrig;
          var g = gOrig;
          var b = bOrig;

          if (hasAdjustments) {
            // Exposure
            r *= expFactor;
            g *= expFactor;
            b *= expFactor;

            // Contrast
            r = (r - 128.0) * contrastFactor + 128.0;
            g = (g - 128.0) * contrastFactor + 128.0;
            b = (b - 128.0) * contrastFactor + 128.0;

            // Warmth
            r += warmthOffset;
            b -= warmthOffset;

            // Saturation
            final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
            r = lum + (r - lum) * satFactor;
            g = lum + (g - lum) * satFactor;
            b = lum + (b - lum) * satFactor;

            // Alpha blend back with original
            r = rOrig * (1.0 - alpha) + r * alpha;
            g = gOrig * (1.0 - alpha) + g * alpha;
            b = bOrig * (1.0 - alpha) + b * alpha;
          }

          if (showOverlay) {
            // Rubylith overlay: translucent scarlet red
            final overlayIntensity = alpha * 0.45;
            r = r * (1.0 - overlayIntensity) + 245.0 * overlayIntensity;
            g = g * (1.0 - overlayIntensity) + 35.0 * overlayIntensity;
            b = b * (1.0 - overlayIntensity) + 45.0 * overlayIntensity;
          }

          pixel.r = r.round().clamp(0, 255);
          pixel.g = g.round().clamp(0, 255);
          pixel.b = b.round().clamp(0, 255);
        }
      }
    }
  }
}
