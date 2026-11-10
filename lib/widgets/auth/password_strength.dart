import 'package:flutter/widgets.dart';
import 'design_tokens.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final int passwordDots;
  final int maxDots;
  final double? top;

  const PasswordStrengthMeter({
    super.key,
    required this.passwordDots,
    this.maxDots = 9,
    this.top,
  });

  @override
  Widget build(BuildContext context) {
    final double fraction = (passwordDots / maxDots).clamp(0.0, 1.0);
    final Color fillColor = passwordDots < 4
        ? DesignTokens.weak
        : DesignTokens.strong;

    final Widget meterContainer = Container(
      height: DesignTokens.meterHeight,
      decoration: BoxDecoration(
        color: DesignTokens.meterTrack,
        borderRadius: BorderRadius.circular(DesignTokens.meterRadius),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction,
        heightFactor: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(DesignTokens.meterRadius),
          ),
        ),
      ),
    );

    if (top != null) {
      return Positioned(
        left: DesignTokens.meterInset,
        right: DesignTokens.meterInset,
        top: top,
        height: DesignTokens.meterHeight,
        child: meterContainer,
      );
    }

    return meterContainer;
  }
}
