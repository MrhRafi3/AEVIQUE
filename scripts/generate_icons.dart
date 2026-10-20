// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  print('Generating AEVIQUE brand assets and Android launcher icons...');

  final sizes = {
    'assets/images/aevique_logo.png': 512,
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  for (final entry in sizes.entries) {
    final path = entry.key;
    final size = entry.value;

    final image = _renderAeviqueIcon(size);
    final pngBytes = img.encodePng(image);

    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes);
    print('Generated: $path (${size}x$size)');
  }

  print('Asset generation complete.');
}

img.Image _renderAeviqueIcon(int size) {
  final image = img.Image(width: size, height: size);

  // Deep Black background: #0B0B0D
  final bg = img.ColorRgba8(0x0B, 0x0B, 0x0D, 0xFF);
  img.fill(image, color: bg);

  // Subtle circular ambient glow in Champagne Gold
  final goldColor = img.ColorRgba8(0xD4, 0xAF, 0x7C, 0xFF);
  final goldDark = img.ColorRgba8(0x9E, 0x7E, 0x50, 0xFF);
  final ivoryColor = img.ColorRgba8(0xF8, 0xF6, 0xF0, 0xFF);

  // Subtle border / rounded badge background for launcher
  final center = (size / 2).round();
  final radius = (size * 0.46).round();
  img.drawCircle(
    image,
    x: center,
    y: center,
    radius: radius,
    color: img.ColorRgba8(0x18, 0x18, 0x20, 0xFF),
  );
  img.drawCircle(image, x: center, y: center, radius: radius, color: goldDark);

  final s = size.toDouble();

  // Draw Aperture 'A'
  final apexX = (s * 0.50).round();
  final apexY = (s * 0.20).round();

  final leftBaseX = (s * 0.22).round();
  final leftBaseY = (s * 0.78).round();

  final rightBaseX = (s * 0.78).round();
  final rightBaseY = (s * 0.78).round();

  final innerApexX = (s * 0.50).round();
  final innerApexY = (s * 0.42).round();

  final innerLeftX = (s * 0.36).round();
  final innerLeftY = (s * 0.62).round();

  final innerRightX = (s * 0.64).round();
  final innerRightY = (s * 0.62).round();

  // Draw main outer blades
  _drawLineThick(
    image,
    leftBaseX,
    leftBaseY,
    apexX,
    apexY,
    goldColor,
    (s * 0.035).clamp(1.0, 7.0).round(),
  );
  _drawLineThick(
    image,
    rightBaseX,
    rightBaseY,
    apexX,
    apexY,
    goldColor,
    (s * 0.035).clamp(1.0, 7.0).round(),
  );
  _drawLineThick(
    image,
    (s * 0.30).round(),
    innerLeftY,
    (s * 0.70).round(),
    innerLeftY,
    goldColor,
    (s * 0.035).clamp(1.0, 7.0).round(),
  );

  // Draw inner aperture iris
  _drawLineThick(
    image,
    innerApexX,
    innerApexY,
    innerLeftX,
    innerLeftY,
    ivoryColor,
    (s * 0.025).clamp(1.0, 5.0).round(),
  );
  _drawLineThick(
    image,
    innerApexX,
    innerApexY,
    innerRightX,
    innerRightY,
    ivoryColor,
    (s * 0.025).clamp(1.0, 5.0).round(),
  );
  _drawLineThick(
    image,
    innerLeftX,
    innerLeftY,
    innerRightX,
    innerRightY,
    ivoryColor,
    (s * 0.025).clamp(1.0, 5.0).round(),
  );

  // Center aperture jewel
  final jewelRadius = (s * 0.03).clamp(1.0, 6.0).round();
  img.fillCircle(
    image,
    x: apexX,
    y: (s * 0.53).round(),
    radius: jewelRadius,
    color: ivoryColor,
  );

  return image;
}

void _drawLineThick(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  img.Color color,
  int thickness,
) {
  img.drawLine(image, x1: x1, y1: y1, x2: x2, y2: y2, color: color);
  for (int o = 1; o <= thickness ~/ 2; o++) {
    img.drawLine(image, x1: x1 + o, y1: y1, x2: x2 + o, y2: y2, color: color);
    img.drawLine(image, x1: x1 - o, y1: y1, x2: x2 - o, y2: y2, color: color);
    img.drawLine(image, x1: x1, y1: y1 + o, x2: x2, y2: y2 + o, color: color);
    img.drawLine(image, x1: x1, y1: y1 - o, x2: x2, y2: y2 - o, color: color);
  }
}
