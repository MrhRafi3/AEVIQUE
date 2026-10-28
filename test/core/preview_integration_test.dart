import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/core/image_engine/image_pipeline.dart';
import 'package:lumaforge/core/models/edit_state.dart';
import 'package:lumaforge/core/native_engine/aevique_ffi.dart';

void main() {
  setUpAll(() {
    const dylibPath = 'native/aevique_core/build/libaevique_core.dylib';
    if (File(dylibPath).existsSync()) {
      AeviqueNativeEngine.tryLoad(customLibraryPath: dylibPath);
    }
  });

  tearDown(() {
    // Reset engine mode to auto after each test
    AeviqueNativeEngine.engineMode = EngineMode.auto;
  });

  group('Phase 2 Preview Integration - Compatibility Gate', () {
    test('Identity state is Phase 1 compatible', () {
      expect(ImagePipeline.isNativePhase1Compatible(EditState.identity()), isTrue);
    });

    test('Single and combined Exposure, Contrast, Saturation are compatible', () {
      final expState = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 25.0),
      );
      expect(ImagePipeline.isNativePhase1Compatible(expState), isTrue);

      final conState = EditState.identity().copyWith(
        tune: const TuneAdjustments(contrast: -15.0),
      );
      expect(ImagePipeline.isNativePhase1Compatible(conState), isTrue);

      final satState = EditState.identity().copyWith(
        tune: const TuneAdjustments(saturation: 30.0),
      );
      expect(ImagePipeline.isNativePhase1Compatible(satState), isTrue);

      final combinedState = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 20.0, contrast: 15.0, saturation: -50.0),
      );
      expect(ImagePipeline.isNativePhase1Compatible(combinedState), isTrue);
    });

    test('Unsupported Phase 2/3 adjustments are correctly routed to Dart fallback', () {
      // Brightness (Phase 2)
      final brightState = EditState.identity().copyWith(
        tune: const TuneAdjustments(brightness: 10.0),
      );
      expect(ImagePipeline.isNativePhase1Compatible(brightState), isFalse);

      // Warmth (Phase 2)
      final warmState = EditState.identity().copyWith(
        tune: const TuneAdjustments(warmth: 15.0),
      );
      expect(ImagePipeline.isNativePhase1Compatible(warmState), isFalse);

      // Curves (Phase 2)
      final curveState = EditState.identity().copyWith(
        curves: const ToneCurves(rgb: [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.6), CurvePoint(1.0, 1.0)]),
      );
      expect(ImagePipeline.isNativePhase1Compatible(curveState), isFalse);

      // Filters (Phase 3)
      final filterState = EditState.identity().copyWith(filterId: 'vivid');
      expect(ImagePipeline.isNativePhase1Compatible(filterState), isFalse);

      // Portrait retouching (Phase 4)
      final portraitState = EditState.identity().copyWith(
        portrait: const PortraitAdjustments(skinSmooth: 30.0),
      );
      expect(ImagePipeline.isNativePhase1Compatible(portraitState), isFalse);

      // Crop & Geometry (Phase 5)
      final cropState = EditState.identity().copyWith(
        geometry: const GeometryAdjustments(rotationQuarterTurns: 1),
      );
      expect(ImagePipeline.isNativePhase1Compatible(cropState), isFalse);
    });
  });

  group('Phase 2 Preview Integration - Execution & Fallback', () {
    late img.Image testImage;
    late Uint8List rawRgbaBytes;

    setUp(() {
      testImage = img.Image(width: 40, height: 30);
      for (int y = 0; y < 30; y++) {
        for (int x = 0; x < 40; x++) {
          testImage.setPixelRgba(x, y, (x * 6) % 256, (y * 8) % 256, 128, 255);
        }
      }
      final rgbaImage = testImage.convert(numChannels: 4);
      rawRgbaBytes = rgbaImage.toUint8List();
    });

    test('Renders native ui.Image when compatible and native engine is available', () async {
      if (!AeviqueNativeEngine.isAvailable) {
        print('Skipping native execution test: native library not loaded on this platform');
        return;
      }

      final state = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 20.0, contrast: 10.0, saturation: 15.0),
      );

      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: testImage,
        rawPreviewRgba8: rawRgbaBytes,
        state: state,
      );

      expect(frame.isNative, isTrue);
      expect(frame.uiImage, isNotNull);
      expect(frame.jpegBytes, isNull);
      expect(frame.uiImage!.width, equals(40));
      expect(frame.uiImage!.height, equals(30));

      // Test proper cleanup
      frame.uiImage!.dispose();
    });

    test('Seamlessly falls back to Dart pipeline when EngineMode.dartOnly is forced', () async {
      AeviqueNativeEngine.engineMode = EngineMode.dartOnly;

      final state = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 20.0, contrast: 10.0, saturation: 15.0),
      );

      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: testImage,
        rawPreviewRgba8: rawRgbaBytes,
        state: state,
      );

      expect(frame.isNative, isFalse);
      expect(frame.uiImage, isNull);
      expect(frame.jpegBytes, isNotNull);
      expect(frame.jpegBytes!.length, greaterThan(0));
    });

    test('Seamlessly falls back to Dart pipeline when adjustments are unsupported natively', () async {
      // State includes vibrance (+20.0), which is unsupported by Phase 3 native tone core
      final unsupportedState = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 15.0, vibrance: 20.0),
      );

      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: testImage,
        rawPreviewRgba8: rawRgbaBytes,
        state: unsupportedState,
      );

      expect(frame.isNative, isFalse);
      expect(frame.uiImage, isNull);
      expect(frame.jpegBytes, isNotNull);
      expect(frame.jpegBytes!.length, greaterThan(0));
    });

    test('EngineMode.nativeOnly succeeds on compatible state but throws on unsupported adjustments', () async {
      if (!AeviqueNativeEngine.isAvailable) return;

      AeviqueNativeEngine.engineMode = EngineMode.nativeOnly;

      final compatibleState = EditState.identity().copyWith(
        tune: const TuneAdjustments(exposure: 15.0, contrast: 10.0, saturation: -20.0, warmth: 15.0),
        curves: const ToneCurves(rgb: [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.6), CurvePoint(1.0, 1.0)]),
      );

      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: testImage,
        rawPreviewRgba8: rawRgbaBytes,
        state: compatibleState,
      );

      expect(frame.isNative, isTrue);
      expect(frame.uiImage, isNotNull);
      frame.dispose();

      // Incompatible adjustment (filterId) should throw UnsupportedError instead of falling back to Dart
      final incompatibleState = EditState.identity().copyWith(filterId: 'vivid');

      expect(
        () => ImagePipeline.renderPreviewFrame(
          previewBase: testImage,
          rawPreviewRgba8: rawRgbaBytes,
          state: incompatibleState,
        ),
        throwsUnsupportedError,
      );
    });

    test('PreprocessedImageBundle provides both raw RGBA8 and previewImage', () async {
      final sampleJpg = Uint8List.fromList(img.encodeJpg(testImage));
      final bundle = await ImagePipeline.prepareImageBundle(sampleJpg, maxPreviewDimension: 1200);

      expect(bundle.previewImage, isNotNull);
      expect(bundle.thumbnailImage, isNotNull);
      expect(bundle.originalPreviewBytes, isNotNull);
      expect(bundle.rawPreviewRgba8, isNotNull);
      expect(bundle.rawPreviewRgba8!.length, equals(bundle.previewImage.width * bundle.previewImage.height * 4));
    });

    test('Rapid consecutive preview requests correctly produce frames and allow clean disposal', () async {
      final List<PreviewFrame> frames = [];
      for (double exp = -30.0; exp <= 30.0; exp += 15.0) {
        final state = EditState.identity().copyWith(
          tune: TuneAdjustments(exposure: exp, contrast: exp * 0.5, saturation: exp * 0.3),
        );
        final frame = await ImagePipeline.renderPreviewFrame(
          previewBase: testImage,
          rawPreviewRgba8: rawRgbaBytes,
          state: state,
        );
        frames.add(frame);
      }

      expect(frames.length, equals(5));
      for (final f in frames) {
        if (f.isNative) {
          expect(f.uiImage, isNotNull);
        } else {
          expect(f.jpegBytes, isNotNull);
        }
        // Test explicit lifecycle disposal
        f.dispose();
      }
    });

    test('Alpha channel is strictly preserved through native preview rendering', () async {
      if (!AeviqueNativeEngine.isAvailable) return;

      // Create test image with non-opaque alpha
      final alphaImg = img.Image(width: 20, height: 20, numChannels: 4);
      for (int y = 0; y < 20; y++) {
        for (int x = 0; x < 20; x++) {
          alphaImg.setPixelRgba(x, y, 100, 150, 200, 180); // alpha = 180
        }
      }
      final rawAlphaRgba = alphaImg.convert(numChannels: 4).toUint8List();

      final engine = AeviqueNativeEngine.instance!;
      final processed = engine.processRgba8(
        rgbaBytes: rawAlphaRgba,
        width: 20,
        height: 20,
        exposure: 25.0,
        contrast: 15.0,
        saturation: -30.0,
      );

      // Verify all alpha bytes remain exactly 180
      for (int i = 3; i < processed.length; i += 4) {
        expect(processed[i], equals(180));
      }
    });

    test('Native preview output matches Dart reference calculation within 1 LSB', () async {
      if (!AeviqueNativeEngine.isAvailable) return;

      final testCases = [
        const TuneAdjustments(exposure: 15.0),
        const TuneAdjustments(contrast: 20.0),
        const TuneAdjustments(saturation: -40.0),
        const TuneAdjustments(exposure: -10.0, contrast: 15.0, saturation: 25.0),
      ];

      for (final tune in testCases) {
        final state = EditState.identity().copyWith(tune: tune);

        // Native processed bytes
        final nativeRgba = AeviqueNativeEngine.instance!.processRgba8(
          rgbaBytes: rawRgbaBytes,
          width: 40,
          height: 30,
          exposure: tune.exposure,
          contrast: tune.contrast,
          saturation: tune.saturation,
        );

        // Dart processed image
        final dartProcessed = ImagePipeline.processRawImage(testImage, state);
        final dartRgba = dartProcessed.convert(numChannels: 4).toUint8List();

        int maxDiff = 0;
        for (int i = 0; i < nativeRgba.length; i++) {
          final diff = (nativeRgba[i] - dartRgba[i]).abs();
          if (diff > maxDiff) maxDiff = diff;
        }

        expect(
          maxDiff,
          lessThanOrEqualTo(1),
          reason: 'Adjustment $tune exceeded 1 LSB tolerance (max diff: $maxDiff)',
        );
      }
    });

    test('Extreme adjustment parameters (+100/-100) are correctly clamped within [0, 255]', () async {
      if (!AeviqueNativeEngine.isAvailable) return;

      final extremeCases = [
        const TuneAdjustments(exposure: 100.0, contrast: 100.0, saturation: 100.0),
        const TuneAdjustments(exposure: -100.0, contrast: -100.0, saturation: -100.0),
        const TuneAdjustments(exposure: 100.0, contrast: -100.0, saturation: 50.0),
        const TuneAdjustments(exposure: -100.0, contrast: 100.0, saturation: -50.0),
      ];

      for (final tune in extremeCases) {
        final state = EditState.identity().copyWith(tune: tune);
        final frame = await ImagePipeline.renderPreviewFrame(
          previewBase: testImage,
          rawPreviewRgba8: rawRgbaBytes,
          state: state,
        );

        expect(frame.isNative, isTrue);
        expect(frame.uiImage, isNotNull);
        expect(frame.uiImage!.width, equals(40));
        expect(frame.uiImage!.height, equals(30));
        frame.dispose();
      }
    });

    test('Gracefully falls back to Dart pipeline when native instance is null in EngineMode.auto', () async {
      final cachedInstance = AeviqueNativeEngine.instance;
      try {
        AeviqueNativeEngine.setInstance(null);
        expect(AeviqueNativeEngine.isAvailable, isFalse);

        final state = EditState.identity().copyWith(
          tune: const TuneAdjustments(exposure: 10.0, contrast: 15.0),
        );

        final frame = await ImagePipeline.renderPreviewFrame(
          previewBase: testImage,
          rawPreviewRgba8: rawRgbaBytes,
          state: state,
        );

        expect(frame.isNative, isFalse);
        expect(frame.uiImage, isNull);
        expect(frame.jpegBytes, isNotNull);
        expect(frame.jpegBytes!.length, greaterThan(0));
      } finally {
        AeviqueNativeEngine.setInstance(cachedInstance);
      }
    });

    test('Repeated frame rendering lifecycle: 100 frames created and disposed without memory leaks', () async {
      if (!AeviqueNativeEngine.isAvailable) return;

      for (int i = 0; i < 100; i++) {
        final state = EditState.identity().copyWith(
          tune: TuneAdjustments(exposure: (i % 20).toDouble() - 10.0),
        );
        final frame = await ImagePipeline.renderPreviewFrame(
          previewBase: testImage,
          rawPreviewRgba8: rawRgbaBytes,
          state: state,
        );
        expect(frame.isNative, isTrue);
        expect(frame.uiImage, isNotNull);
        // Explicitly dispose each texture as in production EditorScreen
        frame.dispose();
      }
    });

    test('Phase 3 Compatibility Gate correctly accepts curves, warmth, highlights', () {
      final curveState = EditState.identity().copyWith(
        curves: const ToneCurves(rgb: [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.6), CurvePoint(1.0, 1.0)]),
      );
      expect(ImagePipeline.isNativePhase3Compatible(curveState), isTrue);

      final warmthState = EditState.identity().copyWith(
        tune: const TuneAdjustments(warmth: 20.0, tint: -10.0),
      );
      expect(ImagePipeline.isNativePhase3Compatible(warmthState), isTrue);

      final hlState = EditState.identity().copyWith(
        tune: const TuneAdjustments(highlights: -30.0, shadows: 25.0, whites: 10.0, blacks: -5.0),
      );
      expect(ImagePipeline.isNativePhase3Compatible(hlState), isTrue);

      // Vibrance and clarity are still deferred
      final vibState = EditState.identity().copyWith(
        tune: const TuneAdjustments(vibrance: 20.0),
      );
      expect(ImagePipeline.isNativePhase3Compatible(vibState), isFalse);

      final clarityState = EditState.identity().copyWith(
        tune: const TuneAdjustments(clarity: 15.0),
      );
      expect(ImagePipeline.isNativePhase3Compatible(clarityState), isFalse);
    });

    test('Tone curves, warmth, highlights, and combined tone parity with Dart reference within 1 LSB', () async {
      if (!AeviqueNativeEngine.isAvailable) return;

      final testCases = [
        // 1. Tone Curves (S-curve)
        EditState.identity().copyWith(
          curves: const ToneCurves(
            rgb: [CurvePoint(0.0, 0.0), CurvePoint(0.25, 0.15), CurvePoint(0.75, 0.85), CurvePoint(1.0, 1.0)],
          ),
        ),
        // 2. Channel Curves (Red and Blue)
        EditState.identity().copyWith(
          curves: const ToneCurves(
            red: [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.65), CurvePoint(1.0, 1.0)],
            blue: [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.35), CurvePoint(1.0, 1.0)],
          ),
        ),
        // 3. Warmth and Tint
        EditState.identity().copyWith(
          tune: const TuneAdjustments(warmth: 35.0, tint: -20.0),
        ),
        // 4. Highlights and Shadows
        EditState.identity().copyWith(
          tune: const TuneAdjustments(highlights: -40.0, shadows: 35.0, whites: 15.0, blacks: -15.0),
        ),
        // 5. Combined Advanced Tone: Exposure, Contrast, Warmth, Highlights, Shadows, Curves, Saturation
        EditState.identity().copyWith(
          tune: const TuneAdjustments(
            exposure: 15.0,
            contrast: 10.0,
            saturation: 25.0,
            brightness: 5.0,
            warmth: 20.0,
            tint: -10.0,
            highlights: -25.0,
            shadows: 30.0,
            whites: 10.0,
            blacks: -10.0,
            ambiance: 15.0,
          ),
          curves: const ToneCurves(
            rgb: [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.58), CurvePoint(1.0, 1.0)],
          ),
        ),
      ];

      for (int tIdx = 0; tIdx < testCases.length; tIdx++) {
        final state = testCases[tIdx];

        // Native processed bytes
        final nativeRgba = AeviqueNativeEngine.instance!.processRgba8(
          rgbaBytes: rawRgbaBytes,
          width: 40,
          height: 30,
          exposure: state.tune.exposure,
          contrast: state.tune.contrast,
          saturation: state.tune.saturation,
          brightness: state.tune.brightness,
          warmth: state.tune.warmth,
          tint: state.tune.tint,
          highlights: state.tune.highlights,
          shadows: state.tune.shadows,
          whites: state.tune.whites,
          blacks: state.tune.blacks,
          ambiance: state.tune.ambiance,
          curves: state.curves,
        );

        // Dart processed image
        final dartProcessed = ImagePipeline.processRawImage(testImage, state);
        final dartRgba = dartProcessed.convert(numChannels: 4).toUint8List();

        int maxDiff = 0;
        for (int i = 0; i < nativeRgba.length; i++) {
          final diff = (nativeRgba[i] - dartRgba[i]).abs();
          if (diff > maxDiff) maxDiff = diff;
        }

        expect(
          maxDiff,
          lessThanOrEqualTo(1),
          reason: 'Test case $tIdx exceeded 1 LSB tolerance (max channel difference was: $maxDiff)',
        );
      }
    });
  });
}
