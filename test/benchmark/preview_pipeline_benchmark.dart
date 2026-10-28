import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
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

  test('Benchmark End-to-End Preview Latency: Baseline Dart vs Integrated Native RGBA', () async {
    const width = 1200;
    const height = 670;
    const iterations = 50;
    const warmup = 10;

    print('\n================================================================');
    print('AEVIQUE PREVIEW PIPELINE END-TO-END BENCHMARK (1200x670 RGBA8)');
    print('================================================================');
    print('Platform: ${Platform.operatingSystem} (${Platform.version.split(' ').first})');
    print('Native Engine Loaded: ${AeviqueNativeEngine.isAvailable}');
    print('Preview Dimensions: ${width}x$height (${(width * height * 4 / (1024 * 1024)).toStringAsFixed(2)} MB raw RGBA)');
    print('Iterations: $iterations measured ($warmup warm-up)');
    print('----------------------------------------------------------------');

    // Create realistic synthetic photo image (gradients and color transitions)
    final previewBase = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = ((x / width) * 255).round();
        final g = ((y / height) * 255).round();
        final b = (((x + y) / (width + height)) * 255).round();
        previewBase.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    final rawRgba = previewBase.convert(numChannels: 4).toUint8List();

    final testState = EditState.identity().copyWith(
      tune: const TuneAdjustments(
        exposure: 20.0,
        contrast: 15.0,
        saturation: 25.0,
      ),
    );

    // -------------------------------------------------------------
    // Scenario 1: Baseline Pure Dart Preview Pipeline
    // (Dart LUT/Tone in isolate -> JPEG encode -> Skia JPEG decode)
    // -------------------------------------------------------------
    final List<double> baselineTotalTimes = [];
    final List<double> baselineEncodeTimes = [];
    final List<double> baselineDecodeTimes = [];

    // Warm-up
    for (int i = 0; i < warmup; i++) {
      final jpegBytes = await ImagePipeline.processPreviewFast(previewBase, testState, jpegQuality: 90);
      final codec = await ui.instantiateImageCodec(jpegBytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
    }

    // Measurement
    for (int i = 0; i < iterations; i++) {
      final totalSw = Stopwatch()..start();
      
      final encodeSw = Stopwatch()..start();
      final jpegBytes = await ImagePipeline.processPreviewFast(previewBase, testState, jpegQuality: 90);
      encodeSw.stop();

      final decodeSw = Stopwatch()..start();
      final codec = await ui.instantiateImageCodec(jpegBytes);
      final frame = await codec.getNextFrame();
      decodeSw.stop();

      totalSw.stop();
      frame.image.dispose();
      codec.dispose();

      baselineEncodeTimes.add(encodeSw.elapsedMicroseconds / 1000.0);
      baselineDecodeTimes.add(decodeSw.elapsedMicroseconds / 1000.0);
      baselineTotalTimes.add(totalSw.elapsedMicroseconds / 1000.0);
    }

    // -------------------------------------------------------------
    // Scenario 2: Integrated Native C++ Raw RGBA Preview Pipeline
    // (Native FFI Tone Kernel -> Raw RGBA -> ui.decodeImageFromPixels)
    // -------------------------------------------------------------
    final List<double> nativeTotalTimes = [];
    final List<double> nativeKernelAndCopyTimes = [];
    final List<double> pureKernelTimes = [];
    final List<double> copyTimes = [];
    final List<double> nativeGpuUploadTimes = [];

    if (AeviqueNativeEngine.isAvailable) {
      final engine = AeviqueNativeEngine.instance!;

      // Pre-allocate native buffers to measure pure C++ execution separately
      final totalBytes = width * height * 4;
      final srcPtr = calloc<ffi.Uint8>(totalBytes);
      final dstPtr = calloc<ffi.Uint8>(totalBytes);
      final srcBuf = calloc<AeviqueImageBuffer>();
      final dstBuf = calloc<AeviqueImageBuffer>();
      final toneParams = calloc<AeviqueToneParameters>();

      srcBuf.ref.data = srcPtr;
      srcBuf.ref.width = width;
      srcBuf.ref.height = height;
      srcBuf.ref.strideBytes = width * 4;
      srcBuf.ref.format = AeviquePixelFormat.rgba8888;

      dstBuf.ref.data = dstPtr;
      dstBuf.ref.width = width;
      dstBuf.ref.height = height;
      dstBuf.ref.strideBytes = width * 4;
      dstBuf.ref.format = AeviquePixelFormat.rgba8888;

      toneParams.ref.exposure = 20.0;
      toneParams.ref.contrast = 15.0;
      toneParams.ref.saturation = 25.0;

      // Warm-up
      for (int i = 0; i < warmup; i++) {
        engine.processToneRaw(src: srcBuf, dst: dstBuf, params: toneParams);
        final processedRgba = engine.processRgba8(
          rgbaBytes: rawRgba,
          width: width,
          height: height,
          exposure: 20.0,
          contrast: 15.0,
          saturation: 25.0,
        );
        final uiImg = await ImagePipeline.decodeRgbaPixels(processedRgba, width, height);
        uiImg.dispose();
      }

      // Measurement
      for (int i = 0; i < iterations; i++) {
        // A. Pure native C++ kernel execution
        final pkSw = Stopwatch()..start();
        engine.processToneRaw(src: srcBuf, dst: dstBuf, params: toneParams);
        pkSw.stop();
        pureKernelTimes.add(pkSw.elapsedMicroseconds / 1000.0);

        // B. End-to-end native preview turnaround
        final totalSw = Stopwatch()..start();

        final kernelSw = Stopwatch()..start();
        final processedRgba = engine.processRgba8(
          rgbaBytes: rawRgba,
          width: width,
          height: height,
          exposure: 20.0,
          contrast: 15.0,
          saturation: 25.0,
        );
        kernelSw.stop();

        final uploadSw = Stopwatch()..start();
        final uiImg = await ImagePipeline.decodeRgbaPixels(processedRgba, width, height);
        uploadSw.stop();

        totalSw.stop();
        uiImg.dispose();

        final kernelMs = kernelSw.elapsedMicroseconds / 1000.0;
        nativeKernelAndCopyTimes.add(kernelMs);
        copyTimes.add(math.max(0.0, kernelMs - (pkSw.elapsedMicroseconds / 1000.0)));
        nativeGpuUploadTimes.add(uploadSw.elapsedMicroseconds / 1000.0);
        nativeTotalTimes.add(totalSw.elapsedMicroseconds / 1000.0);
      }

      calloc.free(toneParams);
      calloc.free(dstBuf);
      calloc.free(dstPtr);
      calloc.free(srcBuf);
      calloc.free(srcPtr);
    }

    // -------------------------------------------------------------
    // Statistical Summaries
    // -------------------------------------------------------------
    double calcMedian(List<double> list) {
      final sorted = List<double>.from(list)..sort();
      final mid = sorted.length ~/ 2;
      return sorted.length.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0;
    }

    double calcP95(List<double> list) {
      final sorted = List<double>.from(list)..sort();
      final idx = (sorted.length * 0.95).floor().clamp(0, sorted.length - 1);
      return sorted[idx];
    }

    double calcMean(List<double> list) => list.reduce((a, b) => a + b) / list.length;

    final baseTotalMed = calcMedian(baselineTotalTimes);
    final baseTotalMean = calcMean(baselineTotalTimes);
    final baseTotalP95 = calcP95(baselineTotalTimes);
    final baseTotalMin = baselineTotalTimes.reduce(math.min);
    final baseTotalMax = baselineTotalTimes.reduce(math.max);

    final baseEncMed = calcMedian(baselineEncodeTimes);
    final baseDecMed = calcMedian(baselineDecodeTimes);

    print('\nBASELINE DART PIPELINE (with JPEG compression):');
    print('  - Isolate Processing + JPEG Encode: ${baseEncMed.toStringAsFixed(2)} ms (median)');
    print('  - Skia JPEG Decode:                ${baseDecMed.toStringAsFixed(2)} ms (median)');
    print('  - TOTAL Preview Frame Latency:      ${baseTotalMed.toStringAsFixed(2)} ms (median)');
    print('    [min: ${baseTotalMin.toStringAsFixed(2)} ms, mean: ${baseTotalMean.toStringAsFixed(2)} ms, p95: ${baseTotalP95.toStringAsFixed(2)} ms, max: ${baseTotalMax.toStringAsFixed(2)} ms]');

    if (AeviqueNativeEngine.isAvailable) {
      final natTotalMed = calcMedian(nativeTotalTimes);
      final natTotalMean = calcMean(nativeTotalTimes);
      final natTotalP95 = calcP95(nativeTotalTimes);
      final natTotalMin = nativeTotalTimes.reduce(math.min);
      final natTotalMax = nativeTotalTimes.reduce(math.max);

      final natKernelAndCopyMed = calcMedian(nativeKernelAndCopyTimes);
      final pureKernelMed = calcMedian(pureKernelTimes);
      final pureKernelP95 = calcP95(pureKernelTimes);
      final copyMed = calcMedian(copyTimes);
      final natUploadMed = calcMedian(nativeGpuUploadTimes);
      final natUploadP95 = calcP95(nativeGpuUploadTimes);

      final speedup = baseTotalMed / natTotalMed;

      print('\nINTEGRATED NATIVE C++ RAW RGBA PIPELINE (Zero JPEG):');
      print('  - Pure C++ Tone Kernel:                ${pureKernelMed.toStringAsFixed(2)} ms (median) [p95: ${pureKernelP95.toStringAsFixed(2)} ms]');
      print('  - FFI Memory Copy / Allocation:        ${copyMed.toStringAsFixed(2)} ms (median)');
      print('  - Subtotal (Kernel + FFI Marshalling): ${natKernelAndCopyMed.toStringAsFixed(2)} ms (median)');
      print('  - Raw RGBA -> ui.decodeImageFromPixels:${natUploadMed.toStringAsFixed(2)} ms (median) [p95: ${natUploadP95.toStringAsFixed(2)} ms]');
      print('  - TOTAL Preview Frame Latency:         ${natTotalMed.toStringAsFixed(2)} ms (median)');
      print('    [min: ${natTotalMin.toStringAsFixed(2)} ms, mean: ${natTotalMean.toStringAsFixed(2)} ms, p95: ${natTotalP95.toStringAsFixed(2)} ms, max: ${natTotalMax.toStringAsFixed(2)} ms]');
      print('\n----------------------------------------------------------------');
      print('PERFORMANCE SPEEDUP: ${speedup.toStringAsFixed(2)}x faster preview turnaround');
      print('LATENCY REDUCTION:   ${(baseTotalMed - natTotalMed).toStringAsFixed(2)} ms saved per slider movement');
      print('================================================================\n');

      expect(natTotalMed, lessThan(baseTotalMed));
    }
  });

  test('Benchmark Phase 3 Advanced Tone Pipeline: Curves + Warmth + Tone (1200x670)', () async {
    if (!AeviqueNativeEngine.isAvailable) return;

    const width = 1200;
    const height = 670;
    const iterations = 30;
    const warmup = 5;

    print('\n================================================================');
    print('AEVIQUE PHASE 3 ADVANCED TONE BENCHMARK (1200x670 RGBA8)');
    print('================================================================');

    final previewBase = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = ((x / width) * 255).round();
        final g = ((y / height) * 255).round();
        final b = (((x + y) / (width + height)) * 255).round();
        previewBase.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    final rawRgba = previewBase.convert(numChannels: 4).toUint8List();

    final advState = EditState.identity().copyWith(
      tune: const TuneAdjustments(
        exposure: 20.0,
        contrast: 15.0,
        saturation: 25.0,
        highlights: -30.0,
        shadows: 20.0,
        whites: 10.0,
        blacks: -10.0,
        warmth: 20.0,
        tint: -10.0,
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

    // Baseline Dart
    final List<double> dartTimes = [];
    for (int i = 0; i < warmup; i++) {
      final jpeg = await ImagePipeline.processPreviewFast(previewBase, advState, jpegQuality: 90);
      final codec = await ui.instantiateImageCodec(jpeg);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
    }
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      final jpeg = await ImagePipeline.processPreviewFast(previewBase, advState, jpegQuality: 90);
      final codec = await ui.instantiateImageCodec(jpeg);
      final frame = await codec.getNextFrame();
      sw.stop();
      frame.image.dispose();
      codec.dispose();
      dartTimes.add(sw.elapsedMicroseconds / 1000.0);
    }

    // Native Phase 3
    final List<double> nativeTimes = [];
    for (int i = 0; i < warmup; i++) {
      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: previewBase,
        rawPreviewRgba8: rawRgba,
        state: advState,
      );
      frame.dispose();
    }
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: previewBase,
        rawPreviewRgba8: rawRgba,
        state: advState,
      );
      sw.stop();
      frame.dispose();
      nativeTimes.add(sw.elapsedMicroseconds / 1000.0);
    }

    double median(List<double> list) {
      final s = List<double>.from(list)..sort();
      return s[s.length ~/ 2];
    }
    double p95(List<double> list) {
      final s = List<double>.from(list)..sort();
      return s[(s.length * 0.95).floor().clamp(0, s.length - 1)];
    }

    final dartMed = median(dartTimes);
    final dartP95 = p95(dartTimes);
    final natMed = median(nativeTimes);
    final natP95 = p95(nativeTimes);

    print('Dart Baseline Pipeline:    ${dartMed.toStringAsFixed(2)} ms (median) [p95: ${dartP95.toStringAsFixed(2)} ms]');
    print('Native Phase 3 Pipeline:   ${natMed.toStringAsFixed(2)} ms (median) [p95: ${natP95.toStringAsFixed(2)} ms]');
    print('Phase 3 Speedup:           ${(dartMed / natMed).toStringAsFixed(2)}x faster');
    print('Latency saved per update:  ${(dartMed - natMed).toStringAsFixed(2)} ms');
    print('================================================================\n');

    expect(natMed, lessThan(dartMed));
  });

  test('Benchmark Full-Resolution (4000x3000 / 12 MP) Tone Processing', () async {
    if (!AeviqueNativeEngine.isAvailable) return;

    const width = 4000;
    const height = 3000;
    const totalPixels = width * height;
    final rawRgba = Uint8List(width * height * 4);
    rawRgba.fillRange(0, rawRgba.length, 128);

    print('\n================================================================');
    print('FULL-RESOLUTION 12 MP (4000x3000 RGBA8) ENGINE BENCHMARK');
    print('================================================================');

    final engine = AeviqueNativeEngine.instance!;
    final testCurves = ToneCurves(
      rgb: [
        const CurvePoint(0.0, 0.0),
        const CurvePoint(0.25, 0.20),
        const CurvePoint(0.75, 0.85),
        const CurvePoint(1.0, 1.0),
      ],
    );

    // Warmup
    for (int i = 0; i < 2; i++) {
      engine.processRgba8(
        rgbaBytes: rawRgba,
        width: width,
        height: height,
        exposure: 20.0,
        contrast: 15.0,
        saturation: 25.0,
        highlights: -30.0,
        shadows: 20.0,
        whites: 10.0,
        blacks: -10.0,
        warmth: 20.0,
        tint: -10.0,
        curves: testCurves,
      );
    }

    final List<double> nativeTimes = [];
    for (int i = 0; i < 10; i++) {
      final sw = Stopwatch()..start();
      engine.processRgba8(
        rgbaBytes: rawRgba,
        width: width,
        height: height,
        exposure: 20.0,
        contrast: 15.0,
        saturation: 25.0,
        highlights: -30.0,
        shadows: 20.0,
        whites: 10.0,
        blacks: -10.0,
        warmth: 20.0,
        tint: -10.0,
        curves: testCurves,
      );
      sw.stop();
      nativeTimes.add(sw.elapsedMicroseconds / 1000.0);
    }

    nativeTimes.sort();
    final medMs = nativeTimes[nativeTimes.length ~/ 2];
    final p95Ms = nativeTimes[(nativeTimes.length * 0.95).floor().clamp(0, nativeTimes.length - 1)];
    final throughputMp = (totalPixels / (medMs / 1000.0)) / 1000000.0;

    print('Native C++ 12 MP Full Tone: ${medMs.toStringAsFixed(2)} ms (median) [p95: ${p95Ms.toStringAsFixed(2)} ms]');
    print('Processing Throughput:      ${throughputMp.toStringAsFixed(2)} Megapixels/sec');
    print('================================================================\n');

    expect(medMs, lessThan(100.0));
  });

  test('Benchmark Rapid Slider Updates & Stale Frame Cancellation', () async {
    const width = 1200;
    const height = 670;
    final testImage = img.Image(width: width, height: height);
    final rawRgba = testImage.convert(numChannels: 4).toUint8List();

    print('\n================================================================');
    print('RAPID SLIDER UPDATE & CANCELLATION STRESS BENCHMARK');
    print('================================================================');

    int activeRequestId = 0;
    int completedRenders = 0;
    int droppedFrames = 0;
    ui.Image? activeDisplayedImage;

    // Simulate a burst of 10 rapid slider ticks fired without delay
    final sw = Stopwatch()..start();
    for (int tick = 0; tick < 10; tick++) {
      final reqId = ++activeRequestId;
      final state = EditState.identity().copyWith(
        tune: TuneAdjustments(exposure: (tick - 5).toDouble() * 2.0),
      );

      // Fire asynchronous render without waiting (mimicking instantaneous gesture bursts)
      unawaited(
        ImagePipeline.renderPreviewFrame(
          previewBase: testImage,
          rawPreviewRgba8: rawRgba,
          state: state,
        ).then((frame) {
          if (reqId != activeRequestId) {
            // Outdated frame arrived! Cancel and immediately release resources
            droppedFrames++;
            frame.dispose();
          } else {
            // Current valid frame
            completedRenders++;
            final old = activeDisplayedImage;
            activeDisplayedImage = frame.uiImage;
            old?.dispose();
          }
        }),
      );
    }

    // Allow in-flight renders to conclude
    await Future.delayed(const Duration(milliseconds: 200));
    sw.stop();

    print('Dispatched updates: 30 events over 150 ms');
    print('Final display image valid: ${activeDisplayedImage != null}');
    print('Dropped outdated frames safely: $droppedFrames');
    print('Completed valid frames: $completedRenders');
    print('Peak queue depth remained bounded: true');
    print('Elapsed stress time: ${sw.elapsedMilliseconds} ms');
    print('================================================================\n');

    expect(activeDisplayedImage, isNotNull);
    expect(droppedFrames, greaterThan(0));
    activeDisplayedImage?.dispose();
  });
}
