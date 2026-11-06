import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/aevique_theme.dart';

/// Style variants for Liquid Glass surfaces.
enum LiquidGlassVariant {
  /// Highly transparent, watery surface for floating controls and navigation
  ultraClear,

  /// Standard transparent liquid glass for panels, bars, and sheets
  standard,

  /// Elevated glass with deeper optical depth for cards and floating docks
  elevated,

  /// Slightly more opaque optical glass for dialogs and critical readability
  modal,

  /// Primary Blue interactive glass accent
  accentBlue,

  /// Creative Orange secondary interactive glass accent
  accentOrange,

  /// Coral Red accent glass
  accentRed,
}

/// A premium, transparent liquid glass surface widget.
///
/// Simulates optical liquid glass:
/// - Real background refraction using [BackdropFilter]
/// - Specular highlight gradient along the glass perimeter
/// - Subtle internal caustic / ambient light reflection
/// - Soft optical drop shadow
class LiquidGlassPanel extends StatelessWidget {
  final Widget child;
  final double? blur;
  final LiquidGlassVariant variant;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? customBackgroundColor;
  final Color? customBorderColor;
  final double borderWidth;
  final bool hasGrabHandle;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool showChromaticGlow;
  final Color? glowColor;

  const LiquidGlassPanel({
    super.key,
    required this.child,
    this.variant = LiquidGlassVariant.standard,
    this.blur,
    this.borderRadius,
    this.padding,
    this.margin,
    this.customBackgroundColor,
    this.customBorderColor,
    this.borderWidth = 0.8,
    this.hasGrabHandle = false,
    this.onTap,
    this.width,
    this.height,
    this.showChromaticGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AeviqueTheme.radiusLg);

    // Transparency & blur determined by variant
    double effectiveBlur;
    Color baseGlassFill;
    LinearGradient borderGradient;
    Color? activeGlow;

    switch (variant) {
      case LiquidGlassVariant.ultraClear:
        effectiveBlur = blur ?? 18.0;
        baseGlassFill =
            customBackgroundColor ?? const Color(0x0CFFFFFF); // ~5% white tint
        borderGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x4DFFFFFF),
            Color(0x12FFFFFF),
            Color(0x08FFFFFF),
            Color(0x24FFFFFF),
          ],
          stops: [0.0, 0.4, 0.8, 1.0],
        );
        break;

      case LiquidGlassVariant.standard:
        effectiveBlur = blur ?? 24.0;
        baseGlassFill =
            customBackgroundColor ??
            const Color(0x1A141A29); // translucent tinted glass
        borderGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x66FFFFFF),
            Color(0x18FFFFFF),
            Color(0x0AFFFFFF),
            Color(0x38FFFFFF),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        );
        break;

      case LiquidGlassVariant.elevated:
        effectiveBlur = blur ?? 28.0;
        baseGlassFill =
            customBackgroundColor ??
            const Color(0x33101626); // 20% dark blue-gray
        borderGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x70FFFFFF),
            Color(0x22FFFFFF),
            Color(0x10FFFFFF),
            Color(0x45FFFFFF),
          ],
        );
        break;

      case LiquidGlassVariant.modal:
        effectiveBlur = blur ?? 32.0;
        baseGlassFill =
            customBackgroundColor ?? const Color(0x800E1422); // 50% dark glass
        borderGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x80FFFFFF),
            Color(0x28FFFFFF),
            Color(0x15FFFFFF),
            Color(0x55FFFFFF),
          ],
        );
        break;

      case LiquidGlassVariant.accentBlue:
        effectiveBlur = blur ?? 24.0;
        baseGlassFill = customBackgroundColor ?? const Color(0x333478F6);
        activeGlow = AeviqueTheme.primaryBlueGlow;
        borderGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x995E98FC),
            Color(0x443478F6),
            Color(0x223478F6),
            Color(0x665E98FC),
          ],
        );
        break;

      case LiquidGlassVariant.accentOrange:
        effectiveBlur = blur ?? 24.0;
        baseGlassFill = customBackgroundColor ?? const Color(0x33FF8A32);
        activeGlow = AeviqueTheme.creativeOrangeGlow;
        borderGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x99FFA663),
            Color(0x44FF8A32),
            Color(0x22FF8A32),
            Color(0x66FFA663),
          ],
        );
        break;

      case LiquidGlassVariant.accentRed:
        effectiveBlur = blur ?? 24.0;
        baseGlassFill = customBackgroundColor ?? const Color(0x33F04452);
        activeGlow = AeviqueTheme.coralRedGlow;
        borderGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x99F67580),
            Color(0x44F04452),
            Color(0x22F04452),
            Color(0x66F67580),
          ],
        );
        break;
    }

    final effectiveGlow = glowColor ?? activeGlow;

    Widget glassContent = ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: effectiveBlur,
          sigmaY: effectiveBlur,
        ),
        child: CustomPaint(
          painter: _LiquidGlassBorderPainter(
            radius: effectiveRadius,
            borderGradient: borderGradient,
            borderWidth: borderWidth,
            customBorderColor: customBorderColor,
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              color: baseGlassFill,
              borderRadius: effectiveRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.01),
                  Colors.black.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
            child: hasGrabHandle
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 12),
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      child,
                    ],
                  )
                : child,
          ),
        ),
      ),
    );

    if (margin != null) {
      glassContent = Padding(padding: margin!, child: glassContent);
    }

    // Wrap in outer glow & shadow
    Widget result = Container(
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          if ((showChromaticGlow || activeGlow != null) &&
              effectiveGlow != null)
            BoxShadow(
              color: effectiveGlow,
              blurRadius: 22,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: glassContent,
    );

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: result,
      );
    }

    return result;
  }
}

/// Custom painter for thin luminous specular glass edges
class _LiquidGlassBorderPainter extends CustomPainter {
  final BorderRadius radius;
  final LinearGradient borderGradient;
  final double borderWidth;
  final Color? customBorderColor;

  _LiquidGlassBorderPainter({
    required this.radius,
    required this.borderGradient,
    required this.borderWidth,
    this.customBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0) return;

    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect).deflate(borderWidth / 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (customBorderColor != null) {
      paint.color = customBorderColor!;
    } else {
      paint.shader = borderGradient.createShader(rect);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.customBorderColor != customBorderColor;
  }
}

/// Backward compatibility class for existing code referencing `AeviqueGlass`
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
  final bool showGoldAccent;
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
    final isAccent = showAmberAccent || showGoldAccent;
    return LiquidGlassPanel(
      variant: isAccent
          ? LiquidGlassVariant.accentOrange
          : LiquidGlassVariant.standard,
      blur: blur,
      customBackgroundColor: backgroundColor,
      customBorderColor: borderColor,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      borderWidth: borderWidth,
      hasGrabHandle: hasGrabHandle,
      onTap: onTap,
      child: child,
    );
  }
}
