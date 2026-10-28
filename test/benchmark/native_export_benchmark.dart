import 'dart:io';
import 'dart:math' as math;
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

  double median(List<double> list) {
    final s = List<double>.from(list)..sort();
    return s[s.length ~/ 2];
  }

  double p95(List<double> list) {
    final s = List<double>.from(list)..sort();
    return s[(s.length * 0.95).floor().clamp(0, s.length - 1)];
  }

  test('Benchmark Full-Resolution Export: 1200x670 Photo (Dart vs Native C++)', () async {
    const w = 1200;
    const h = 670;
    const iterations = 15;
    const warmup = 3;

    print('\n================================================================');
    print('AEVIQUE FULL-RESOLUTION EXPORT BENCHMARK (1200x670 Photo)');
    print('================================================================');

    final testImage = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        testImage.setPixelRgba(x, y, (x * 255) ~/ w, (y * 255) ~/ h, ((x + y) * 255) ~/ (w + h), 255);
      }
    }
    final sourceJpg = Uint8List.fromList(img.encodeJpg(testImage, quality: 92));

    final exportState = EditState.identity().copyWith(
      tune: const TuneAdjustments(
        exposure: 20.0,
        contrast: 15.0,
        saturation: 20.0,
        warmth: 15.0,
        tint: -10.0,
        highlights: -25.0,
        shadows: 20.0,
      ),
      curves: ToneCurves(
        rgb: [
          const CurvePoint(0.0, 0.0),
          const CurvePoint(0.25, 0.20),
          const CurvePoint(0.75, 0.85),
          const CurvePoint(1.0, 1.0),
        ],
      ),
    );

    // Baseline Pure Dart Export
    AeviqueNativeEngine.engineMode = EngineMode.dartOnly;
    for (int i = 0; i < warmup; i++) {
      await ImagePipeline.processImage(sourceJpg, exportState, jpegQuality: 92);
    }
    final List<double> dartTimes = [];
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      await ImagePipeline.processImage(sourceJpg, exportState, jpegQuality: 92);
      sw.stop();
      dartTimes.add(sw.elapsedMicroseconds / 1000.0);
    }

    // Native C++ Export
    AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;
    for (int i = 0; i < warmup; i++) {
      await ImagePipeline.processImage(sourceJpg, exportState, jpegQuality: 92);
    }
    final List<double> nativeTimes = [];
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      await ImagePipeline.processImage(sourceJpg, exportState, jpegQuality: 92);
      sw.stop();
      nativeTimes.add(sw.elapsedMicroseconds / 1000.0);
    }

    final dMed = median(dartTimes);
    final dP95 = p95(dartTimes);
    final nMed = median(nativeTimes);
    final nP95 = p95(nativeTimes);

    print('Dart Export Pipeline:    ${dMed.toStringAsFixed(2)} ms (median) [p95: ${dP95.toStringAsFixed(2)} ms]');
    print('Native Export Pipeline:  ${nMed.toStringAsFixed(2)} ms (median) [p95: ${nP95.toStringAsFixed(2)} ms]');
    print('Export Speedup:          ${(dMed / nMed).toStringAsFixed(2)}x faster');
    print('Latency saved:           ${(dMed - nMed).toStringAsFixed(2)} ms');
    print('================================================================\n');

    expect(nMed, lessThan(dMed));
  });

  test('Benchmark Full-Resolution Export: 12-Megapixel (4000x3000 Photo)', () async {
    const w = 4000;
    const h = 3000;
    const totalPixels = w * h;
    const iterations = 5;

    print('\n================================================================');
    print('AEVIQUE 12-MEGAPIXEL FULL-RESOLUTION EXPORT (4000x3000 Photo)');
    print('================================================================');
    print('Raw uncompressed RGBA8 buffer: ${(totalPixels * 4 / (1024 * 1024)).toStringAsFixed(1)} MB');

    // Create a 12 MP test image
    final testImage = img.Image(width: w, height: h);
    testImage.clear(img.ColorRgba8(120, 140, 160, 255));
    final sourceJpg = Uint8List.fromList(img.encodeJpg(testImage, quality: 90));

    final exportState = EditState.identity().copyWith(
      tune: const TuneAdjustments(
        exposure: 20.0,
        contrast: 15.0,
        saturation: 20.0,
        warmth: 15.0,
        highlights: -30.0,
        shadows: 20.0,
      ),
      curves: ToneCurves(
        rgb: [
          const CurvePoint(0.0, 0.0),
          const CurvePoint(0.25, 0.20),
          const CurvePoint(0.75, 0.85),
          const CurvePoint(1.0, 1.0),
        ],
      ),
    );

    // 1. Measure pure processing kernel differences
    final rawRgba = testImage.convert(numChannels: 4).toUint8List();

    // Dart kernel
    final dartSw = Stopwatch()..start();
    ImagePipeline.processRawImage(testImage, exportState);
    dartSw.stop();
    final dartKernelMs = dartSw.elapsedMicroseconds / 1000.0;

    // Native C++ kernel
    final engine = AeviqueNativeEngine.instance!;
    final nativeSw = Stopwatch()..start();
    engine.processRgba8(
      rgbaBytes: rawRgba,
      width: w,
      height: h,
      exposure: 20.0,
      contrast: 15.0,
      saturation: 20.0,
      warmth: 15.0,
      highlights: -30.0,
      shadows: 20.0,
      curves: exportState.curves,
      inPlace: true,
    );
    nativeSw.stop();
    final nativeKernelMs = nativeSw.elapsedMicroseconds / 1000.0;

    print('\nPURE 12 MP PROCESSING KERNEL:');
    print('  - Pure Dart Tone LUT loop:  ${dartKernelMs.toStringAsFixed(2)} ms');
    print('  - Native C++ Tone 3-LUT:    ${nativeKernelMs.toStringAsFixed(2)} ms');
    print('  - Kernel Processing Speedup: ${(dartKernelMs / nativeKernelMs).toStringAsFixed(2)}x faster');
    print('  - Native Kernel Throughput:  ${((totalPixels / (nativeKernelMs / 1000.0)) / 1000000.0).toStringAsFixed(2)} MP/sec');

    // 2. Measure end-to-end export turnaround (Decode -> Process -> JPEG Encode)
    final List<double> dartEndToEnd = [];
    AeviqueNativeEngine.engineMode = EngineMode.dartOnly;
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      await ImagePipeline.processImage(sourceJpg, exportState, jpegQuality: 90);
      sw.stop();
      dartEndToEnd.add(sw.elapsedMicroseconds / 1000.0);
    }

    final List<double> nativeEndToEnd = [];
    AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      await ImagePipeline.processImage(sourceJpg, exportState, jpegQuality: 90);
      sw.stop();
      nativeEndToEnd.add(sw.elapsedMicroseconds / 1000.0);
    }

    final dTotal = median(dartEndToEnd);
    final nTotal = median(nativeEndToEnd);

    print('\nEND-TO-END 12 MP EXPORT (Decode + Process + JPEG Encode):');
    print('  - Pure Dart Export:   ${dTotal.toStringAsFixed(2)} ms');
    print('  - Native C++ Export:  ${nTotal.toStringAsFixed(2)} ms');
    print('  - Overall Time Saved: ${(dTotal - nTotal).toStringAsFixed(2)} ms per export');
    print('================================================================\n');

    expect(nTotal, lessThan(dTotal));
    expect(nativeKernelMs, lessThan(dartKernelMs));
  });
}
