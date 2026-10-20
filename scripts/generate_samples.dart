// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  print('Generating curated sample photographs for AEVIQUE...');

  // 1. Sunset Landscape (800x600): Golden Hour sky, mountains, lake reflection
  final landscape = img.Image(width: 800, height: 600);
  for (int y = 0; y < 600; y++) {
    for (int x = 0; x < 800; x++) {
      final ny = y / 600.0;
      final nx = x / 800.0;
      if (ny < 0.5) {
        // Sky: Warm gradient from deep amber at horizon to dark twilight indigo at top
        final skyT = ny / 0.5;
        final r = (80 + (skyT * 170) + (1.0 - (nx - 0.5).abs()) * 30)
            .clamp(0, 255)
            .round();
        final g = (40 + (skyT * 110)).clamp(0, 255).round();
        final b = (100 - (skyT * 60)).clamp(0, 255).round();
        landscape.setPixelRgba(x, y, r, g, b, 255);
      } else {
        // Water with golden sun reflection
        final waterT = (ny - 0.5) / 0.5;
        final wave = (math.sin(ny * 60.0 + nx * 20.0) * 8).round();
        final sunRefl =
            (1.0 - (nx - 0.5).abs() * 3.0).clamp(0.0, 1.0) * (1.0 - waterT);
        final r = (40 + sunRefl * 180 + wave).clamp(0, 255).round();
        final g = (35 + sunRefl * 110).clamp(0, 255).round();
        final b = (50 + (waterT * 40)).clamp(0, 255).round();
        landscape.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }
  // Mountain silhouette
  for (int x = 0; x < 800; x++) {
    final nx = x / 800.0;
    final mHeight =
        240 + (math.sin(nx * 8.0) * 40 + math.cos(nx * 14.0) * 25).round();
    for (int y = mHeight; y < 300; y++) {
      landscape.setPixelRgba(x, y, 22, 24, 32, 255);
    }
  }
  File(
    'assets/images/sample_landscape.jpg',
  ).writeAsBytesSync(img.encodeJpg(landscape, quality: 92));
  File(
    'assets/images/sample.jpg',
  ).writeAsBytesSync(img.encodeJpg(landscape, quality: 92));

  // 2. Nature & Greenery (800x600): Lush forest foliage, depth of field, moss tones
  final nature = img.Image(width: 800, height: 600);
  for (int y = 0; y < 600; y++) {
    for (int x = 0; x < 800; x++) {
      final nx = x / 800.0;
      final ny = y / 600.0;
      final noise = (math.sin(nx * 15.0) * math.cos(ny * 15.0) * 20).round();
      final r = (30 + noise + (ny * 30)).clamp(10, 120).round();
      final g = (90 + noise * 2 + ((1.0 - ny) * 50)).clamp(40, 210).round();
      final b = (45 + noise).clamp(20, 110).round();
      nature.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  // Sunlight flare through canopy
  for (int y = 0; y < 300; y++) {
    for (int x = 300; x < 600; x++) {
      final dist = math.sqrt(math.pow(x - 450, 2) + math.pow(y - 100, 2));
      if (dist < 180) {
        final flare = ((180 - dist) / 180.0) * 70;
        final p = nature.getPixel(x, y);
        nature.setPixelRgba(
          x,
          y,
          (p.r + flare * 1.2).clamp(0, 255).round(),
          (p.g + flare * 1.1).clamp(0, 255).round(),
          (p.b + flare * 0.4).clamp(0, 255).round(),
          255,
        );
      }
    }
  }
  File(
    'assets/images/sample_nature.jpg',
  ).writeAsBytesSync(img.encodeJpg(nature, quality: 92));

  // 3. Architecture: 800x600 high contrast architectural lines
  final arch = img.Image(width: 800, height: 600);
  for (int y = 0; y < 600; y++) {
    for (int x = 0; x < 800; x++) {
      final nx = x / 800.0;
      final ny = y / 600.0;
      final skyBlue = 40 + (ny * 120).round();
      final building = (math.sin(nx * 12.0).abs() * 60).round();
      final r = (30 + building * 0.4).clamp(0, 255).round();
      final g = (50 + building * 0.6 + (1 - ny) * 40).clamp(0, 255).round();
      final b = (skyBlue + building).clamp(0, 255).round();
      arch.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  for (int x = 100; x < 700; x += 80) {
    img.drawLine(
      arch,
      x1: x,
      y1: 150,
      x2: x + 40,
      y2: 600,
      color: img.ColorRgba8(220, 220, 240, 255),
    );
  }
  File(
    'assets/images/sample_architecture.jpg',
  ).writeAsBytesSync(img.encodeJpg(arch, quality: 92));

  // 4. Food & Still Life: 800x600 warm artisanal cafe still life
  final food = img.Image(width: 800, height: 600);
  for (int y = 0; y < 600; y++) {
    for (int x = 0; x < 800; x++) {
      final dist = math.sqrt(math.pow(x - 400, 2) + math.pow(y - 300, 2));
      final warmBase = (200 - (dist * 0.35)).clamp(40, 230).round();
      final r = (warmBase + 25).clamp(0, 255);
      final g = (warmBase * 0.72).clamp(0, 255).round();
      final b = (warmBase * 0.45).clamp(0, 255).round();
      food.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  img.drawCircle(
    food,
    x: 400,
    y: 300,
    radius: 180,
    color: img.ColorRgba8(245, 240, 230, 255),
  );
  img.drawCircle(
    food,
    x: 400,
    y: 300,
    radius: 178,
    color: img.ColorRgba8(210, 175, 124, 255),
  );
  img.fillCircle(
    food,
    x: 400,
    y: 300,
    radius: 110,
    color: img.ColorRgba8(170, 105, 50, 255),
  );
  File(
    'assets/images/sample_food.jpg',
  ).writeAsBytesSync(img.encodeJpg(food, quality: 92));

  print('All 5 curated photographs generated successfully.');
}
