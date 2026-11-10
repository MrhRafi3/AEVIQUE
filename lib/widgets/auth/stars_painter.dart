import 'package:flutter/widgets.dart';

import 'crew_data.dart';
import 'design_tokens.dart';
import 'login_animation_engine.dart';
import 'organic_shapes.dart';

/// CustomPainter rendering twinkling decorative stars and sparkles.
class StarsPainter extends CustomPainter {
  final RafiAnimationEngine engine;

  static final Paint _starPaint = Paint()
    ..color = RafiDesignTokens.characterInk.withValues(alpha: 0.55)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final List<Path> _cachedStarPaths = [
    for (final star in CrewData.stars) OrganicShapes.starPath(star.radius),
  ];

  StarsPainter({required this.engine}) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width > 0.0 ? size.width : 400.0;
    final double dx = (w - 400.0) / 2.0;
    final double scale = w < 400.0 ? (w / 400.0) : 1.0;

    final stars = engine.stars;
    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      if (star.scale <= 0.001) continue;

      canvas.save();
      if (dx != 0.0) {
        canvas.translate(dx, 0.0);
      }
      if (scale < 1.0) {
        canvas.translate(200.0, 160.0);
        canvas.scale(scale, scale);
        canvas.translate(-200.0, -160.0);
      }
      canvas.translate(star.definition.x, star.definition.y);
      canvas.rotate(star.rotation);
      canvas.scale(star.scale, star.scale);

      canvas.drawPath(_cachedStarPaths[i], _starPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => false;
}
