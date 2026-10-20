// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  print('Generating Architecture and Food sample images...');

  // 1. Architecture: 800x600 high contrast architectural lines
  final arch = img.Image(width: 800, height: 600);
  for (int y = 0; y < 600; y++) {
    for (int x = 0; x < 800; x++) {
      final nx = x / 800.0;
      final ny = y / 600.0;
      // Sky to glass facade gradient
      final skyBlue = 40 + (ny * 120).round();
      final building = (math.sin(nx * 12.0).abs() * 60).round();
      final r = (30 + building * 0.4).clamp(0, 255).round();
      final g = (50 + building * 0.6 + (1 - ny) * 40).clamp(0, 255).round();
      final b = (skyBlue + building).clamp(0, 255).round();
      arch.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  // Draw structural vertical and diagonal lines
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
  ).writeAsBytesSync(img.encodeJpg(arch, quality: 90));

  // 2. Food & Still Life: 800x600 warm artisanal cafe still life
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
  // Plate and pastry circles
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
  ).writeAsBytesSync(img.encodeJpg(food, quality: 90));

  print('Sample images generated successfully.');
}
