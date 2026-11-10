import 'package:flutter_test/flutter_test.dart';
import 'package:lumafix/core/models/edit_state.dart';
import 'package:lumafix/core/image_engine/lut_generator.dart';

void main() {
  group('ToneCurves Fritsch-Carlson Monotone Cubic Spline', () {
    test('Identity 2-point curve generates strict linear identity LUT', () {
      final luts = LutGenerator.generate(
        const TuneAdjustments(),
        const ToneCurves(),
      );

      for (var i = 0; i < 256; i++) {
        expect(luts.rLut[i], i);
        expect(luts.gLut[i], i);
        expect(luts.bLut[i], i);
      }
    });

    test('S-Curve is strictly monotonic with smooth midtone contrast', () {
      final sCurve = ToneCurves(
        rgb: [
          const CurvePoint(0.0, 0.0),
          const CurvePoint(0.25, 0.15),
          const CurvePoint(0.5, 0.5),
          const CurvePoint(0.75, 0.85),
          const CurvePoint(1.0, 1.0),
        ],
      );

      final luts = LutGenerator.generate(const TuneAdjustments(), sCurve);

      // Verify strict monotonicity (no non-monotonic wiggles)
      for (var i = 1; i < 256; i++) {
        expect(luts.rLut[i], greaterThanOrEqualTo(luts.rLut[i - 1]));
      }

      // Check shadow compression and highlight boost
      final shadowVal = luts.rLut[64]; // around 0.25
      expect(shadowVal, lessThan(64));

      final highlightVal = luts.rLut[192]; // around 0.75
      expect(highlightVal, greaterThan(192));
    });

    test('Inverted curve (negative photo) is strictly monotonic decreasing', () {
      final invertCurve = ToneCurves(
        rgb: [
          const CurvePoint(0.0, 1.0),
          const CurvePoint(1.0, 0.0),
        ],
      );

      final luts = LutGenerator.generate(const TuneAdjustments(), invertCurve);

      expect(luts.rLut[0], 255);
      expect(luts.rLut[255], 0);

      for (var i = 1; i < 256; i++) {
        expect(luts.rLut[i], lessThanOrEqualTo(luts.rLut[i - 1]));
      }
    });

    test('Individual color channels (Red, Green, Blue) are independent', () {
      final customCurves = ToneCurves(
        red: [
          const CurvePoint(0.0, 0.0),
          const CurvePoint(0.5, 0.8), // Boost mid red
          const CurvePoint(1.0, 1.0),
        ],
        green: [
          const CurvePoint(0.0, 0.0),
          const CurvePoint(0.5, 0.2), // Cut mid green
          const CurvePoint(1.0, 1.0),
        ],
      );

      final luts = LutGenerator.generate(const TuneAdjustments(), customCurves);

      final midR = luts.rLut[128];
      final midG = luts.gLut[128];
      final midB = luts.bLut[128];

      expect(midR, greaterThan(128));
      expect(midG, lessThan(128));
      expect(midB, equals(128)); // Blue is untouched identity
    });

    test('Extreme points close in X do not cause NaN or wild overflow', () {
      final extreme = ToneCurves(
        rgb: [
          const CurvePoint(0.0, 0.0),
          const CurvePoint(0.499, 0.1),
          const CurvePoint(0.501, 0.9),
          const CurvePoint(1.0, 1.0),
        ],
      );

      final luts = LutGenerator.generate(const TuneAdjustments(), extreme);

      for (var i = 0; i < 256; i++) {
        expect(luts.rLut[i], inInclusiveRange(0, 255));
      }
    });
  });
}
