import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/mask_model.dart';
import 'filter_kernels.dart';

/// Engine responsible for calculating and rendering selective masks
/// (Brush, Subject, Linear Gradient, Radial Gradient) with tone adjustments and rubylith overlays.
class MaskEngine {
  /// Paints a continuous line stroke from (x0, y0) to (x1, y1) into a grayscale alpha buffer.
  ///
  /// Supports:
  /// - [radius]: Brush stamp radius in buffer pixels
  /// - [hardness]: Hard edge [1.0] vs soft feather [0.0] with smooth Hermite falloff
  /// - [opacity]: Flow/opacity multiplier [0.0 .. 1.0]
  /// - [isErase]: If true, reduces alpha (subtractive); if false, increases alpha (additive)
  static void paintStrokeIntoBuffer({
    required Uint8List buffer,
    required int width,
    required int height,
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    required double radius,
    required double hardness,
    required double opacity,
    required bool isErase,
  }) {
    if (width <= 0 || height <= 0 || radius <= 0 || opacity <= 0) return;

    final rPx = radius;
    final minX = math.max(0, (math.min(x0, x1) - rPx - 1).floor());
    final maxX = math.min(width - 1, (math.max(x0, x1) + rPx + 1).ceil());
    final minY = math.max(0, (math.min(y0, y1) - rPx - 1).floor());
    final maxY = math.min(height - 1, (math.max(y0, y1) + rPx + 1).ceil());

    final clampedHardness = hardness.clamp(0.0, 1.0);
    final innerRadius = rPx * clampedHardness;
    final featherDist = rPx - innerRadius;
    final clampedOpacity = opacity.clamp(0.0, 1.0);

    for (var y = minY; y <= maxY; y++) {
      final py = y.toDouble();
      final rowOffset = y * width;
      for (var x = minX; x <= maxX; x++) {
        final px = x.toDouble();
        final dist = _distanceToSegment(px, py, x0, y0, x1, y1);
        if (dist > rPx) continue;

        double falloff;
        if (dist <= innerRadius || featherDist <= 1e-4) {
          falloff = 1.0;
        } else {
          final t = ((dist - innerRadius) / featherDist).clamp(0.0, 1.0);
          falloff = 1.0 - (t * t * (3.0 - 2.0 * t)); // Hermite smoothstep
        }

        final stampAlpha = (falloff * clampedOpacity).clamp(0.0, 1.0);
        final idx = rowOffset + x;
        final current = buffer[idx];

        if (isErase) {
          final reduced = (current * (1.0 - stampAlpha)).round().clamp(0, 255);
          buffer[idx] = reduced;
        } else {
          final currNorm = current / 255.0;
          final blended = currNorm + stampAlpha * (1.0 - currNorm);
          buffer[idx] = (blended * 255.0).round().clamp(0, 255);
        }
      }
    }
  }

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

    // Check if mask has a rasterized alpha buffer (e.g. Brush or Subject selection)
    final mw = mask.maskWidth;
    final mh = mask.maskHeight;
    if (mask.maskBytes != null &&
        mask.maskBytes!.isNotEmpty &&
        mw != null &&
        mh != null &&
        mw > 0 &&
        mh > 0 &&
        mask.maskBytes!.length >= mw * mh) {
      final u = (normX * (mw - 1)).clamp(0.0, (mw - 1).toDouble());
      final v = (normY * (mh - 1)).clamp(0.0, (mh - 1).toDouble());

      final x0 = u.floor();
      final y0 = v.floor();
      final x1 = math.min(x0 + 1, mw - 1);
      final y1 = math.min(y0 + 1, mh - 1);

      final fx = u - x0;
      final fy = v - y0;

      final b = mask.maskBytes!;
      final a00 = b[y0 * mw + x0];
      final a10 = b[y0 * mw + x1];
      final a01 = b[y1 * mw + x0];
      final a11 = b[y1 * mw + x1];

      final top = a00 * (1.0 - fx) + a10 * fx;
      final bot = a01 * (1.0 - fx) + a11 * fx;
      rawAlpha = (top * (1.0 - fy) + bot * fy) / 255.0;
    } else {
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

        case MaskType.subject:
          // If no maskBytes yet, subject has not been computed or is empty
          rawAlpha = 0.0;
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
    }

    if (mask.inverted) {
      rawAlpha = 1.0 - rawAlpha;
    }

