import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import 'character_rig.dart';
import 'crew_data.dart';
import 'design_tokens.dart';
import 'login_animation_engine.dart';
import 'organic_shapes.dart';

class CharacterPainter extends CustomPainter {
  final RafiAnimationEngine engine;
  final CharacterLayer layer;

  static final Path _sweatPath = OrganicShapes.sweatPath();
  static final Path _heartPath = OrganicShapes.heartPath();

  // Static reusable Paint objects to completely eliminate GC allocations per frame
  static final Paint _bodyPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _whitePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _pupilPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _lidPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _happyEyePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _browPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _mouthStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _mouthFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _tonguePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _sweatPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final Paint _blushPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  static final Paint _heartPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // Cached happy and brow paths for each eye radius
  static final Map<double, Path> _cachedHappyPaths = {};
  static final Map<double, Path> _cachedBrowPaths = {};

  CharacterPainter({required this.engine, required this.layer})
    : super(repaint: engine);

  Path _getHappyPath(double r) =>
      _cachedHappyPaths.putIfAbsent(r, () => OrganicShapes.happyEyePath(r));

  Path _getBrowPath(double r) =>
      _cachedBrowPaths.putIfAbsent(r, () => OrganicShapes.browPath(r));

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width > 0.0 ? size.width : 400.0;
    final double h = size.height > 0.0 ? size.height : 860.0;

