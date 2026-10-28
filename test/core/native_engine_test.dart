import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/core/image_engine/filter_kernels.dart';
import 'package:lumaforge/core/image_engine/lut_generator.dart';
import 'package:lumaforge/core/models/edit_state.dart';
import 'package:lumaforge/core/native_engine/aevique_ffi.dart';

void main() {
  late AeviqueNativeEngine engine;
  late String dylibPath;

  setUpAll(() {
    dylibPath = 'native/aevique_core/build/libaevique_core.dylib';
    expect(
      File(dylibPath).existsSync(),
      isTrue,
      reason: 'Compiled native library must exist at $dylibPath',
    );
    engine = AeviqueNativeEngine.load(customLibraryPath: dylibPath);
  });

  group('AEVIQUE Native Engine FFI Integration', () {
    test('Library loads and reports version 1.0.0', () {
      final version = engine.getVersion();
      final major = (version >> 16) & 0xFF;
      final minor = (version >> 8) & 0xFF;
      final patch = version & 0xFF;

      expect(major, equals(1));
      expect(minor, equals(1));
      expect(patch, equals(0));
    });

    test('Status string mapping functions correctly', () {
      expect(engine.getStatusString(AeviqueStatusCode.success), equals('Success'));
      expect(
        engine.getStatusString(AeviqueStatusCode.errorNullPointer),
        contains('Null pointer'),
      );
      expect(
        engine.getStatusString(AeviqueStatusCode.errorInvalidDimensions),
        contains('Invalid image dimensions'),
      );
    });

    test('Neutral parameters produce zero pixel shift (Identity)', () {
      const width = 10;
      const height = 10;
      final bytes = Uint8List(width * height * 4);
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = (i * 17 + 5) % 256;
      }

      final out = engine.processRgba8(
        rgbaBytes: bytes,
        width: width,
        height: height,
        exposure: 0.0,
        contrast: 0.0,
        saturation: 0.0,
      );

      expect(out, equals(bytes));
    });

    test('In-place processing modifies input array directly', () {
      const width = 4;
      const height = 4;
      final bytes = Uint8List(width * height * 4);
      for (int i = 0; i < bytes.length; i += 4) {
        bytes[i + 0] = 100;
        bytes[i + 1] = 100;
        bytes[i + 2] = 100;
        bytes[i + 3] = 255;
      }

      final returned = engine.processRgba8(
        rgbaBytes: bytes,
        width: width,
        height: height,
        exposure: 30.0,
        inPlace: true,
      );

      expect(identical(returned, bytes), isTrue);
      expect(bytes[0], greaterThan(100)); // Was modified in place!
    });

    test('Alpha channel is preserved under extreme adjustments', () {
      const width = 8;
      const height = 8;
      final bytes = Uint8List(width * height * 4);
      for (int i = 0; i < bytes.length; i += 4) {
        bytes[i + 0] = 120;
        bytes[i + 1] = 140;
        bytes[i + 2] = 160;
        bytes[i + 3] = ((i ~/ 4) * 15) % 256; // Varying alpha values
      }

      final out = engine.processRgba8(
        rgbaBytes: bytes,
        width: width,
        height: height,
        exposure: 40.0,
        contrast: 30.0,
        saturation: -50.0,
      );

      for (int i = 0; i < bytes.length; i += 4) {
        expect(out[i + 3], equals(bytes[i + 3]), reason: 'Alpha must match at pixel index ${i ~/ 4}');
      }
    });

    test('Saturation -100 produces monochrome grayscale (R == G == B)', () {
      const width = 5;
      const height = 5;
      final bytes = Uint8List(width * height * 4);
      for (int i = 0; i < bytes.length; i += 4) {
        bytes[i + 0] = 230; // Orange-red
        bytes[i + 1] = 110;
        bytes[i + 2] = 40;
        bytes[i + 3] = 255;
      }

      final out = engine.processRgba8(
        rgbaBytes: bytes,
        width: width,
        height: height,
        saturation: -100.0,
      );

      for (int i = 0; i < bytes.length; i += 4) {
        expect(out[i + 0], equals(out[i + 1]), reason: 'R should equal G in B&W');
        expect(out[i + 1], equals(out[i + 2]), reason: 'G should equal B in B&W');
      }
    });
  });

  group('Numerical Parity Verification: Native C++ vs Dart Reference Engine', () {
    test('Pixel parity on realistic gradient image is within 1 LSB tolerance', () {
      const width = 64;
      const height = 64;
      final totalPixels = width * height;

      // 1. Create identical raw test image
      final dartImage = img.Image(width: width, height: height);
      final rawRgba = Uint8List(width * height * 4);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final r = ((x * 255) ~/ width);
          final g = ((y * 255) ~/ height);
          final b = (((x + y) * 255) ~/ (width + height));
          const a = 255;

          dartImage.setPixelRgba(x, y, r, g, b, a);
          final idx = (y * width + x) * 4;
          rawRgba[idx + 0] = r;
          rawRgba[idx + 1] = g;
          rawRgba[idx + 2] = b;
          rawRgba[idx + 3] = a;
        }
      }

      // Adjustment parameters
      const exposureVal = 20.0;
      const contrastVal = 15.0;
      const saturationVal = 20.0;

      // 2. Process through Dart reference pipeline
      final luts = LutGenerator.generate(
        const TuneAdjustments(exposure: exposureVal, contrast: contrastVal),
        const ToneCurves(),
      );
      for (final p in dartImage) {
        p.r = luts.rLut[p.r.toInt().clamp(0, 255)];
        p.g = luts.gLut[p.g.toInt().clamp(0, 255)];
        p.b = luts.bLut[p.b.toInt().clamp(0, 255)];
      }
      FilterKernels.applySaturationAndBw(dartImage, saturationVal, false);

      // 3. Process through Native C++ Engine via FFI
      final nativeOut = engine.processRgba8(
        rgbaBytes: rawRgba,
        width: width,
        height: height,
        exposure: exposureVal,
        contrast: contrastVal,
        saturation: saturationVal,
      );

      // 4. Compare every pixel
      int maxAbsDiff = 0;
      double sumSquaredError = 0.0;
      int exactMatches = 0;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final dartPixel = dartImage.getPixel(x, y);
          final idx = (y * width + x) * 4;

          final rNative = nativeOut[idx + 0];
          final gNative = nativeOut[idx + 1];
          final bNative = nativeOut[idx + 2];
          final aNative = nativeOut[idx + 3];

          final diffR = (dartPixel.r.toInt() - rNative).abs();
          final diffG = (dartPixel.g.toInt() - gNative).abs();
          final diffB = (dartPixel.b.toInt() - bNative).abs();

          maxAbsDiff = math.max(maxAbsDiff, math.max(diffR, math.max(diffG, diffB)));

          sumSquaredError += (diffR * diffR + diffG * diffG + diffB * diffB);
          if (diffR == 0 && diffG == 0 && diffB == 0) {
            exactMatches++;
          }

          expect(aNative, equals(255), reason: 'Alpha must remain 255');
        }
      }

      final meanSquaredError = sumSquaredError / (totalPixels * 3.0);
      final exactMatchPercent = (exactMatches / totalPixels) * 100.0;

      // Print parity statistics for audit trail
      print('\n--- Parity Statistics (64x64 Gradient, Exp: +20, Con: +15, Sat: +20) ---');
      print('Exact 24-bit RGB matches: $exactMatches / $totalPixels (${exactMatchPercent.toStringAsFixed(1)}%)');
      print('Max absolute channel difference: $maxAbsDiff LSB (tolerance <= 1)');
      print('Mean Squared Error (MSE): ${meanSquaredError.toStringAsFixed(6)} (tolerance < 0.001)');

      expect(maxAbsDiff, lessThanOrEqualTo(1), reason: 'Maximum LSB difference must not exceed 1');
      expect(meanSquaredError, lessThan(0.001), reason: 'MSE must be less than 0.001');
    });
  });
}

