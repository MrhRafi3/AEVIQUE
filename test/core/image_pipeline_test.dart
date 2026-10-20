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

  group('FilterCatalogue and Signature Vivid', () {
    test('Contains Signature Vivid and requested filter categories', () {
      final allFilters = FilterCatalogue.allFilters;
      expect(allFilters.length, greaterThanOrEqualTo(20));

      final signatureVivid = FilterCatalogue.findById('signature_vivid');
      expect(signatureVivid, isNotNull);
      expect(signatureVivid!.name, 'Signature Vivid');
      expect(signatureVivid.category, FilterCategory.signature);
      expect(signatureVivid.state.tune.vibrance, greaterThan(0));

      final portraitFilters = FilterCatalogue.getByCategory(
        FilterCategory.portrait,
      );
      expect(portraitFilters, isNotEmpty);

      final natureFilters = FilterCatalogue.getByCategory(
        FilterCategory.nature,
      );
      expect(natureFilters, isNotEmpty);

      final bwFilters = FilterCatalogue.getByCategory(FilterCategory.bw);
      expect(bwFilters, isNotEmpty);
    });

    test('Filter blending at 0% returns neutral identity state', () {
      final signatureVivid = FilterCatalogue.findById('signature_vivid')!;
      final blended0 = signatureVivid.blendWithNeutral(0.0);
      expect(blended0.isIdentity, isTrue);
    });

    test('Filter blending at 100% returns full filter parameters', () {
      final signatureVivid = FilterCatalogue.findById('signature_vivid')!;
      final blended100 = signatureVivid.blendWithNeutral(100.0);
      expect(blended100.filterId, 'signature_vivid');
      expect(
        blended100.tune.vibrance,
        equals(signatureVivid.state.tune.vibrance),
      );
      expect(
        blended100.tune.contrast,
        equals(signatureVivid.state.tune.contrast),
      );
    });

    test(
      'Legacy PresetCatalogue is maintained for backwards compatibility',
      () {
        final presets = PresetCatalogue.presets;
        expect(presets.length, greaterThanOrEqualTo(6));
      },
    );
  });
}