    // Apply density scaling
    rawAlpha *= mask.density.clamp(0.0, 1.0);

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

      // Pre-compute scalar adjustment factors
      final expFactor = math.pow(2.0, tone.exposure / 50.0).toDouble();
      final brightnessOffset = (tone.brightness / 100.0) * 50.0;
      final contrastFactor = 1.0 + (tone.contrast / 100.0) * 0.8;
      final satFactor = ((tone.saturation + 100.0) / 100.0).clamp(0.0, 3.0);
      final warmthOffset = (tone.warmth / 100.0) * 35.0;
      final tintOffset = (tone.tint / 100.0) * 30.0;
      final clarityFactor = (tone.clarity / 100.0) * 0.7;
      final textureFactor = (tone.texture / 100.0) * 0.4;
      final dehazeFactor = (tone.dehaze / 100.0) * 0.3;
      final vibranceFactor = tone.vibrance / 100.0;
      final hasHsl = !tone.hsl.isIdentity;

      // HSL color mixer bands if HSL is active
      final hslBands = hasHsl
          ? [
              (tone.hsl.red, 0.0, 35.0),
              (tone.hsl.orange, 30.0, 28.0),
              (tone.hsl.yellow, 60.0, 38.0),
              (tone.hsl.green, 120.0, 48.0),
              (tone.hsl.aqua, 180.0, 42.0),
              (tone.hsl.blue, 240.0, 42.0),
              (tone.hsl.purple, 280.0, 32.0),
              (tone.hsl.magenta, 320.0, 32.0),
            ]
          : null;

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
            // 1. Exposure
            if (tone.exposure != 0.0) {
              r *= expFactor;
              g *= expFactor;
              b *= expFactor;
            }

            // 2. Brightness
            if (tone.brightness != 0.0) {
              r += brightnessOffset;
              g += brightnessOffset;
              b += brightnessOffset;
            }

            // 3. Contrast
            if (tone.contrast != 0.0) {
              r = (r - 128.0) * contrastFactor + 128.0;
              g = (g - 128.0) * contrastFactor + 128.0;
              b = (b - 128.0) * contrastFactor + 128.0;
            }

            // 4. Highlights, Shadows, Whites, Blacks
            final currentLum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
            if (tone.highlights != 0.0 && currentLum > 100.0) {
              final wH = ((currentLum - 100.0) / 155.0).clamp(0.0, 1.0);
              final offH = (tone.highlights / 100.0) * 40.0 * wH;
              r += offH; g += offH; b += offH;
            }
            if (tone.shadows != 0.0 && currentLum < 155.0) {
              final wS = ((155.0 - currentLum) / 155.0).clamp(0.0, 1.0);
              final offS = (tone.shadows / 100.0) * 40.0 * wS;
              r += offS; g += offS; b += offS;
            }
            if (tone.whites != 0.0 && currentLum > 180.0) {
              final wW = ((currentLum - 180.0) / 75.0).clamp(0.0, 1.0);
              final offW = (tone.whites / 100.0) * 35.0 * wW;
              r += offW; g += offW; b += offW;
            }
            if (tone.blacks != 0.0 && currentLum < 75.0) {
              final wB = ((75.0 - currentLum) / 75.0).clamp(0.0, 1.0);
              final offB = (tone.blacks / 100.0) * 35.0 * wB;
              r += offB; g += offB; b += offB;
            }

            // 5. Warmth & Tint
            if (tone.warmth != 0.0) {
              r += warmthOffset;
              b -= warmthOffset;
            }
            if (tone.tint != 0.0) {
              g -= tintOffset;
              r += tintOffset * 0.5;
              b += tintOffset * 0.5;
            }

            // 6. Saturation & Vibrance
            if (tone.saturation != 0.0 || tone.vibrance != 0.0) {
              final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
              if (tone.saturation != 0.0) {
                r = lum + (r - lum) * satFactor;
                g = lum + (g - lum) * satFactor;
                b = lum + (b - lum) * satFactor;
              }
              if (tone.vibrance != 0.0) {
                final maxC = math.max(r, math.max(g, b));
                final minC = math.min(r, math.min(g, b));
                final sat = maxC == 0 ? 0.0 : (maxC - minC) / maxC;
                final satWeight = (1.0 - sat).clamp(0.0, 1.0);
                final skinProb = FilterKernels.computeSkinProbability(
                  (r / 255.0).clamp(0.0, 1.0),
                  (g / 255.0).clamp(0.0, 1.0),
                  (b / 255.0).clamp(0.0, 1.0),
                );
                final skinProtection = vibranceFactor > 0.0 ? (1.0 - 0.65 * skinProb) : 1.0;
                final amt = vibranceFactor * satWeight * 1.25 * skinProtection;
                r += (r - lum) * amt;
                g += (g - lum) * amt;
                b += (b - lum) * amt;
              }
            }

