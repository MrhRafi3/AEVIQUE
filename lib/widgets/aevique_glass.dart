import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/aevique_theme.dart';

class AeviqueGlass extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderWidth;
  final bool showGoldAccent;

  const AeviqueGlass({
    super.key,
    required this.child,
    this.blur = 18.0,
    this.opacity = 0.72,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 1.0,
    this.showGoldAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          if (showGoldAccent)
            BoxShadow(
              color: AeviqueTheme.champagneGold.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AeviqueTheme.charcoalSurface.withValues(alpha: opacity),
              borderRadius: effectiveRadius,
              border: Border.all(
                color:
                    borderColor ??
                    (showGoldAccent
                        ? AeviqueTheme.champagneGold.withValues(alpha: 0.3)
                        : AeviqueTheme.border.withValues(alpha: 0.5)),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
