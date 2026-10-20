// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  final dir = Directory('assets/images');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // 1. Generate landscape test image (1200x800) with dynamic range
  final landscape = img.Image(width: 1200, height: 800);
  for (var y = 0; y < 800; y++) {
    final ny = y / 800.0;
    for (var x = 0; x < 1200; x++) {
      // Sky gradient (warm sunset into deep blue)
      if (ny < 0.55) {
        final t = ny / 0.55;
        // Sun position around (800, 260)
        final dx = (x - 800) / 1200.0;
        final dy = (y - 260) / 800.0;
        final dist = math.sqrt(dx * dx + dy * dy);
        final sunGlow = math.max(0.0, 1.0 - dist * 4.0);

        final r = ((1.0 - t) * 40 + t * 240 + sunGlow * 180)
            .clamp(0, 255)
            .toInt();
        final g = ((1.0 - t) * 70 + t * 140 + sunGlow * 150)
            .clamp(0, 255)
            .toInt();
        final b = ((1.0 - t) * 160 + t * 60 + sunGlow * 80)
            .clamp(0, 255)
            .toInt();
        landscape.setPixelRgb(x, y, r, g, b);
      } else {
        // Water with reflection and waves
        final t = (ny - 0.55) / 0.45;
        final wave = math.sin(x * 0.08 + y * 0.2) * 8.0;
        final r = (30 + t * 40 + wave).clamp(0, 255).toInt();
        final g = (60 + t * 80 + wave * 0.8).clamp(0, 255).toInt();
        final b = (90 + t * 110 + wave * 1.2).clamp(0, 255).toInt();
        landscape.setPixelRgb(x, y, r, g, b);
      }
    }
  }

  // Draw mountains
  for (var x = 0; x < 1200; x++) {
    final mountainHeight =
        350 +
        (math.sin(x * 0.005) * 80 +
            math.cos(x * 0.015) * 40 +
            math.sin(x * 0.03) * 20);
    for (var y = mountainHeight.toInt(); y < 460; y++) {
      final shade = ((y - mountainHeight) / 110.0).clamp(0.0, 1.0);
      final r = (45 + shade * 30).toInt();
      final g = (48 + shade * 25).toInt();
      final b = (65 + shade * 20).toInt();
      landscape.setPixelRgb(x, y, r, g, b);
    }
  }

  File(
    'assets/images/sample.jpg',
  ).writeAsBytesSync(img.encodeJpg(landscape, quality: 92));
  print(
    'Generated assets/images/sample.jpg (${landscape.width}x${landscape.height})',
  );

  // 2. Generate portrait test image (800x1000)
  final portrait = img.Image(width: 800, height: 1000);
  for (var y = 0; y < 1000; y++) {
    for (var x = 0; x < 800; x++) {
      // Background gradient
      final bg = (40 + (y / 1000.0) * 50).toInt();
      portrait.setPixelRgb(x, y, bg, bg + 5, bg + 15);
    }
  }
  // Face oval
  for (var y = 250; y < 750; y++) {
    for (var x = 200; x < 600; x++) {
      final dx = (x - 400) / 180.0;
      final dy = (y - 500) / 230.0;
      if (dx * dx + dy * dy <= 1.0) {
        final r = (235 - dy * 30).clamp(0, 255).toInt();
        final g = (180 - dy * 25).clamp(0, 255).toInt();
        final b = (150 - dy * 20).clamp(0, 255).toInt();
        portrait.setPixelRgb(x, y, r, g, b);
      }
    }
  }
  File(
    'assets/images/sample_portrait.jpg',
  ).writeAsBytesSync(img.encodeJpg(portrait, quality: 92));
  print(
    'Generated assets/images/sample_portrait.jpg (${portrait.width}x${portrait.height})',
  );
}