            // 7. Clarity, Texture, Dehaze
            if (tone.clarity != 0.0) {
              final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
              final midWeight = 1.0 - ((lum - 128.0).abs() / 128.0).clamp(0.0, 1.0);
              final delta = (lum - 128.0) * clarityFactor * midWeight;
              r += delta; g += delta; b += delta;
            }
            if (tone.texture != 0.0) {
              final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
              final delta = (lum - 128.0) * textureFactor;
              r += delta; g += delta; b += delta;
            }
            if (tone.dehaze != 0.0) {
              r = (r - 128.0) * (1.0 + dehazeFactor) + 128.0 - (tone.dehaze / 100.0) * 10.0;
              g = (g - 128.0) * (1.0 + dehazeFactor) + 128.0 - (tone.dehaze / 100.0) * 10.0;
              b = (b - 128.0) * (1.0 + dehazeFactor) + 128.0 - (tone.dehaze / 100.0) * 10.0;
            }

            // 8. HSL Color Mixer
            if (hasHsl && hslBands != null) {
              final rN = (r / 255.0).clamp(0.0, 1.0);
              final gN = (g / 255.0).clamp(0.0, 1.0);
              final bN = (b / 255.0).clamp(0.0, 1.0);
              final maxVal = math.max(rN, math.max(gN, bN));
              final minVal = math.min(rN, math.min(gN, bN));
              final delta = maxVal - minVal;
              var l = (maxVal + minVal) * 0.5;

              if (delta >= 1e-4) {
                final s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal);
                double h;
                if ((maxVal - rN).abs() < 1e-5) {
                  h = ((gN - bN) / delta) % 6.0;
                } else if ((maxVal - gN).abs() < 1e-5) {
                  h = (bN - rN) / delta + 2.0;
                } else {
                  h = (rN - gN) / delta + 4.0;
                }
                h = (h * 60.0) % 360.0;
                if (h < 0.0) h += 360.0;

                var totalWeight = 0.0;
                var dH = 0.0;
                var dS = 0.0;
                var dL = 0.0;

                for (final band in hslBands) {
                  final adj = band.$1;
                  final center = band.$2;
                  final width = band.$3;
                  var dist = (h - center).abs() % 360.0;
                  if (dist > 180.0) dist = 360.0 - dist;
                  if (dist < width) {
                    final wB = 0.5 * (1.0 + math.cos(math.pi * dist / width));
                    totalWeight += wB;
                    dH += (adj.hue * 0.45) * wB;
                    dS += (adj.saturation / 100.0) * wB;
                    dL += (adj.luminance / 100.0 * 0.5) * wB;
                  }
                }

                if (totalWeight >= 1e-4) {
                  final norm = 1.0 / math.max(1.0, totalWeight);
                  final finalH = ((h + dH * norm) % 360.0 + 360.0) % 360.0;
                  final finalS = (s * (1.0 + dS * norm)).clamp(0.0, 1.0);
                  final finalL = (l + dL * norm).clamp(0.0, 1.0);

                  final c = (1.0 - (2.0 * finalL - 1.0).abs()) * finalS;
                  final xVal = c * (1.0 - ((finalH / 60.0) % 2.0 - 1.0).abs());
                  final m = finalL - c * 0.5;

                  double rP, gP, bP;
                  if (finalH < 60.0) {
                    rP = c; gP = xVal; bP = 0.0;
                  } else if (finalH < 120.0) {
                    rP = xVal; gP = c; bP = 0.0;
                  } else if (finalH < 180.0) {
                    rP = 0.0; gP = c; bP = xVal;
                  } else if (finalH < 240.0) {
                    rP = 0.0; gP = xVal; bP = c;
                  } else if (finalH < 300.0) {
                    rP = xVal; gP = 0.0; bP = c;
                  } else {
                    rP = c; gP = 0.0; bP = xVal;
                  }
                  r = (rP + m) * 255.0;
                  g = (gP + m) * 255.0;
                  b = (bP + m) * 255.0;
                }
              }
            }

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

