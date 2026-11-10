import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'design_tokens.dart';
import 'login_content.dart';

class SignupButton extends StatelessWidget {
  final bool isLoading;
  final bool isDone;
  final bool enabled;
  final String? label;
  final String? loadingLabel;
  final String? doneLabel;
  final double pressScale;
  final double spinnerAngle;
  final VoidCallback? onTap;
  final double? top;

  const SignupButton({
    super.key,
    required this.isLoading,
    required this.isDone,
    this.enabled = true,
    this.label,
    this.loadingLabel,
    this.doneLabel,
    this.pressScale = 1.0,
    required this.spinnerAngle,
    this.onTap,
    this.top,
  });

  @override
  Widget build(BuildContext context) {
    final String textLabel = isDone
        ? (doneLabel ?? RafiLoginContent.buttonDone)
        : (isLoading
              ? (loadingLabel ?? RafiLoginContent.buttonLoading)
              : (label ?? RafiLoginContent.button));

    final Color backgroundColor = isDone
        ? RafiDesignTokens.ok
        : RafiDesignTokens.buttonFill;

    final Widget buttonCore = Transform.scale(
      scale: pressScale,
      child: Semantics(
        button: true,
        enabled: !isLoading && !isDone && enabled,
        label: textLabel,
        child: GestureDetector(
          key: const Key('login_button'),
          onTap: (!isLoading && !isDone && enabled) ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: RafiDesignTokens.buttonHeight,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                RafiDesignTokens.buttonRadius,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  textLabel,
                  style: const TextStyle(
                    fontFamily: RafiDesignTokens.fontFamily,
                    package: RafiDesignTokens.fontPackage,
                    fontSize: RafiDesignTokens.buttonSize,
                    fontWeight: RafiDesignTokens.buttonWeight,
                    color: RafiDesignTokens.buttonText,
                    height: 1.0,
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(width: RafiDesignTokens.buttonGap),
                  Transform.rotate(
                    angle: spinnerAngle,
                    child: const CustomPaint(
                      size: Size(
                        RafiDesignTokens.spinnerSize,
                        RafiDesignTokens.spinnerSize,
                      ),
                      painter: _SpinnerPainter(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (top != null) {
      return Positioned(
        left: RafiDesignTokens.buttonInset,
        right: RafiDesignTokens.buttonInset,
        top: top,
        height: RafiDesignTokens.buttonHeight,
        child: buttonCore,
      );
    }

    return SizedBox(
      height: RafiDesignTokens.buttonHeight,
      width: double.infinity,
      child: buttonCore,
    );
  }
}

/// Compatibility alias for [SignupButton].
typedef RafiButton = SignupButton;
typedef LumaButton = SignupButton;

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint trackPaint = Paint()
      ..color = RafiDesignTokens.spinnerTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = RafiDesignTokens.spinnerWidth;

    final Paint arcPaint = Paint()
      ..color = RafiDesignTokens.buttonText
      ..style = PaintingStyle.stroke
      ..strokeWidth = RafiDesignTokens.spinnerWidth
      ..strokeCap = StrokeCap.round;

    // Background track ring
    canvas.drawArc(rect, 0.0, math.pi * 2.0, false, trackPaint);
    // Rotating active indicator segment
    canvas.drawArc(rect, 0.0, math.pi * 0.75, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
