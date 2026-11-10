import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumafix/core/models/mask_model.dart';
import 'package:lumafix/core/models/hsl_adjustments.dart';
import 'package:lumafix/core/image_engine/mask_engine.dart';

void main() {
  group('MaskModel & Raster Representation', () {
    test('SelectiveMask supports raster alpha buffer and defaults', () {
      final mask = SelectiveMask(
        id: 'mask_1',
        name: 'Test Mask',
        type: MaskType.brush,
      );

      expect(mask.type, MaskType.brush);
      expect(mask.inverted, isFalse);
      expect(mask.density, 1.0);
      expect(mask.adjustments.isIdentity, isTrue);
      expect(mask.maskBytes, isNull);
    });

    test('MaskToneAdjustments has complete Light, Color, HSL, and Effects fields', () {
      const tone = MaskToneAdjustments(
        exposure: 20.0,
        brightness: 10.0,
        contrast: 15.0,
        highlights: -30.0,
        shadows: 25.0,
        whites: 5.0,
        blacks: -10.0,
        warmth: 12.0,
        tint: -8.0,
        saturation: 18.0,
        vibrance: 22.0,
        clarity: 15.0,
        texture: 10.0,
        dehaze: 8.0,
        sharpness: 25.0,
      );

      expect(tone.isIdentity, isFalse);
      expect(tone.exposure, 20.0);
      expect(tone.whites, 5.0);
      expect(tone.blacks, -10.0);
      expect(tone.vibrance, 22.0);
      expect(tone.texture, 10.0);
      expect(tone.dehaze, 8.0);
      expect(tone.sharpness, 25.0);

      final reset = tone.copyWith(
        exposure: 0.0,
        brightness: 0.0,
        contrast: 0.0,
        highlights: 0.0,
        shadows: 0.0,
        whites: 0.0,
        blacks: 0.0,
        warmth: 0.0,
        tint: 0.0,
        saturation: 0.0,
        vibrance: 0.0,
        clarity: 0.0,
        texture: 0.0,
        dehaze: 0.0,
        sharpness: 0.0,
      );
      expect(reset.isIdentity, isTrue);
    });

    test('SelectiveMask serialization and deserialization preserves all adjustments and raster data', () {
      final alphaData = Uint8List.fromList([0, 128, 255, 64]);
      final mask = SelectiveMask(
        id: 'test_m',
        name: 'Subject 1',
        type: MaskType.subject,
        inverted: true,
        density: 0.85,
        maskBytes: alphaData,
        maskWidth: 2,
        maskHeight: 2,
        adjustments: const MaskToneAdjustments(
          exposure: 35.0,
          warmth: 20.0,
          vibrance: 15.0,
        ),
      );

      final json = mask.toJson();
      final restored = SelectiveMask.fromJson(json);

      expect(restored.id, 'test_m');
      expect(restored.type, MaskType.subject);
      expect(restored.inverted, isTrue);
      expect(restored.density, 0.85);
      expect(restored.maskWidth, 2);
      expect(restored.maskHeight, 2);
      expect(restored.maskBytes, isNotNull);
      expect(restored.maskBytes!.length, 4);
      expect(restored.adjustments.exposure, 35.0);
      expect(restored.adjustments.warmth, 20.0);
      expect(restored.adjustments.vibrance, 15.0);
    });
  });

  group('MaskEngine Local Adjustments Isolation & Alpha Blending', () {
    test('Adjustments alter ONLY the masked area; unmasked region remains bit-for-bit identical', () {
      // Create a 100x100 test image: left half red (200, 50, 50), right half blue (50, 50, 200)
      final image = img.Image(width: 100, height: 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          if (x < 50) {
            image.setPixelRgb(x, y, 200, 50, 50);
          } else {
            image.setPixelRgb(x, y, 50, 50, 200);
          }
        }
      }

      // Create a mask that selects ONLY the left half (x < 50)
      final maskAlpha = Uint8List(100 * 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          maskAlpha[y * 100 + x] = x < 50 ? 255 : 0;
        }
      }

      final mask = SelectiveMask(
        id: 'left_half',
        name: 'Left Mask',
        type: MaskType.brush,
        maskBytes: maskAlpha,
        maskWidth: 100,
        maskHeight: 100,
        adjustments: const MaskToneAdjustments(
          exposure: 50.0, // Significant brightening
          warmth: 30.0,
        ),
      );

      MaskEngine.applyMasks(image, [mask]);

      // Left half (masked) must be altered
      final pLeft = image.getPixel(25, 50);
      expect(pLeft.r, greaterThan(200));

      // Right half (unmasked) must remain strictly unchanged: (50, 50, 200)
      final pRight = image.getPixel(75, 50);
      expect(pRight.r, 50);
      expect(pRight.g, 50);
      expect(pRight.b, 200);
    });

    test('Mask inversion inverts affected area', () {
      final image = img.Image(width: 100, height: 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          image.setPixelRgb(x, y, 100, 100, 100);
        }
      }

      // Center circle mask: radius 20
      final maskAlpha = Uint8List(100 * 100);
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 100; x++) {
          final dist = math.sqrt((x - 50) * (x - 50) + (y - 50) * (y - 50));
          maskAlpha[y * 100 + x] = dist < 20 ? 255 : 0;
        }
      }

      // Inverted mask: affects everything EXCEPT the center circle
      final mask = SelectiveMask(
        id: 'inverted_mask',
        name: 'Background Mask',
        type: MaskType.brush,
        inverted: true,
        maskBytes: maskAlpha,
        maskWidth: 100,
        maskHeight: 100,
        adjustments: const MaskToneAdjustments(
          exposure: -40.0, // Darken background
        ),
      );

      MaskEngine.applyMasks(image, [mask]);

      // Center circle (unselected in inverted mask) remains 100
      final pCenter = image.getPixel(50, 50);
      expect(pCenter.r, 100);

      // Outside corner (selected in inverted mask) is darkened (< 100)
      final pCorner = image.getPixel(10, 10);
      expect(pCorner.r, lessThan(100));
    });

    test('Brush rasterization adds strokes and erases accurately', () {
      final buffer = Uint8List(100 * 100); // 100x100 all zeros

      // Paint a stroke at (50, 50) with radius 10
      MaskEngine.paintStrokeIntoBuffer(
        buffer: buffer,
        width: 100,
        height: 100,
        x0: 50,
        y0: 50,
        x1: 50,
        y1: 50,
        radius: 10,
        hardness: 0.8,
        opacity: 1.0,
        isErase: false,
      );

      // Center pixel (50, 50) should be 255
      expect(buffer[50 * 100 + 50], 255);
      // Pixel far away (10, 10) should be 0
      expect(buffer[10 * 100 + 10], 0);

      // Now erase with radius 5 at (50, 50)
      MaskEngine.paintStrokeIntoBuffer(
        buffer: buffer,
        width: 100,
        height: 100,
        x0: 50,
        y0: 50,
        x1: 50,
        y1: 50,
        radius: 5,
        hardness: 1.0,
        opacity: 1.0,
        isErase: true,
      );

      // Center pixel should now be 0
      expect(buffer[50 * 100 + 50], 0);
      // Pixel at distance 8 should still have paint
      expect(buffer[50 * 100 + 58], greaterThan(0));
    });

    test('Rubylith overlay renders scarlet tint on masked pixels', () {
      final image = img.Image(width: 10, height: 10);
      for (var y = 0; y < 10; y++) {
        for (var x = 0; x < 10; x++) {
          image.setPixelRgb(x, y, 100, 100, 100);
        }
      }

      final maskAlpha = Uint8List(10 * 10);
      for (var i = 0; i < maskAlpha.length; i++) {
        maskAlpha[i] = 255; // fully masked
      }

      final mask = SelectiveMask(
        id: 'overlay_m',
        name: 'Overlay Test',
        type: MaskType.brush,
        maskBytes: maskAlpha,
        maskWidth: 10,
        maskHeight: 10,
      );

      MaskEngine.applyMasks(image, [mask], showOverlay: true);

      final p = image.getPixel(5, 5);
      // Should have increased red channel and decreased green/blue channels from rubylith overlay
      expect(p.r, greaterThan(150));
      expect(p.g, lessThan(80));
      expect(p.b, lessThan(85));
    });

    test('HSL adjustments in masked area modify target hue band', () {
      final image = img.Image(width: 20, height: 20);
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 20; x++) {
          image.setPixelRgb(x, y, 220, 30, 30); // Pure Red
        }
      }

      final maskAlpha = Uint8List(20 * 20);
      for (var i = 0; i < maskAlpha.length; i++) {
        maskAlpha[i] = 255; // 全 mask
      }

      final mask = SelectiveMask(
        id: 'hsl_mask',
        name: 'HSL Mask',
        type: MaskType.brush,
        maskBytes: maskAlpha,
        maskWidth: 20,
        maskHeight: 20,
        adjustments: const MaskToneAdjustments(
          hsl: HslAdjustments(
            red: HslChannelAdjustment(hue: 60.0), // Shift red towards yellow
          ),
        ),
      );

      MaskEngine.applyMasks(image, [mask]);

      final p = image.getPixel(10, 10);
      // Shift towards yellow means green channel increases significantly
      expect(p.g, greaterThan(30));
    });
  });
}
