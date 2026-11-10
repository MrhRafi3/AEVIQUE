import 'package:flutter/widgets.dart';
import 'design_tokens.dart';

class TapIndicator extends StatelessWidget {
  final bool active;
  final Offset position;
  final double scale;
  final double opacity;

  const TapIndicator({
    super.key,
    required this.active,
    required this.position,
    required this.scale,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    if (!active || opacity <= 0.001) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: DesignTokens.tapSize,
      height: DesignTokens.tapSize,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.tapFill,
                shape: BoxShape.circle,
                border: Border.all(color: DesignTokens.tapEdge, width: 2.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
