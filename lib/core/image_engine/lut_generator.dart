import 'dart:typed_data';
import '../models/edit_state.dart';

class LutGenerator {
  /// Generates 256-element look-up tables for red, green, and blue channels
  /// combining exposure, brightness, contrast, highlights, shadows, whites, blacks,
  /// ambiance, warmth, tint, and curves.
  static ChannelLuts generate(TuneAdjustments tune, ToneCurves curves) {
    final rLut = Uint8List(256);
    final gLut = Uint8List(256);
    final bLut = Uint8List(256);

    // Fast-path: return identity LUT when no adjustments or curves are applied
    if (tune.isIdentity && curves.isIdentity) {
      for (var i = 0; i < 256; i++) {
        rLut[i] = i;
        gLut[i] = i;
        bLut[i] = i;
      }
      return ChannelLuts(rLut: rLut, gLut: gLut, bLut: bLut);
    }

    // 1. Exposure factor (EV scaling: 2^(exposure / 50))
    final exposureFactor = tune.exposure == 0.0
        ? 1.0
        : (tune.exposure > 0
              ? 1.0 + (tune.exposure / 100.0) * 1.5
              : 1.0 / (1.0 + (-tune.exposure / 100.0) * 1.5));

    // 2. Contrast factor
    // Standard contrast formulation: f = 259 * (contrast + 255) / (255 * (259 - contrast))
    final cVal = tune.contrast.clamp(-100.0, 100.0) * 1.5;
    final contrastFactor = (259.0 * (cVal + 255.0)) / (255.0 * (259.0 - cVal));

    // 3. Brightness shift
    final brightnessShift = tune.brightness.clamp(-100.0, 100.0) * 1.28;

    // 4. Warmth and tint shifts
    // Warmth: positive boosts red, drops blue; negative boosts blue, drops red
    final warmthShift = tune.warmth.clamp(-100.0, 100.0) * 0.45;
    // Tint: positive boosts magenta (R+B), drops G; negative boosts green
    final tintShift = tune.tint.clamp(-100.0, 100.0) * 0.45;

    // 5. Precompute spline curves for RGB, R, G, B channels
    final rgbCurve = _interpolateCurve(curves.rgb);
    final rCurve = _interpolateCurve(curves.red);
    final gCurve = _interpolateCurve(curves.green);
    final bCurve = _interpolateCurve(curves.blue);

    for (var i = 0; i < 256; i++) {
      // Base tone calculation starting from linear input
      double base = i.toDouble() * exposureFactor;

      // Whites & Blacks adjustments
      if (tune.whites != 0.0 && i > 180) {
        final weight = ((i - 180) / 75.0).clamp(0.0, 1.0);
        base += tune.whites * 0.5 * weight;
      }
      if (tune.blacks != 0.0 && i < 75) {
        final weight = ((75 - i) / 75.0).clamp(0.0, 1.0);
        base += tune.blacks * 0.5 * weight;
      }

      // Highlights adjustment (values > 100)
      if (tune.highlights != 0.0 && i > 100) {
        final weight = ((i - 100) / 155.0).clamp(0.0, 1.0);
        base += tune.highlights * 0.6 * weight;
      }

      // Shadows adjustment (values < 155)
      if (tune.shadows != 0.0 && i < 155) {
        final weight = ((155 - i) / 155.0).clamp(0.0, 1.0);
        base += tune.shadows * 0.6 * weight;
      }

      // Contrast and brightness
      base = contrastFactor * (base - 128.0) + 128.0 + brightnessShift;

      // Ambiance (boosts midtone detail and contrast subtly)
      if (tune.ambiance != 0.0) {
        final midWeight = 1.0 - ((i - 128.0).abs() / 128.0);
        base += tune.ambiance * 0.4 * midWeight;
      }

      // Apply master RGB curve
      final clampedBase = base.clamp(0.0, 255.0).round();
      final curvedBase = rgbCurve[clampedBase];

      // Channel-specific warmth & tint
      final rVal = (curvedBase + warmthShift + (tintShift * 0.6)).clamp(
        0.0,
        255.0,
      );
      final gVal = (curvedBase - (tintShift * 0.8)).clamp(0.0, 255.0);
      final bVal = (curvedBase - warmthShift + (tintShift * 0.6)).clamp(
        0.0,
        255.0,
      );

      // Apply individual channel curves
      rLut[i] = rCurve[rVal.round()];
      gLut[i] = gCurve[gVal.round()];
      bLut[i] = bCurve[bVal.round()];
    }

    return ChannelLuts(rLut: rLut, gLut: gLut, bLut: bLut);
  }

  /// Interpolates a list of CurvePoint into a 256-element uint8 LUT.
  /// If points represent an identity line (e.g. [(0,0), (1,1)]), it strictly
  /// produces the linear identity map without introducing unwanted S-curves.
  static Uint8List _interpolateCurve(List<CurvePoint> points) {
    final lut = Uint8List(256);
    if (points.isEmpty || _isIdentityCurve(points)) {
      for (var i = 0; i < 256; i++) {
        lut[i] = i;
      }
      return lut;
    }

    // Sort by x
    final sorted = List<CurvePoint>.from(points)
      ..sort((a, b) => a.x.compareTo(b.x));

    for (var i = 0; i < 256; i++) {
      final normX = i / 255.0;

      if (normX <= sorted.first.x) {
        lut[i] = (sorted.first.y * 255.0).clamp(0.0, 255.0).round();
      } else if (normX >= sorted.last.x) {
        lut[i] = (sorted.last.y * 255.0).clamp(0.0, 255.0).round();
      } else {
        // Find surrounding segment [p0, p1]
        var idx = 0;
        while (idx < sorted.length - 1 && sorted[idx + 1].x < normX) {
          idx++;
        }
        final p0 = sorted[idx];
        final p1 = sorted[idx + 1];
        final dx = p1.x - p0.x;
        final t = dx > 0 ? (normX - p0.x) / dx : 0.0;

        // Linear interpolation between consecutive points avoids artificial contrast boosts
        final interpolatedY = p0.y + (p1.y - p0.y) * t;
        lut[i] = (interpolatedY * 255.0).clamp(0.0, 255.0).round();
      }
    }
    return lut;
  }

  static bool _isIdentityCurve(List<CurvePoint> points) {
    if (points.length != 2) return false;
    return (points[0].x - 0.0).abs() < 1e-4 &&
        (points[0].y - 0.0).abs() < 1e-4 &&
        (points[1].x - 1.0).abs() < 1e-4 &&
        (points[1].y - 1.0).abs() < 1e-4;
  }
}

class ChannelLuts {
  final Uint8List rLut;
  final Uint8List gLut;
  final Uint8List bLut;

  const ChannelLuts({
    required this.rLut,
    required this.gLut,
    required this.bLut,
  });
}
