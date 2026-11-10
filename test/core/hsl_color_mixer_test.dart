import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumafix/core/models/edit_state.dart';
import 'package:lumafix/core/image_engine/filter_kernels.dart';
import 'package:lumafix/core/native_engine/lumafix_ffi.dart';

void main() {
  setUpAll(() {
    final dylibPath = '${Directory.current.path}/native/lumafix_core/build/liblumafix_core.dylib';
    if (File(dylibPath).existsSync()) {
      LumaFixNativeEngine.tryLoad(customLibraryPath: dylibPath);
    }
  });

  group('HSL Color Mixer — 8 Color Bands Pixel Transformation Tests', () {
    final sampleBands = <HslColorBand, (int, int, int)>{
      HslColorBand.red: (230, 25, 25),       // ~0° hue
      HslColorBand.orange: (235, 115, 20),   // ~26° hue
      HslColorBand.yellow: (225, 225, 20),   // ~60° hue
      HslColorBand.green: (25, 220, 25),     // ~120° hue
      HslColorBand.aqua: (20, 215, 215),     // ~180° hue
      HslColorBand.blue: (25, 45, 230),      // ~234° hue
      HslColorBand.purple: (140, 25, 230),   // ~274° hue
      HslColorBand.magenta: (230, 25, 180),  // ~315° hue
    };

    for (final entry in sampleBands.entries) {
      final band = entry.key;
      final (r, g, b) = entry.value;

      test('Band ${band.displayName}: desaturation reduces chromatic difference', () {
        final image = img.Image(width: 4, height: 4);
        for (final p in image) {
          p.r = r; p.g = g; p.b = b; p.a = 255;
        }

        final hsl = const HslAdjustments().updateBand(band, saturation: -100.0);
        FilterKernels.applyHslMixer(image, hsl);

        final p = image.getPixel(0, 0);
        // Desaturated pixel should have R, G, B much closer to each other than original
        final origSpread = (r - g).abs() + (g - b).abs() + (b - r).abs();
        final newSpread = (p.r - p.g).abs() + (p.g - p.b).abs() + (p.b - p.r).abs();
        expect(newSpread, lessThan(origSpread / 2));
      });

      test('Band ${band.displayName}: luminance increase brightens the color', () {
        final image = img.Image(width: 4, height: 4);
        for (final p in image) {
          p.r = r; p.g = g; p.b = b; p.a = 255;
        }

        final hsl = const HslAdjustments().updateBand(band, luminance: 60.0);
        FilterKernels.applyHslMixer(image, hsl);

        final p = image.getPixel(0, 0);
        final origLuma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        final newLuma = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
        expect(newLuma, greaterThan(origLuma + 10));
      });

      test('Band ${band.displayName}: luminance decrease darkens the color', () {
        final image = img.Image(width: 4, height: 4);
        for (final p in image) {
          p.r = r; p.g = g; p.b = b; p.a = 255;
        }

        final hsl = const HslAdjustments().updateBand(band, luminance: -60.0);
        FilterKernels.applyHslMixer(image, hsl);

        final p = image.getPixel(0, 0);
        final origLuma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        final newLuma = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
        expect(newLuma, lessThan(origLuma - 10));
      });

      test('Band ${band.displayName}: hue shift changes pixel channels measurably', () {
        final image = img.Image(width: 4, height: 4);
        for (final p in image) {
          p.r = r; p.g = g; p.b = b; p.a = 255;
        }

        final hsl = const HslAdjustments().updateBand(band, hue: 60.0);
        FilterKernels.applyHslMixer(image, hsl);

        final p = image.getPixel(0, 0);
        final channelDelta = (p.r - r).abs() + (p.g - g).abs() + (p.b - b).abs();
        expect(channelDelta, greaterThan(5), reason: 'Hue shift must alter RGB channels');
      });
    }

    test('Zero dead zones: Foliage green-aqua transition (hue 150) responds smoothly to Green and Aqua', () {
      // 150° hue is halfway between green (120°) and aqua (180°)
      // In RGB: r=25, g=220, b=120
      final imgGreen = img.Image(width: 2, height: 2);
      for (final p in imgGreen) {
        p.r = 25; p.g = 220; p.b = 120; p.a = 255;
      }
      final hslGreen = const HslAdjustments().updateBand(HslColorBand.green, saturation: -80.0);
      FilterKernels.applyHslMixer(imgGreen, hslGreen);
      final pG = imgGreen.getPixel(0, 0);
      final deltaG = (pG.r - 25).abs() + (pG.g - 220).abs() + (pG.b - 120).abs();
      expect(deltaG, greaterThan(15), reason: 'Green slider must affect foliage at 150°');

      final imgAqua = img.Image(width: 2, height: 2);
      for (final p in imgAqua) {
        p.r = 25; p.g = 220; p.b = 120; p.a = 255;
      }
      final hslAqua = const HslAdjustments().updateBand(HslColorBand.aqua, saturation: -80.0);
      FilterKernels.applyHslMixer(imgAqua, hslAqua);
      final pA = imgAqua.getPixel(0, 0);
      final deltaA = (pA.r - 25).abs() + (pA.g - 220).abs() + (pA.b - 120).abs();
      expect(deltaA, greaterThan(10), reason: 'Aqua slider must affect foliage at 150°');
    });

    test('C++ Native Pipeline HSL processing parity across all 8 bands', () {
      if (!LumaFixNativeEngine.isAvailable) return;
      final engine = LumaFixNativeEngine.instance!;

      for (final entry in sampleBands.entries) {
        final band = entry.key;
        final (r, g, b) = entry.value;

        final rawBytes = Uint8List.fromList([r, g, b, 255]);
        final state = EditState.identity().copyWith(
          hsl: const HslAdjustments().updateBand(band, saturation: -100.0),
        );

        final processed = engine.processPipelineRgba8(
          rgbaBytes: rawBytes,
          width: 1,
          height: 1,
          state: state,
          inPlace: false,
        );

        final outR = processed[0];
        final outG = processed[1];
        final outB = processed[2];

        // Should be desaturated
        final newSpread = (outR - outG).abs() + (outG - outB).abs() + (outB - outR).abs();
        final origSpread = (r - g).abs() + (g - b).abs() + (b - r).abs();
        expect(newSpread, lessThan(origSpread / 2),
            reason: 'Native C++ HSL must desaturate ${band.displayName}');
      }
    });
  });
}
