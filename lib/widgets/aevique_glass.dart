import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/aevique_theme.dart';

/// Genuine Translucent Frosted Glass Container
///
/// Implements iOS 26-inspired glass material:
/// - True backdrop blur via [BackdropFilter]
/// - Semi-transparent smoked fill
/// - Specular highlight border
/// - Optional amber active glow
class AeviqueGlass extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderWidth;
  final bool showAmberAccent;
  final bool showGoldAccent; // Compatibility alias
  final bool hasGrabHandle;
  final VoidCallback? onTap;

  const AeviqueGlass({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 0.8,
    this.showAmberAccent = false,
    this.showGoldAccent = false,
    this.hasGrabHandle = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AeviqueTheme.radiusLg);
    final isAccent = showAmberAccent || showGoldAccent;

    final containerDecoration = BoxDecoration(
      borderRadius: effectiveRadius,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        if (isAccent)
          BoxShadow(
            color: AeviqueTheme.accentAmber.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
      ],
    );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isAccent ? AeviqueTheme.accentAmberBg : AeviqueTheme.glassSmoked),
        borderRadius: effectiveRadius,
        border: Border.all(
          color: isAccent
              ? AeviqueTheme.accentAmber.withValues(alpha: 0.8)
              : (borderColor ?? AeviqueTheme.border),
          width: isAccent ? 1.2 : borderWidth,
        ),
      ),
      child: hasGrabHandle
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                child,
              ],
            )
          : child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: effectiveRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: containerDecoration,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}
