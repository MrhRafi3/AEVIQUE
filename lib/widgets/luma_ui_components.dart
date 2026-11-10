import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/luma_theme.dart';
import 'luma_glass.dart';

/// Floating Action Button with luminous Liquid Glass gradient.
class LumaFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool isSecondary;

  const LumaFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 56.0,
    this.iconSize = 28.0,
    this.tooltip,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final startColor = isSecondary
        ? const Color(0xFFFFA663)
        : const Color(0xFF5E98FC);
    final midColor = isSecondary
        ? LumaTheme.creativeOrange
        : LumaTheme.primaryBlue;
    final endColor = isSecondary
        ? const Color(0xFFDF6B15)
        : const Color(0xFF1E5AD6);
    final glowColor = isSecondary
        ? LumaTheme.creativeOrangeGlow
        : LumaTheme.primaryBlueGlow;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, midColor, endColor],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed?.call();
          },
          child: Center(
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Liquid Glass Capsule Pill (Categories, Modes, Tags)
class LumaPillChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final bool useOrangeAccent;

  const LumaPillChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.padding,
    this.useOrangeAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return LiquidGlassPanel(
      variant: isSelected
          ? (useOrangeAccent
                ? LiquidGlassVariant.accentOrange
                : LiquidGlassVariant.accentBlue)
          : LiquidGlassVariant.ultraClear,
      borderRadius: BorderRadius.circular(LumaTheme.radiusFull),
      blur: 20.0,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: effectivePadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (useOrangeAccent
                          ? LumaTheme.creativeOrangeLight
                          : LumaTheme.primaryBlueLight)
                    : LumaTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : LumaTheme.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Island / Dock Navigation Capsule in Liquid Glass
class LumaFloatingDock extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const LumaFloatingDock({
    super.key,
    required this.children,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 24),
      child: LiquidGlassPanel(
        variant: LiquidGlassVariant.elevated,
        borderRadius: BorderRadius.circular(LumaTheme.radiusFull),
        blur: 28.0,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: children,
        ),
      ),
    );
  }
}

/// Liquid Glass Angle Rotation Ruler with Floating Badge
class LumaRulerSlider extends StatefulWidget {
  final double value; // in degrees, e.g. -45 to +45
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;

  const LumaRulerSlider({
    super.key,
    required this.value,
    this.min = -45.0,
    this.max = 45.0,
    required this.onChanged,
    this.onReset,
  });

  @override
  State<LumaRulerSlider> createState() => _LumaRulerSliderState();
}

class _LumaRulerSliderState extends State<LumaRulerSlider> {
  double _dragStartValue = 0.0;
  double _dragStartX = 0.0;

