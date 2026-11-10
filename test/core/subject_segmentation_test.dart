import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumafix/core/native_engine/lumafix_ffi.dart';
import 'package:lumafix/core/image_engine/subject_segmentation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    LumaFixNativeEngine.tryLoad();
  });

  group('On-Device Subject Auto-Selection', () {
    test('Segments human subject on real portrait photograph (sample_portrait.jpg)', () async {
      final file = File('assets/images/sample_portrait.jpg');
      expect(file.existsSync(), isTrue, reason: 'sample_portrait.jpg must exist in assets/images');

      final bytes = file.readAsBytesSync();
      final image = img.decodeImage(bytes);
      expect(image, isNotNull);

      // Downsample test image to preview size for fast execution in tests
      final preview = img.copyResize(image!, width: 400);

      final maskResult = await SubjectSegmentationService.segmentSubject(preview);

      expect(maskResult.width, preview.width);
      expect(maskResult.height, preview.height);
      expect(maskResult.maskBytes.length, preview.width * preview.height);

      // Analyze mask distribution
      int foregroundCount = 0;
      final totalPixels = maskResult.width * maskResult.height;

      for (final alpha in maskResult.maskBytes) {
        if (alpha > 128) {
          foregroundCount++;
        }
      }

      final fgFraction = foregroundCount / totalPixels;
      // Portrait subject should occupy between 10% and 60% of the image
      expect(fgFraction, greaterThan(0.10), reason: 'Subject must be detected in foreground');
      expect(fgFraction, lessThan(0.60), reason: 'Subject mask must not cover the entire background');

      // Top corners should be background (low alpha)
      final topLeftAlpha = maskResult.getPixelAlpha(10, 10);
      final topRightAlpha = maskResult.getPixelAlpha(maskResult.width - 10, 10);
      expect(topLeftAlpha, lessThan(80), reason: 'Top-left corner is background');
      expect(topRightAlpha, lessThan(80), reason: 'Top-right corner is background');

      // Center (face/torso area) should be foreground (high alpha)
      final centerAlpha = maskResult.getPixelAlpha(
        (maskResult.width * 0.5).round(),
        (maskResult.height * 0.45).round(),
      );
      expect(centerAlpha, greaterThan(150), reason: 'Subject center should be selected');
    });

    test('Dart fallback segments human subject when native engine is disabled', () async {
      final file = File('assets/images/sample_portrait.jpg');
      final bytes = file.readAsBytesSync();
      final image = img.decodeImage(bytes);
      final preview = img.copyResize(image!, width: 300);

      final prevMode = LumaFixNativeEngine.engineMode;
      LumaFixNativeEngine.engineMode = EngineMode.dartOnly;

      try {
        final maskResult = await SubjectSegmentationService.segmentSubject(preview);

        expect(maskResult.width, preview.width);
        expect(maskResult.height, preview.height);

        // Top corners should be background
        expect(maskResult.getPixelAlpha(10, 10), lessThan(80));
        expect(maskResult.getPixelAlpha(maskResult.width - 10, 10), lessThan(80));

        // Center face area should be detected
        final centerAlpha = maskResult.getPixelAlpha(
          (maskResult.width * 0.5).round(),
          (maskResult.height * 0.45).round(),
        );
        expect(centerAlpha, greaterThan(150));
      } finally {
        LumaFixNativeEngine.engineMode = prevMode;
      }
    });
  });
}
