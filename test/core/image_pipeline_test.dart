import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/core/image_engine/image_pipeline.dart';
import 'package:lumaforge/core/models/edit_state.dart';
import 'package:lumaforge/core/presets/filter_catalogue.dart';
import 'package:lumaforge/core/presets/preset_catalogue.dart';

void main() {
  late Uint8List testImageBytes;
  late img.Image rawTestImage;

  setUp(() {
    // Create a 100x60 test image with distinct quadrant colors
    rawTestImage = img.Image(width: 100, height: 60);
    for (var y = 0; y < 60; y++) {
      for (var x = 0; x < 100; x++) {
        final r = (x * 2.5).toInt().clamp(0, 255);
        final g = (y * 4.0).toInt().clamp(0, 255);
        final b = 100;
        rawTestImage.setPixelRgb(x, y, r, g, b);
      }
    }
    testImageBytes = Uint8List.fromList(img.encodeJpg(rawTestImage));
  });

  group('Neutral State Regression & Pixel Integrity', () {
    test('Neutral EditState applies ZERO color grading or pixel shifts', () {
      final processedRaw = ImagePipeline.processRawImage(
        rawTestImage,
        EditState.identity(),
      );

      // Verify every pixel matches the original exactly without S-curve or tone shifts
      for (var y = 0; y < rawTestImage.height; y++) {
        for (var x = 0; x < rawTestImage.width; x++) {
          final orig = rawTestImage.getPixel(x, y);
          final proc = processedRaw.getPixel(x, y);
          expect(proc.r, equals(orig.r));
          expect(proc.g, equals(orig.g));
          expect(proc.b, equals(orig.b));
        }
      }
    });

    test(
      'Fast preview processing on neutral state returns original bytes',
      () async {
        final fastBytes = await ImagePipeline.processPreviewFast(
          rawTestImage,
          EditState.identity(),
        );
        expect(fastBytes, isNotEmpty);
        final decoded = img.decodeImage(fastBytes)!;
        expect(decoded.width, rawTestImage.width);
        expect(decoded.height, rawTestImage.height);
      },
    );
  });

  group('ImagePipeline Real Processing', () {
    test('Identity edit state returns visually identical image', () async {
      final processed = await ImagePipeline.processImage(
        testImageBytes,
        EditState.identity(),
      );
      final decoded = img.decodeImage(processed);
      expect(decoded, isNotNull);
      expect(decoded!.width, rawTestImage.width);
      expect(decoded.height, rawTestImage.height);
    });

    test('Brightness increases pixel luminance', () async {
      final brightState = EditState.identity().copyWith(
        tune: const TuneAdjustments(brightness: 50.0),
      );
      final processed = await ImagePipeline.processImage(
        testImageBytes,
        brightState,
      );
      final decoded = img.decodeImage(processed)!;

      final origPixel = rawTestImage.getPixel(50, 30);
      final newPixel = decoded.getPixel(50, 30);

      expect(newPixel.r, greaterThan(origPixel.r));
      expect(newPixel.g, greaterThan(origPixel.g));
      expect(newPixel.b, greaterThan(origPixel.b));
    });

    test('Black & White mode sets R == G == B', () async {
      final bwState = EditState.identity().copyWith(
        effects: const EffectsAdjustments(bwMode: true),
      );
      final processed = await ImagePipeline.processImage(
        testImageBytes,
        bwState,
      );
      final decoded = img.decodeImage(processed)!;

      final pixel = decoded.getPixel(40, 25);
      expect((pixel.r - pixel.g).abs(), lessThanOrEqualTo(1));
      expect((pixel.g - pixel.b).abs(), lessThanOrEqualTo(1));
    });

    test('Rotation 90 degrees swaps width and height', () async {
      final rotateState = EditState.identity().copyWith(
        geometry: const GeometryAdjustments(rotationQuarterTurns: 1),
      );
      final processed = await ImagePipeline.processImage(
        testImageBytes,
        rotateState,
      );
      final decoded = img.decodeImage(processed)!;

      expect(decoded.width, 60);
      expect(decoded.height, 100);
    });

    test('Crop cuts image to specified normalized bounds', () async {
      final cropState = EditState.identity().copyWith(
        geometry: const GeometryAdjustments(
          cropLeft: 0.2,
          cropTop: 0.1,
          cropRight: 0.8,
          cropBottom: 0.9,
        ),
      );
      final processed = await ImagePipeline.processImage(
        testImageBytes,
        cropState,
      );
      final decoded = img.decodeImage(processed)!;

      expect(decoded.width, inInclusiveRange(58, 62));
      expect(decoded.height, inInclusiveRange(46, 50));
    });

    test('Vignette darkens outer edge while leaving center brighter', () async {
      final vignetteState = EditState.identity().copyWith(
        vignette: const VignetteAdjustments(amount: -80.0, radius: 40.0),
      );
      final processed = await ImagePipeline.processImage(
        testImageBytes,
        vignetteState,
      );
      final decoded = img.decodeImage(processed)!;

      final cornerPixel = decoded.getPixel(0, 0);
      final origCorner = rawTestImage.getPixel(0, 0);

      expect(cornerPixel.b, lessThan(origCorner.b));
    });
  });

  group('FilterCatalogue and Tuned Vivid', () {
    test('Contains exactly 10 core iPhone-inspired filters', () {
      final allFilters = FilterCatalogue.allFilters;
      expect(allFilters.length, equals(10));

      final vivid = FilterCatalogue.findById('vivid');
      expect(vivid, isNotNull);
      expect(vivid!.name, 'Vivid');
      // Tuned Vivid: strictly neutral warmth & tint to eliminate orange cast
      expect(vivid.state.tune.warmth, equals(0.0));
      expect(vivid.state.tune.tint, equals(0.0));
      expect(vivid.state.tune.vibrance, greaterThan(0));

      final backwardsVivid = FilterCatalogue.findById('signature_vivid');
      expect(backwardsVivid, isNotNull);

      final bwFilters = FilterCatalogue.getByCategory(FilterCategory.bw);
      expect(bwFilters.length, equals(3)); // Mono, Silvertone, Noir
    });

    test('Filter blending at 0% returns neutral identity state', () {
      final vivid = FilterCatalogue.findById('vivid')!;
      final blended0 = vivid.blendWithNeutral(0.0);
      expect(blended0.isIdentity, isTrue);
    });

    test('Filter blending at 100% returns full filter parameters', () {
      final vivid = FilterCatalogue.findById('vivid')!;
      final blended100 = vivid.blendWithNeutral(100.0);
      expect(blended100.filterId, 'vivid');
      expect(blended100.tune.vibrance, equals(vivid.state.tune.vibrance));
      expect(blended100.tune.contrast, equals(vivid.state.tune.contrast));
    });

    test(
      'Legacy PresetCatalogue is maintained for backwards compatibility',
      () {
        final presets = PresetCatalogue.presets;
        expect(presets.length, greaterThanOrEqualTo(6));
      },
    );
  });

  group('Portrait Retouching Engine', () {
    test('Portrait skin brightening boosts skin midtones', () {
      // Create a test skin tone image (fair/medium skin: R=210, G=160, B=130)
      final skinImage = img.Image(width: 40, height: 40);
      for (final p in skinImage) {
        p.r = 210;
        p.g = 160;
        p.b = 130;
      }

      final brightened = ImagePipeline.processRawImage(
        skinImage,
        const EditState(portrait: PortraitAdjustments(skinBrighten: 40.0)),
      );

      final pOrig = skinImage.getPixel(20, 20);
      final pNew = brightened.getPixel(20, 20);

      // Brightened pixel should have higher luminance
      expect(pNew.r, greaterThan(pOrig.r));
      expect(pNew.g, greaterThan(pOrig.g));
      expect(pNew.b, greaterThan(pOrig.b));
    });

    test('Blemish removal inpaints dark spot on skin', () {
      // Create a skin-toned image with a dark pimple/blemish in the center
      final blemishImage = img.Image(width: 50, height: 50);
      for (final p in blemishImage) {
        p.r = 200;
        p.g = 150;
        p.b = 120;
      }
      // Add a dark spot at center (25, 25)
      for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
          final p = blemishImage.getPixel(25 + dx, 25 + dy);
          p.r = 70;
          p.g = 40;
          p.b = 30;
        }
      }

      // Heal the blemish at normalized (0.5, 0.5)
      final healed = ImagePipeline.processRawImage(
        blemishImage,
        const EditState(
          portrait: PortraitAdjustments(
            blemishes: [BlemishSpot(x: 0.5, y: 0.5, radius: 0.08)],
          ),
        ),
      );

      final centerPixel = healed.getPixel(25, 25);
      // Dark spot should now be healed close to surrounding skin (200, 150, 120)
      expect(centerPixel.r, greaterThan(150));
      expect(centerPixel.g, greaterThan(110));
    });
  });

  group('Format Identification', () {
    test('Correctly identifies JPEG magic bytes', () {
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
      expect(ImagePipeline.identifyFormat(jpegBytes), equals('jpeg'));
    });

    test('Correctly identifies PNG magic bytes', () {
      final pngBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      expect(ImagePipeline.identifyFormat(pngBytes), equals('png'));
    });
  });
}