  @override
  Widget build(BuildContext context) {
    final displayDegrees = widget.value.round();
    final badgeText = '${displayDegrees > 0 ? '+' : ''}$displayDegrees°';
    final isModified = widget.value != 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Degree Badge
        GestureDetector(
          onDoubleTap: () {
            HapticFeedback.lightImpact();
            if (widget.onReset != null) {
              widget.onReset!();
            } else {
              widget.onChanged(0.0);
            }
          },
          child: LiquidGlassPanel(
            variant: isModified
                ? LiquidGlassVariant.accentOrange
                : LiquidGlassVariant.ultraClear,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isModified ? Colors.white : LumaTheme.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal Ruler Ticks
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            _dragStartX = details.localPosition.dx;
            _dragStartValue = widget.value;
          },
          onHorizontalDragUpdate: (details) {
            final delta = details.localPosition.dx - _dragStartX;
            final newValue = (_dragStartValue - delta * 0.4).clamp(
              widget.min,
              widget.max,
            );
            widget.onChanged(newValue);
          },
          child: SizedBox(
            height: 32,
            width: double.infinity,
            child: CustomPaint(
              painter: _RulerPainter(
                value: widget.value,
                min: widget.min,
                max: widget.max,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  _RulerPainter({required this.value, required this.min, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    const tickSpacing = 8.0;
    final totalDegrees = (size.width / tickSpacing).ceil();

    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final centerPaint = Paint()
      ..color = LumaTheme.creativeOrange
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int deg = -totalDegrees; deg <= totalDegrees; deg++) {
      final x = centerX + (deg - value) * tickSpacing;
      if (x < 0 || x > size.width) continue;

      final isMajor = deg % 5 == 0;
      final tickHeight = isMajor ? 16.0 : 8.0;
      final topY = (size.height - tickHeight) / 2;

      canvas.drawLine(
        Offset(x, topY),
        Offset(x, topY + tickHeight),
        deg == 0 ? centerPaint : tickPaint,
      );
    }

    canvas.drawLine(
      Offset(centerX, 4),
      Offset(centerX, size.height - 4),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.value != value;
}

/// Rotary Dial Knob with Perimeter Ticks and Liquid Glass Aesthetics
class LumaCircularDial extends StatefulWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final double size;

  const LumaCircularDial({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.min = -100.0,
    this.max = 100.0,
    required this.onChanged,
    this.size = 64.0,
  });

  @override
  State<LumaCircularDial> createState() => _LumaCircularDialState();
}

class _LumaCircularDialState extends State<LumaCircularDial> {
  double _currentAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _currentAngle = _valueToAngle(widget.value);
  }

  @override
  void didUpdateWidget(covariant LumaCircularDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentAngle = _valueToAngle(widget.value);
    }
  }

  double _valueToAngle(double val) {
    final norm = (val - widget.min) / (widget.max - widget.min);
    return (norm - 0.5) * 1.5 * math.pi;
  }

  double _angleToValue(double angle) {
    final norm = (angle / (1.5 * math.pi)) + 0.5;
    return (widget.min + norm * (widget.max - widget.min)).clamp(
      widget.min,
      widget.max,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isModified = widget.value.abs() > 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            final center = Offset(widget.size / 2, widget.size / 2);
            final touchPoint = details.localPosition;
            final angle = math.atan2(
              touchPoint.dy - center.dy,
              touchPoint.dx - center.dx,
            );
            final clamped = angle.clamp(-0.75 * math.pi, 0.75 * math.pi);
            setState(() => _currentAngle = clamped);
            widget.onChanged(_angleToValue(clamped));
          },
          onDoubleTap: () {
            HapticFeedback.lightImpact();
            widget.onChanged(0.0);
          },
          child: LiquidGlassPanel(
            variant: isModified
                ? LiquidGlassVariant.accentBlue
                : LiquidGlassVariant.standard,
            borderRadius: BorderRadius.circular(widget.size / 2),
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _DialTicksPainter(
                    angle: _currentAngle,
                    isModified: isModified,
                  ),
                ),
                Icon(
                  widget.icon,
                  size: widget.size * 0.38,
                  color: isModified ? Colors.white : LumaTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isModified ? FontWeight.w600 : FontWeight.w500,
            color: isModified ? Colors.white : LumaTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DialTicksPainter extends CustomPainter {
  final double angle;
  final bool isModified;

  _DialTicksPainter({required this.angle, required this.isModified});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const tickCount = 20;

    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (int i = 0; i < tickCount; i++) {
      final tickAngle = -0.75 * math.pi + (i / (tickCount - 1)) * 1.5 * math.pi;
      final start = Offset(
        center.dx + (radius - 5) * math.cos(tickAngle),
        center.dy + (radius - 5) * math.sin(tickAngle),
      );
      final end = Offset(
        center.dx + (radius - 2) * math.cos(tickAngle),
        center.dy + (radius - 2) * math.sin(tickAngle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    final thumbIndicator = Paint()
      ..color = LumaTheme.primaryBlueLight
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final startActive = Offset(
      center.dx + (radius - 7) * math.cos(angle),
      center.dy + (radius - 7) * math.sin(angle),
    );
    final endActive = Offset(
      center.dx + (radius - 2) * math.cos(angle),
      center.dy + (radius - 2) * math.sin(angle),
    );
    canvas.drawLine(startActive, endActive, thumbIndicator);
  }

  @override
  bool shouldRepaint(covariant _DialTicksPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.isModified != isModified;
}

/// Precision Slider with Blue/Orange Glowing Thumb & Numeric Value
class LumaPrecisionSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;
  final String Function(double)? valueFormatter;
  final Color? activeColor;

  const LumaPrecisionSlider({
    super.key,
    required this.label,
    required this.value,
    this.min = -100.0,
    this.max = 100.0,
    required this.onChanged,
    this.onReset,
    this.valueFormatter,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = activeColor ?? LumaTheme.primaryBlue;
    final isModified = value.abs() > 0.5;
    final formattedValue = valueFormatter != null
        ? valueFormatter!(value)
        : '${value > 0 ? '+' : ''}${value.round()}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: isModified ? FontWeight.w600 : FontWeight.w500,
                    color: isModified
                        ? Colors.white
                        : LumaTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onDoubleTap: () {
                  HapticFeedback.lightImpact();
                  if (onReset != null) {
                    onReset!();
                  } else {
                    onChanged(0.0);
                  }
                },
                child: Text(
                  formattedValue,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isModified
                        ? LumaTheme.primaryBlueLight
                        : LumaTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: effectiveColor,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: Colors.white,
              overlayColor: effectiveColor.withValues(alpha: 0.25),
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Backward-compatible adjustment slider wrapping [LumaPrecisionSlider].
class LumaSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final VoidCallback? onReset;
  final String unit;

  const LumaSlider({
    super.key,
    required this.title,
    required this.value,
    this.min = -100.0,
    this.max = 100.0,
    required this.onChanged,
    this.onChangeEnd,
    this.onReset,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    return LumaPrecisionSlider(
      label: title,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      onReset: onReset,
      valueFormatter: (v) {
        final rounded = v.round();
        if (min < 0 && rounded > 0) {
          return '+$rounded$unit';
        }
        return '$rounded$unit';
      },
    );
  }
}

/// Liquid Glass Action Button
class LumaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const LumaButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.isLoading = false,
    this.width,
    this.height = 46.0,
    this.padding,
  });

  const LumaButton.secondary({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isDestructive = false,
    this.isLoading = false,
    this.width,
    this.height = 46.0,
    this.padding,
  }) : isPrimary = false;

  @override
  Widget build(BuildContext context) {
    final variant = isDestructive
        ? LiquidGlassVariant.accentRed
        : (isPrimary
              ? LiquidGlassVariant.accentBlue
              : LiquidGlassVariant.standard);

    return LiquidGlassPanel(
      variant: variant,
      borderRadius: BorderRadius.circular(LumaTheme.radiusFull),
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      onTap: isLoading ? null : onPressed,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Liquid Glass Action Row
class LumaGlassActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const LumaGlassActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPanel(
      variant: LiquidGlassVariant.standard,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: LumaTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: LumaTheme.textMuted,
              ),
        ],
      ),
    );
  }
}
