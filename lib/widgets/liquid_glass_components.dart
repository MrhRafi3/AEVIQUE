import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/aevique_theme.dart';
import 'aevique_glass.dart';

/// Button variant for [LiquidGlassButton]
enum LiquidGlassButtonVariant {
  primaryBlue,
  creativeOrange,
  destructiveRed,
  neutralGlass,
}

/// A premium, transparent liquid glass interactive button.
class LiquidGlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final LiquidGlassButtonVariant variant;
  final bool isLoading;
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = LiquidGlassButtonVariant.primaryBlue,
    this.isLoading = false,
    this.height = 50.0,
    this.width,
    this.borderRadius = AeviqueTheme.radiusLg,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color glowColor;
    Color gradientStart;
    Color gradientEnd;
    Color textColor = Colors.white;

    switch (variant) {
      case LiquidGlassButtonVariant.primaryBlue:
        glowColor = AeviqueTheme.primaryBlueGlow;
        gradientStart = const Color(0xE63478F6);
        gradientEnd = const Color(0xCC1E5AD6);
        break;
      case LiquidGlassButtonVariant.creativeOrange:
        glowColor = AeviqueTheme.creativeOrangeGlow;
        gradientStart = const Color(0xE6FF8A32);
        gradientEnd = const Color(0xCCDF6B15);
        break;
      case LiquidGlassButtonVariant.destructiveRed:
        glowColor = AeviqueTheme.coralRedGlow;
        gradientStart = const Color(0xE6F04452);
        gradientEnd = const Color(0xCCD32635);
        break;
      case LiquidGlassButtonVariant.neutralGlass:
        glowColor = Colors.white.withValues(alpha: 0.12);
        gradientStart = const Color(0x33FFFFFF);
        gradientEnd = const Color(0x14FFFFFF);
        textColor = AeviqueTheme.textPrimary;
        break;
    }

    final radius = BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (onPressed != null &&
              variant != LiquidGlassButtonVariant.neutralGlass)
            BoxShadow(
              color: glowColor,
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: LiquidGlassPanel(
        variant: LiquidGlassVariant.ultraClear,
        borderRadius: radius,
        blur: 16.0,
        customBackgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: (onPressed == null || isLoading)
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onPressed!();
                    },
              child: Padding(
                padding:
                    padding ?? const EdgeInsets.symmetric(horizontal: 20.0),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 18, color: textColor),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A floating liquid glass toolbar with icon pills.
class LiquidGlassToolbar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double height;
  final double borderRadius;

  const LiquidGlassToolbar({
    super.key,
    required this.children,
    this.padding,
    this.height = 56.0,
    this.borderRadius = AeviqueTheme.radiusFull,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      variant: LiquidGlassVariant.standard,
      borderRadius: BorderRadius.circular(borderRadius),
      blur: 24.0,
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: SizedBox(
        height: height - 12.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

/// Reusable Liquid Glass Slider widget
class LiquidGlassSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final String? valueDisplay;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color? activeColor;
  final VoidCallback? onReset;

  const LiquidGlassSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    this.valueDisplay,
    required this.onChanged,
    this.onChangeEnd,
    this.activeColor,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? AeviqueTheme.primaryBlue;
    final isNonZero = value.abs() > 0.001;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onReset,
                child: Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AeviqueTheme.textSecondary,
                      ),
                    ),
                    if (isNonZero && onReset != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: effectiveColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                valueDisplay ??
                    (value > 0
                        ? '+${value.toStringAsFixed(0)}'
                        : value.toStringAsFixed(0)),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isNonZero ? effectiveColor : AeviqueTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.5,
            activeTrackColor: effectiveColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            overlayColor: effectiveColor.withValues(alpha: 0.22),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7.5,
              elevation: 4.0,
            ),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}

/// Liquid Glass Dialog
class LiquidGlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;

  const LiquidGlassDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.maxWidth = 420.0,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 32.0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LiquidGlassPanel(
          variant: LiquidGlassVariant.modal,
          borderRadius: BorderRadius.circular(AeviqueTheme.radiusXl),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              content,
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
