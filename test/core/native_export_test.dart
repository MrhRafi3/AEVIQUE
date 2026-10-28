import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/core/image_engine/image_pipeline.dart';
import 'package:lumaforge/core/models/edit_state.dart';
import 'package:lumaforge/core/native_engine/aevique_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const dylibPath = 'native/aevique_core/build/libaevique_core.dylib';
    if (File(dylibPath).existsSync()) {
      AeviqueNativeEngine.tryLoad(customLibraryPath: dylibPath);
    }
  });

  tearDown(() {
    AeviqueNativeEngine.engineMode = EngineMode.auto;
  });

  group('AEVIQUE Native Full-Resolution Export Engine', () {
    test('Parity: Native full-resolution export matches Dart reference within 1 LSB', () async {
      const w = 64;
      const h = 64;
      final testImage = img.Image(width: w, height: h);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          testImage.setPixelRgba(
            x,
            y,
            ((x / w) * 255).round(),
            ((y / h) * 255).round(),
            (((x + y) / (w + h)) * 255).round(),
            255,
          );
        }
      }
      final sourcePng = Uint8List.fromList(img.encodePng(testImage));

      final testState = EditState.identity().copyWith(
        tune: const TuneAdjustments(
          exposure: 15.0,
          contrast: 10.0,
          saturation: 20.0,
          warmth: 15.0,
          tint: -10.0,
          highlights: -20.0,
          shadows: 15.0,
        ),
      );

      // Force pure Dart export
      AeviqueNativeEngine.engineMode = EngineMode.dartOnly;
      final dartExportBytes = await ImagePipeline.processImage(
        sourcePng,
        testState,
        outputPng: true,
      );
      final dartImage = img.decodePng(dartExportBytes)!;

      // Force Native export
      AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;
      final nativeExportBytes = await ImagePipeline.processImage(
        sourcePng,
        testState,
        outputPng: true,
      );
      final nativeImage = img.decodePng(nativeExportBytes)!;

      expect(nativeImage.width, dartImage.width);
      expect(nativeImage.height, dartImage.height);

      int maxDiff = 0;
      int exactMatches = 0;
      final totalPixels = w * h;

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final dp = dartImage.getPixel(x, y);
          final np = nativeImage.getPixel(x, y);

          final dr = (dp.r.toInt() - np.r.toInt()).abs();
          final dg = (dp.g.toInt() - np.g.toInt()).abs();
          final db = (dp.b.toInt() - np.b.toInt()).abs();

          if (dr == 0 && dg == 0 && db == 0) {
            exactMatches++;
          }
          if (dr > maxDiff) maxDiff = dr;
          if (dg > maxDiff) maxDiff = dg;
          if (db > maxDiff) maxDiff = db;
        }
      }

      print('Export Numerical Parity: Exact: $exactMatches / $totalPixels, Max LSB diff: $maxDiff');
      expect(maxDiff, lessThanOrEqualTo(1));
    });

    test('Tone Curves export matches Dart reference within 1 LSB', () async {
      const w = 40;
      const h = 40;
      final testImage = img.Image(width: w, height: h);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          testImage.setPixelRgba(x, y, (x * 6).clamp(0, 255), (y * 6).clamp(0, 255), 128, 255);
        }
      }
      final sourcePng = Uint8List.fromList(img.encodePng(testImage));

      final curveState = EditState.identity().copyWith(
        curves: ToneCurves(
          rgb: [
            const CurvePoint(0.0, 0.0),
            const CurvePoint(0.25, 0.15),
            const CurvePoint(0.75, 0.85),
            const CurvePoint(1.0, 1.0),
          ],
        ),
      );

      // Dart reference
      AeviqueNativeEngine.engineMode = EngineMode.dartOnly;
      final dartBytes = await ImagePipeline.processImage(sourcePng, curveState, outputPng: true);
      final dartImg = img.decodePng(dartBytes)!;

      // Native export
      AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;
      final nativeBytes = await ImagePipeline.processImage(sourcePng, curveState, outputPng: true);
      final nativeImg = img.decodePng(nativeBytes)!;

      int maxDiff = 0;
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final dp = dartImg.getPixel(x, y);
          final np = nativeImg.getPixel(x, y);
          final diff = (dp.r.toInt() - np.r.toInt()).abs();
          if (diff > maxDiff) maxDiff = diff;
        }
      }

      expect(maxDiff, lessThanOrEqualTo(1));
    });

    test('PNG export strictly preserves alpha transparency', () async {
      const w = 32;
      const h = 32;
      final alphaImage = img.Image(width: w, height: h, numChannels: 4);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          // Half transparent, half opaque
          final a = (x < w ~/ 2) ? 100 : 255;
          alphaImage.setPixelRgba(x, y, 200, 150, 100, a);
        }
      }
      final sourcePng = Uint8List.fromList(img.encodePng(alphaImage));

      final state = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 20.0, contrast: 15.0),
      );

      AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;
      final exportBytes = await ImagePipeline.processImage(
        sourcePng,
        state,
        outputPng: true,
      );
      final decoded = img.decodePng(exportBytes)!;

      expect(decoded.width, w);
      expect(decoded.height, h);
      expect(decoded.getPixel(0, 0).a.toInt(), 100);
      expect(decoded.getPixel(w - 1, h - 1).a.toInt(), 255);
    });

    test('JPEG quality affects output compression size', () async {
      const w = 100;
      const h = 100;
      final testImage = img.Image(width: w, height: h);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          testImage.setPixelRgba(x, y, (x * 2) % 256, (y * 2) % 256, ((x + y) * 2) % 256, 255);
        }
      }
      final sourceJpg = Uint8List.fromList(img.encodeJpg(testImage, quality: 95));

      final state = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 10.0),
      );

      final highQualityBytes = await ImagePipeline.processImage(
        sourceJpg,
        state,
        jpegQuality: 95,
        outputPng: false,
      );
      final lowQualityBytes = await ImagePipeline.processImage(
        sourceJpg,
        state,
        jpegQuality: 40,
        outputPng: false,
      );

      expect(highQualityBytes.length, greaterThan(lowQualityBytes.length));
    });

    test('EngineMode.nativeOnly throws UnsupportedError on unsupported features', () async {
      final imgBytes = Uint8List.fromList(img.encodeJpg(img.Image(width: 10, height: 10)));
      final filterState = EditState.identity().copyWith(filterId: 'vivid_warm');

      AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;
      expect(
        () => ImagePipeline.processImage(imgBytes, filterState),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('EngineMode.nativeOnly throws StateError when native library is uninitialized', () async {
      final imgBytes = Uint8List.fromList(img.encodeJpg(img.Image(width: 10, height: 10)));
      final state = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 10.0),
      );

      AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;
      // Temporarily clear instance
      final origInstance = AeviqueNativeEngine.instance;
      AeviqueNativeEngine.setInstance(null);

      expect(
        () => ImagePipeline.processImage(imgBytes, state),
        throwsA(isA<StateError>()),
      );

      // Restore
      AeviqueNativeEngine.setInstance(origInstance);
    });

    test('EngineMode.auto falls back cleanly to Dart for unsupported adjustments', () async {
      final imgBytes = Uint8List.fromList(img.encodeJpg(img.Image(width: 20, height: 20)));
      final complexState = EditState.identity().copyWith(
        filterId: 'monochrome',
        effects: const EffectsAdjustments(grain: 20.0),
      );

      AeviqueNativeEngine.engineMode = EngineMode.auto;
      final result = await ImagePipeline.processImage(imgBytes, complexState);
      expect(result, isNotEmpty);
      final decoded = img.decodeJpg(result);
      expect(decoded, isNotNull);
      expect(decoded!.width, 20);
    });

    test('Invalid or corrupted image data throws clean Exception', () async {
      final corruptBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(
        () => ImagePipeline.processImage(corruptBytes, EditState.identity()),
        throwsA(isA<Exception>()),
      );
    });

    test('Optional downscaling downsamples image correctly during export', () async {
      final largeImage = img.Image(width: 200, height: 100);
      final sourceBytes = Uint8List.fromList(img.encodeJpg(largeImage));

      final state = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 15.0),
      );

      final exported = await ImagePipeline.processImage(
        sourceBytes,
        state,
        maxDimension: 80,
      );
      final decoded = img.decodeJpg(exported)!;

      expect(decoded.width, 80);
      expect(decoded.height, 40);
    });
  });
}
