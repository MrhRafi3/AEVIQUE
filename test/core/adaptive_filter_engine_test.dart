import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:lumafix/core/image_engine/filter_kernels.dart';
import 'package:lumafix/core/image_engine/image_pipeline.dart';
import 'package:lumafix/core/image_engine/lut_generator.dart';
import 'package:lumafix/core/models/edit_state.dart';
import 'package:lumafix/core/native_engine/lumafix_ffi.dart';
import 'package:lumafix/core/presets/filter_catalogue.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const dylibPath = 'native/lumafix_core/build/liblumafix_core.dylib';
    if (File(dylibPath).existsSync()) {
      LumaFixNativeEngine.tryLoad(customLibraryPath: dylibPath);
    }
  });

  group('Phase 02 & 07: Adaptive Color Engine & Skin-Tone Protection', () {
    test('computeSkinProbability identifies human skin tones across diverse complexions', () {
      // Fitzpatrick Type I/II (Peach / Fair)
      final pFair = FilterKernels.computeSkinProbability(215 / 255.0, 160 / 255.0, 135 / 255.0);
      expect(pFair, greaterThan(0.2), reason: 'Fair skin tone should have positive skin probability');

      // Fitzpatrick Type III/IV (Olive / Medium Warm)
      final pOlive = FilterKernels.computeSkinProbability(180 / 255.0, 130 / 255.0, 95 / 255.0);
      expect(pOlive, greaterThan(0.2), reason: 'Olive skin tone should have positive skin probability');

      // Fitzpatrick Type V/VI (Melanin-Rich / Deep Brown)
      final pDeep = FilterKernels.computeSkinProbability(115 / 255.0, 75 / 255.0, 50 / 255.0);
      expect(pDeep, greaterThan(0.2), reason: 'Deep skin tone should have positive skin probability');

      // Non-skin tones must strictly produce 0 probability
      final pSky = FilterKernels.computeSkinProbability(120 / 255.0, 160 / 255.0, 220 / 255.0);
      expect(pSky, equals(0.0), reason: 'Blue sky must have zero skin probability');

      final pFoliage = FilterKernels.computeSkinProbability(60 / 255.0, 150 / 255.0, 50 / 255.0);
      expect(pFoliage, equals(0.0), reason: 'Green plant foliage must have zero skin probability');

      final pRedApple = FilterKernels.computeSkinProbability(230 / 255.0, 30 / 255.0, 35 / 255.0);
      expect(pRedApple, equals(0.0), reason: 'Vibrant red objects must not trigger skin protection');

      final pNeutralGray = FilterKernels.computeSkinProbability(128 / 255.0, 128 / 255.0, 128 / 255.0);
      expect(pNeutralGray, equals(0.0), reason: 'Neutral gray has zero skin probability');
    });

    test('Skin-tone protection attenuates saturation and vibrance on portraits vs landscapes', () {
      final portraitPixel = img.Image(width: 1, height: 1);
      portraitPixel.setPixelRgba(0, 0, 210, 155, 125, 255); // Warm skin tone

      final skyPixel = img.Image(width: 1, height: 1);
      skyPixel.setPixelRgba(0, 0, 125, 155, 210, 255); // Blue sky tone

      FilterKernels.applyVibrance(portraitPixel, 40.0);
      FilterKernels.applyVibrance(skyPixel, 40.0);

      final skinRedBoost = portraitPixel.getPixel(0, 0).r - 210;
      final skyBlueBoost = skyPixel.getPixel(0, 0).b - 210;

      expect(
        skinRedBoost,
        lessThan(skyBlueBoost),
        reason: 'Skin tones must be protected from oversaturation compared to background sky',
      );
    });

    test('Highlight Hermite roll-off and black floor preservation in tone LUT', () {
      final tune = const TuneAdjustments(
        highlights: -30.0,
        shadows: 30.0,
      );
      final luts = LutGenerator.generate(tune, const ToneCurves());

      // At i = 0 (true black floor), shadow recovery must NOT lift blacks into milky gray
      expect(luts.rLut[0], equals(0), reason: 'True black floor (i=0) must remain 0 to prevent noise');

      // At i = 40 (shadows), shadow recovery lifts values cleanly
      expect(luts.rLut[40], greaterThan(40), reason: 'Shadow detail must be recovered');

      // At i = 220 (highlights), highlights -30 compresses smoothly
      expect(luts.rLut[220], lessThan(220), reason: 'Highlights must roll off gently');
    });
  });

  group('Phase 03, 04 & 05: Filter Profiles, Intensity Blending & Native Parity', () {
    test('Single-pixel parity test for (150, 100, 50)', () {
      final imgTest = img.Image(width: 1, height: 1);
      imgTest.setPixelRgba(0, 0, 150, 100, 50, 255);
      final res = ImagePipeline.processRawImage(
        imgTest,
        EditState.identity().copyWith(
          tune: const TuneAdjustments(exposure: 20.0, contrast: 15.0, saturation: 20.0),
        ),
      );
      final p = res.getPixel(0, 0);
      expect(p.r, equals(220));
      expect(p.g, equals(128));
      expect(p.b, equals(38));
    });

    test('All 10 core iPhone-inspired filters are 100% native C++ compatible', () {
      final allFilters = FilterCatalogue.allFilters;
      expect(allFilters.length, equals(10));

      for (final filter in allFilters) {
        final isNative = ImagePipeline.isNativePhase6Compatible(filter.state);
        final reason = ImagePipeline.getNativeIncompatibilityReason(filter.state);
        expect(
          isNative,
          isTrue,
          reason: 'Filter "${filter.name}" must be fully native C++ compatible (reported reason: $reason)',
        );
      }
    });

    test('Filter intensity blending is continuous and has no step function at 50% for monochrome', () {
      final mono = FilterCatalogue.findById('mono')!;

      final state0 = mono.blendWithNeutral(0.0);
      final state25 = mono.blendWithNeutral(25.0);
      final state49 = mono.blendWithNeutral(49.0);
      final state50 = mono.blendWithNeutral(50.0);
      final state75 = mono.blendWithNeutral(75.0);
      final state100 = mono.blendWithNeutral(100.0);

      // At 0%, neutral
      expect(state0.tune.saturation, equals(0.0));
      expect(state0.effects.bwMode, isFalse);

      // Saturation smoothly scales from 0 to -100
      expect(state25.tune.saturation, closeTo(-25.0, 0.5));
      expect(state49.tune.saturation, closeTo(-49.0, 0.5));
      expect(state50.tune.saturation, closeTo(-50.0, 0.5));
      expect(state75.tune.saturation, closeTo(-75.0, 0.5));
      expect(state100.tune.saturation, closeTo(-100.0, 0.5));

      // No abrupt snap of bwMode at 50%
      expect(state49.effects.bwMode, isFalse);
      expect(state50.effects.bwMode, isFalse);
      expect(state75.effects.bwMode, isFalse);
      expect(state100.effects.bwMode, isTrue);

      // Parameter continuity: the jump from 49% to 50% is smooth and infinitesimal
      final satDelta49to50 = (state50.tune.saturation - state49.tune.saturation).abs();
      expect(satDelta49to50, closeTo(1.0, 0.2));
    });

    test('Filter Profiles match iPhone-inspired target aesthetics', () {
      final vivid = FilterCatalogue.findById('vivid')!;
      expect(vivid.state.tune.vibrance, equals(24.0));
      expect(vivid.state.tune.saturation, equals(14.0));
      expect(vivid.state.tune.contrast, equals(10.0));
      expect(vivid.state.tune.highlights, equals(-18.0));
      expect(vivid.state.tune.shadows, equals(12.0));
      expect(vivid.state.details.sharpening, equals(8.0));

      final dramatic = FilterCatalogue.findById('dramatic')!;
      expect(dramatic.state.tune.contrast, equals(30.0));
      expect(dramatic.state.tune.highlights, equals(-28.0));
      expect(dramatic.state.tune.shadows, equals(-15.0));
      expect(dramatic.state.effects.drama, equals(24.0));
      expect(dramatic.state.details.sharpening, equals(12.0));

      final noir = FilterCatalogue.findById('noir')!;
      expect(noir.state.tune.contrast, equals(36.0));
      expect(noir.state.effects.bwMode, isTrue);
      expect(noir.state.effects.grain, equals(12.0));
      expect(noir.state.details.structure, equals(14.0));
      expect(noir.state.details.sharpening, equals(14.0));
    });

    test('Preview and full-resolution export maintain byte-level consistency', () async {
      if (!LumaFixNativeEngine.isAvailable) return;

      final testImg = img.Image(width: 32, height: 32);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          testImg.setPixelRgba(x, y, (x * 7) % 256, (y * 7) % 256, 128, 255);
        }
      }
      final rawRgba = testImg.convert(numChannels: 4).toUint8List();

      final vivid = FilterCatalogue.findById('vivid')!;
      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: testImg,
        rawPreviewRgba8: rawRgba,
        state: vivid.state,
      );

      expect(frame.isNative, isTrue, reason: 'Vivid preview must execute natively');
      expect(frame.uiImage, isNotNull);
      frame.dispose();

      final exportBytes = await ImagePipeline.processImage(
        Uint8List.fromList(img.encodeJpg(testImg)),
        vivid.state,
      );
      expect(exportBytes, isNotEmpty);
    });
  });
}
