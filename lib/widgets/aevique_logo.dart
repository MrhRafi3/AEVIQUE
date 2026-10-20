import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/aevique_theme.dart';

/// An original aperture-inspired geometric "A" logo for AEVIQUE.
///
/// Features precision geometric aperture blades converging into an architectural "A"
/// with a luminous champagne gold and ivory metallic finish.
class AeviqueLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final Color primaryColor;
  final Color accentColor;

  const AeviqueLogo({
    super.key,
    this.size = 64,
    this.showGlow = false,
    this.primaryColor = AeviqueTheme.champagneGold,
    this.accentColor = AeviqueTheme.ivory,
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
              color: primaryColor.withValues(alpha: 0.25),
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

    // Coordinate mapping relative to canvas size
    // Outer "A" Apex and Base Points
    final apex = Offset(w * 0.5, h * 0.12);
    final leftBase = Offset(w * 0.16, h * 0.88);
    final rightBase = Offset(w * 0.84, h * 0.88);

    // Inner Aperture Opening (Triangle)
    final innerApex = Offset(w * 0.5, h * 0.38);
    final innerLeft = Offset(w * 0.34, h * 0.64);
    final innerRight = Offset(w * 0.66, h * 0.64);

    // Paint for main Champagne Gold blades
    final goldPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Paint for subtle Ivory highlight facets
    final ivoryPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Filled center aperture iris
    final irisFillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // 1. Draw Inner Aperture Triangle (The Core Opening)
    final innerPath = Path()
      ..moveTo(innerApex.dx, innerApex.dy)
      ..lineTo(innerLeft.dx, innerLeft.dy)
      ..lineTo(innerRight.dx, innerRight.dy)
      ..close();
    canvas.drawPath(innerPath, irisFillPaint);
    canvas.drawPath(innerPath, goldPaint);

    // 2. Left Outer Aperture Blade (From base to apex)
    final leftLeg = Path()
      ..moveTo(leftBase.dx, leftBase.dy)
      ..lineTo(apex.dx, apex.dy);
    canvas.drawPath(leftLeg, goldPaint);

    // 3. Right Outer Aperture Blade (From base to apex)
    final rightLeg = Path()
      ..moveTo(rightBase.dx, rightBase.dy)
      ..lineTo(apex.dx, apex.dy);
    canvas.drawPath(rightLeg, goldPaint);

    // 4. Horizontal Cross-Blade
    final crossBar = Path()
      ..moveTo(w * 0.25, h * 0.64)
      ..lineTo(w * 0.75, h * 0.64);
    canvas.drawPath(crossBar, goldPaint);

    // 5. Converging Aperture Blades (Interlocking iris facets)
    // Blade 1: From left base toward inner apex
    final blade1 = Path()
      ..moveTo(leftBase.dx + w * 0.08, leftBase.dy)
      ..lineTo(innerApex.dx, innerApex.dy);
    canvas.drawPath(blade1, ivoryPaint);

    // Blade 2: From right base toward inner apex
    final blade2 = Path()
      ..moveTo(rightBase.dx - w * 0.08, rightBase.dy)
      ..lineTo(innerApex.dx, innerApex.dy);
    canvas.drawPath(blade2, ivoryPaint);

    // Blade 3: Precision apex center facet
    final centerSpire = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(innerApex.dx, innerApex.dy);
    canvas.drawPath(centerSpire, ivoryPaint);

    // 6. Central Aperture Jewel / Focal Node
    final jewelPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.53),
      math.max(1.5, w * 0.035),
      jewelPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AeviqueAperturePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
