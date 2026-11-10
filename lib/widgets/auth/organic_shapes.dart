import 'dart:math' as math;
import 'dart:ui';

abstract final class OrganicShapes {
  static double _round1(double v) => (v * 10.0).roundToDouble() / 10.0;

  /// Creates a smooth closed Path using polar coordinates sampled at [sampleCount] points
  /// and connected via Catmull-Rom to cubic Béziers with 1-decimal rounding.
  static Path polar(
    double Function(double angle) radiusFn, {
    int sampleCount = 96,
  }) {
    final List<Offset> points = [];
    for (int i = 0; i < sampleCount; i++) {
      final double a = (i / sampleCount) * math.pi * 2.0;
      final double r = radiusFn(a);
      points.add(Offset(_round1(math.cos(a) * r), _round1(math.sin(a) * r)));
    }

    final Path path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < sampleCount; i++) {
      final Offset p0 = points[(i - 1 + sampleCount) % sampleCount];
      final Offset p1 = points[i];
      final Offset p2 = points[(i + 1) % sampleCount];
      final Offset p3 = points[(i + 2) % sampleCount];

      final double cp1x = _round1(p1.dx + (p2.dx - p0.dx) / 6.0);
      final double cp1y = _round1(p1.dy + (p2.dy - p0.dy) / 6.0);
      final double cp2x = _round1(p2.dx - (p3.dx - p1.dx) / 6.0);
      final double cp2y = _round1(p2.dy - (p3.dy - p1.dy) / 6.0);
      final double endX = _round1(p2.dx);
      final double endY = _round1(p2.dy);

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, endX, endY);
    }

    path.close();
    return path;
  }

  /// Body path for Cookie (mustard scalloped cookie).
  static Path cookieBody() {
    return polar(
      (a) =>
          80.0 * (1.0 + 0.075 * math.pow(math.cos(a * 6.0).abs(), 0.6)) - 6.0,
      sampleCount: 96,
    );
  }

  /// Body path for Bean (cobalt capsule, 100 x 290).
  static Path beanBody() {
    final Path path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-50.0, -145.0, 100.0, 290.0),
        const Radius.circular(50.0),
      ),
    );
    return path;
  }

  /// Body path for Sun (green spiky cyclops, 120 samples).
  static Path sunBody() {
    return polar(
      (a) =>
          50.0 +
          14.0 *
              math.pow(math.max(0.0, math.cos(a * 5.0 + math.pi / 2.0)), 3) *
              1.4 -
          4.0,
      sampleCount: 120,
    );
  }

  /// Body path for Wobble (pink wobble).
  static Path wobbleBody() {
    return polar(
      (a) =>
          88.0 *
          (1.0 + 0.07 * math.sin(a * 4.0 + 0.5) + 0.05 * math.sin(a * 7.0)),
      sampleCount: 96,
    );
  }

  /// Body path for Pebble (orange lumpy pebble).
  static Path pebbleBody() {
    return polar(
      (a) =>
          128.0 *
          (1.0 +
              0.06 * math.sin(a * 2.0 + 1.0) +
              0.04 * math.sin(a * 3.0 + 2.0)),
      sampleCount: 96,
    );
  }

  /// Sweat droplet path.
  static Path sweatPath() {
    final Path path = Path();
    path.moveTo(0.0, 0.0);
    path.cubicTo(-6.0, 9.0, -5.0, 15.0, 0.0, 15.0);
    path.cubicTo(5.0, 15.0, 6.0, 9.0, 0.0, 0.0);
    path.close();
    return path;
  }

  /// Heart path.
  static Path heartPath() {
    final Path path = Path();
    path.moveTo(0.0, 4.0);
    path.cubicTo(-2.0, 0.0, -8.0, -1.0, -8.0, 4.0);
    path.cubicTo(-8.0, 8.0, -3.0, 11.0, 0.0, 14.0);
    path.cubicTo(3.0, 11.0, 8.0, 8.0, 8.0, 4.0);
    path.cubicTo(8.0, -1.0, 2.0, 0.0, 0.0, 4.0);
    path.close();
    return path;
  }

  /// Closed eye smiling (^): shown instead of the eye when happy.
  static Path happyEyePath(double r) {
    final Path path = Path();
    path.moveTo(-r * 0.72, r * 0.2);
    path.quadraticBezierTo(0.0, -r * 0.8, r * 0.72, r * 0.2);
    return path;
  }

  /// Brow above eye: shown when worried.
  static Path browPath(double r) {
    final Path path = Path();
    path.moveTo(-r * 0.75, -r - 9.0);
    path.quadraticBezierTo(0.0, -r - 13.0, r * 0.75, -r - 9.0);
    return path;
  }

  /// Star sparkle path with arm length [r].
  static Path starPath(double r) {
    final Path path = Path();
    path.moveTo(0.0, -r);
    path.lineTo(0.0, r);
    path.moveTo(-r, 0.0);
    path.lineTo(r, 0.0);
    return path;
  }

  /// Three short slanted blush lines under one eye coordinate ([x], [y]).
  static void _addBlushCluster(Path path, double x, double y) {
    path.moveTo(x - 9.0, y + 5.0);
    path.lineTo(x - 5.0, y - 1.0);
    path.moveTo(x - 2.0, y + 5.0);
    path.lineTo(x + 2.0, y - 1.0);
    path.moveTo(x + 5.0, y + 5.0);
    path.lineTo(x + 9.0, y - 1.0);
  }

  /// Blush lines under eye(s).
  static Path blushPath(List<Offset> eyeCenters, List<double> eyeRadii) {
    final Path path = Path();
    if (eyeCenters.isEmpty) return path;

    final Offset leftEye = eyeCenters.first;
    final double leftR = eyeRadii.first;
    _addBlushCluster(path, leftEye.dx, leftEye.dy + leftR + 8.0);

    if (eyeCenters.length > 1) {
      final Offset rightEye = eyeCenters.last;
      final double rightR = eyeRadii.last;
      _addBlushCluster(path, rightEye.dx, rightEye.dy + rightR + 8.0);
    }
    return path;
  }

  /// Mouth path morphed between worried, normal, relieved, and grin.
  static Path mouthPath({
    required double mx,
    required double my,
    required double w,
    required double cy1,
    required double cy2,
  }) {
    final Path path = Path();
    path.moveTo(_round1(mx - w), my);
    path.quadraticBezierTo(mx, _round1(cy1), _round1(mx + w), my);
    path.quadraticBezierTo(mx, _round1(cy2), _round1(mx - w), my);
    path.close();
    return path;
  }
}