    for (final CharacterRig rig in engine.rigs) {
      if (rig.member.layer != layer) continue;
      _paintCharacter(canvas, rig, w, h);
    }
  }

  void _paintCharacter(Canvas canvas, CharacterRig rig, double w, double h) {
    final MemberDefinition m = rig.member;

    canvas.save();

    if (layer == CharacterLayer.back) {
      // Back characters (Cookie, Sun, Bean) centered horizontally
      final double dx = (w - 400.0) / 2.0;
      final double scale = w < 400.0 ? (w / 400.0) : 1.0;
      if (dx != 0.0) {
        canvas.translate(dx, 0.0);
      }
      if (scale < 1.0) {
        canvas.translate(200.0, 160.0);
        canvas.scale(scale, scale);
        canvas.translate(-200.0, -160.0);
      }
      canvas.translate(rig.rootTranslation.dx, rig.rootTranslation.dy);
    } else {
      // Front characters (Wobble, Pebble) anchored to bottom corners
      final double dy = h - 860.0;
      final double scale = w < 400.0 ? (w / 400.0) : 1.0;

      // On wide displays (tablet / desktop), anchor relative to centered 400px card
      final double cardLeft = w > 440.0 ? (w - 400.0) / 2.0 : 0.0;
      final double cardRight = w > 440.0 ? cardLeft + 400.0 : w;

      if (rig.index == 3) {
        // Wobble (bottom-left)
        canvas.translate(cardLeft, dy);
        if (scale < 1.0) {
          canvas.translate(34.0, 820.0);
          canvas.scale(scale, scale);
          canvas.translate(-34.0, -820.0);
        }
      } else if (rig.index == 4) {
        // Pebble (bottom-right)
        final double dx = cardRight - 400.0;
        canvas.translate(dx, dy);
        if (scale < 1.0) {
          canvas.translate(350.0, 870.0);
          canvas.scale(scale, scale);
          canvas.translate(-350.0, -870.0);
        }
      }
      canvas.translate(rig.rootTranslation.dx, rig.rootTranslation.dy);
    }

    canvas.rotate(rig.rootRotationDeg * (math.pi / 180.0));
    canvas.scale(rig.scaleX, rig.scaleY);

    // 1. Body
    _bodyPaint.color = m.color;
    canvas.drawPath(m.bodyPath, _bodyPaint);

    // 2. Face
    canvas.save();
    canvas.translate(rig.faceTranslation.dx, rig.faceTranslation.dy);

    // 2a. Eyes
    for (int k = 0; k < rig.eyes.length; k++) {
      final eye = rig.eyes[k];

      canvas.save();
      canvas.translate(eye.x, eye.y);

      // Normal eye (white + pupil + eyelid)
      if (eye.normalEyeOpacity > 0.001) {
        _whitePaint.color = RafiDesignTokens.eyeWhite.withValues(
          alpha: eye.normalEyeOpacity,
        );
        canvas.drawCircle(Offset.zero, eye.whiteRadius, _whitePaint);

        canvas.save();
        // Hardware accelerated clip without Path allocation
        canvas.clipRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: Offset.zero, radius: eye.clipRadius),
            Radius.circular(eye.clipRadius),
          ),
        );

        // Pupil
        _pupilPaint.color = RafiDesignTokens.characterInk.withValues(
          alpha: eye.normalEyeOpacity,
        );
        canvas.drawCircle(Offset(eye.px, eye.py), eye.pupilRadius, _pupilPaint);

        // Eyelid
        if (eye.lidHeight > 0.001) {
          _lidPaint.color = m.color.withValues(alpha: eye.normalEyeOpacity);
          final double lidH = (2.0 * eye.r + 4.0) * eye.lidHeight;
          canvas.drawRect(
            Rect.fromLTWH(-eye.r - 2.0, -eye.r - 2.0, 2.0 * eye.r + 4.0, lidH),
            _lidPaint,
          );
        }

        canvas.restore(); // end clip
      }

      // Happy eye arc
      if (eye.happyOpacity > 0.001) {
        _happyEyePaint.color = RafiDesignTokens.characterInk.withValues(
          alpha: eye.happyOpacity,
        );
        canvas.drawPath(_getHappyPath(eye.r), _happyEyePaint);
      }

      // Worried eyebrow
      if (eye.browOpacity > 0.001) {
        canvas.save();
        canvas.translate(0.0, eye.browTranslationY);
        canvas.rotate(eye.browRotation * (math.pi / 180.0));
        _browPaint.color = RafiDesignTokens.characterInk.withValues(
          alpha: eye.browOpacity,
        );
        canvas.drawPath(_getBrowPath(eye.r), _browPaint);
        canvas.restore();
      }

      canvas.restore(); // end eye
    }

    // 2b. Mouth
    if (rig.mouthPath != null) {
      if (rig.mouthFillOpacity > 0.001) {
        _mouthFillPaint.color = RafiDesignTokens.characterInk.withValues(
          alpha: rig.mouthFillOpacity,
        );
        canvas.drawPath(rig.mouthPath!, _mouthFillPaint);
      }
      _mouthStrokePaint.color = RafiDesignTokens.characterInk;
      canvas.drawPath(rig.mouthPath!, _mouthStrokePaint);
    }

    // 2c. Tongue
    if (rig.tongueOpacity > 0.001 &&
        rig.tongueRadiusX > 0.001 &&
        rig.tongueRadiusY > 0.001) {
      _tonguePaint.color = RafiDesignTokens.tongue.withValues(
        alpha: rig.tongueOpacity,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: rig.tongueCenter,
          width: rig.tongueRadiusX * 2.0,
          height: rig.tongueRadiusY * 2.0,
        ),
        _tonguePaint,
      );
    }

    // 2d. Sweat
    if (rig.sweatOpacity > 0.001) {
      canvas.save();
      canvas.translate(rig.sweatTranslation.dx, rig.sweatTranslation.dy);
      _sweatPaint.color = RafiDesignTokens.characterInk.withValues(
        alpha: rig.sweatOpacity,
      );
      canvas.drawPath(_sweatPath, _sweatPaint);
      canvas.restore();
    }

    // 2e. Blush
    if (rig.blushOpacity > 0.001) {
      _blushPaint.color = RafiDesignTokens.characterInk.withValues(
        alpha: rig.blushOpacity,
      );
      canvas.drawPath(m.blushPath, _blushPaint);
    }

    // 2f. Heart
    if (rig.heartOpacity > 0.001) {
      canvas.save();
      canvas.translate(rig.heartTranslation.dx, rig.heartTranslation.dy);
      canvas.scale(rig.heartScale, rig.heartScale);
      _heartPaint.color = RafiDesignTokens.characterInk.withValues(
        alpha: rig.heartOpacity,
      );
      canvas.drawPath(_heartPath, _heartPaint);
      canvas.restore();
    }

    canvas.restore(); // end face
    canvas.restore(); // end character
  }

  @override
  bool shouldRepaint(covariant CharacterPainter oldDelegate) => false;
}
