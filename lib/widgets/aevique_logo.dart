import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/aevique_theme.dart';

/// Minimal aperture-inspired geometric "A" logo for AEVIQUE.
///
/// Features precision geometric aperture blades in a clean modern aesthetic.
class AeviqueLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final Color primaryColor;
  final Color accentColor;

  const AeviqueLogo({
    super.key,
    this.size = 64,
    this.showGlow = false,
    this.primaryColor = AeviqueTheme.textPrimary,
    this.accentColor = AeviqueTheme.accentAmber,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: _AeviqueAperturePainter(
        primaryColor: primaryColor,
        accentColor: accentColor,
      ),
    );

    if (showGlow) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: size * 0.4,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }
}

class _AeviqueAperturePainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _AeviqueAperturePainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = math.max(1.5, w * 0.045);

    final apex = Offset(w * 0.5, h * 0.12);
    final leftBase = Offset(w * 0.16, h * 0.88);
    final rightBase = Offset(w * 0.84, h * 0.88);

    final innerApex = Offset(w * 0.5, h * 0.38);
    final innerLeft = Offset(w * 0.34, h * 0.64);
    final innerRight = Offset(w * 0.66, h * 0.64);

    final linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final irisFillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Inner Aperture Triangle
    final innerPath = Path()
      ..moveTo(innerApex.dx, innerApex.dy)
      ..lineTo(innerRight.dx, innerRight.dy)
      ..lineTo(innerLeft.dx, innerLeft.dy)
      ..close();

    canvas.drawPath(innerPath, irisFillPaint);
    canvas.drawPath(innerPath, accentPaint);

    // Outer "A" Frame
    final outerPath = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(rightBase.dx, rightBase.dy);

    canvas.drawPath(outerPath, linePaint);

    // Aperture Blade Lines
    final bladePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.7;

    canvas.drawLine(innerApex, Offset(w * 0.5, h * 0.22), bladePaint);
    canvas.drawLine(innerRight, Offset(w * 0.76, h * 0.76), bladePaint);
    canvas.drawLine(innerLeft, Offset(w * 0.24, h * 0.76), bladePaint);
  }

  @override
  bool shouldRepaint(covariant _AeviqueAperturePainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.accentColor != accentColor;
}
