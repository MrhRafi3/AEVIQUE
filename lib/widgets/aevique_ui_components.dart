import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/aevique_theme.dart';
import 'aevique_glass.dart';

/// Prominent Reference Floating Action Button (Warm Golden Sun Bloom)
///
/// Derived directly from Phone 3 checkmark FAB and Phone 1 "+" FAB.
class AeviqueAmberFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;

  const AeviqueAmberFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 56.0,
    this.iconSize = 28.0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFDF7A),
            Color(0xFFE5A125),
            Color(0xFFB87810),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A125).withValues(alpha: 0.55),
            blurRadius: 28,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
            child: Icon(
              icon,
              size: iconSize,
              color: const Color(0xFF09090C),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reference Glass Capsule Pill (Categories, Modes, Tags)
///
/// Used in Phone 1 ("Vintage", "Reel") and Phone 3 (`[Crop]`, `[Adjust]`, `[Filter]`).
class AeviquePillChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const AeviquePillChip({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return AeviqueGlass(
      borderRadius: BorderRadius.circular(AeviqueTheme.radiusFull),
      showAmberAccent: isSelected,
      padding: EdgeInsets.zero,
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
                color: isSelected ? AeviqueTheme.accentAmberLight : AeviqueTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AeviqueTheme.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Island / Dock Navigation Capsule
///
/// Derived from Phone 1 bottom dock and Phone 3 contextual dock.
class AeviqueFloatingDock extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const AeviqueFloatingDock({
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
      child: AeviqueGlass(
        borderRadius: BorderRadius.circular(AeviqueTheme.radiusFull),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: children,
        ),
      ),
    );
  }
}

/// Reference Angle Rotation Ruler with Floating Badge (Phone 3)
class AeviqueRulerSlider extends StatefulWidget {
  final double value; // in degrees, e.g. -45 to +45
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;

  const AeviqueRulerSlider({
    super.key,
    required this.value,
    this.min = -45.0,
    this.max = 45.0,
    required this.onChanged,
    this.onReset,
  });

  @override
  State<AeviqueRulerSlider> createState() => _AeviqueRulerSliderState();
}

class _AeviqueRulerSliderState extends State<AeviqueRulerSlider> {
  double _dragStartValue = 0.0;
  double _dragStartX = 0.0;

  @override
  Widget build(BuildContext context) {
    final displayDegrees = widget.value.round();
    final badgeText = '${displayDegrees > 0 ? '+' : ''}$displayDegrees°';

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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x66181822),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.value != 0 ? AeviqueTheme.accentAmber : AeviqueTheme.border,
                width: widget.value != 0 ? 1.0 : 0.6,
              ),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.value != 0 ? AeviqueTheme.accentAmberLight : AeviqueTheme.textSecondary,
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
            final newValue = (_dragStartValue - delta * 0.4).clamp(widget.min, widget.max);
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
      ..color = AeviqueTheme.accentAmber
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

/// Reference Rotary Dial Knob with Perimeter Ticks (Phone 5)
class AeviqueCircularDial extends StatefulWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final double size;

  const AeviqueCircularDial({
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
  State<AeviqueCircularDial> createState() => _AeviqueCircularDialState();
}

class _AeviqueCircularDialState extends State<AeviqueCircularDial> {
  double _currentAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _currentAngle = _valueToAngle(widget.value);
  }

  @override
  void didUpdateWidget(covariant AeviqueCircularDial oldWidget) {
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
    return (widget.min + norm * (widget.max - widget.min)).clamp(widget.min, widget.max);
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
            final angle = math.atan2(touchPoint.dy - center.dy, touchPoint.dx - center.dx);
            final clamped = angle.clamp(-0.75 * math.pi, 0.75 * math.pi);
            setState(() => _currentAngle = clamped);
            widget.onChanged(_angleToValue(clamped));
          },
          onDoubleTap: () {
            HapticFeedback.lightImpact();
            widget.onChanged(0.0);
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x66181822),
              border: Border.all(
                color: isModified ? AeviqueTheme.accentAmber : AeviqueTheme.border,
                width: isModified ? 1.2 : 0.8,
              ),
              boxShadow: [
                if (isModified)
                  BoxShadow(
                    color: AeviqueTheme.accentAmber.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
              ],
            ),
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
                  color: isModified ? AeviqueTheme.accentAmberLight : AeviqueTheme.textSecondary,
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
            color: isModified ? Colors.white : AeviqueTheme.textMuted,
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
      ..color = AeviqueTheme.accentAmber
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

/// Reference Glass Action Row (Phone 2)
class AeviqueGlassActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const AeviqueGlassActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AeviqueGlass(
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
                      color: AeviqueTheme.textMuted,
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
                color: AeviqueTheme.textMuted,
              ),
        ],
      ),
    );
  }
}

/// Reference Precision Slider with Amber Glowing Thumb & Numeric Value
class AeviquePrecisionSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;
  final String Function(double)? valueFormatter;

  const AeviquePrecisionSlider({
    super.key,
    required this.label,
    required this.value,
    this.min = -100.0,
    this.max = 100.0,
    required this.onChanged,
    this.onReset,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: isModified ? Colors.white : AeviqueTheme.textSecondary,
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
                    color: isModified ? AeviqueTheme.accentAmberLight : AeviqueTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AeviqueTheme.accentAmber,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              thumbColor: AeviqueTheme.accentAmberLight,
              overlayColor: AeviqueTheme.accentAmber.withValues(alpha: 0.25),
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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

/// Backward-compatible adjustment slider wrapping [AeviquePrecisionSlider].
class AeviqueSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final VoidCallback? onReset;
  final String unit;

  const AeviqueSlider({
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
    return AeviquePrecisionSlider(
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

/// Reference Glass Action Button
class AeviqueButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const AeviqueButton({
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

  const AeviqueButton.secondary({
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
    Color bg;
    Color fg;
    Color border;

    if (isDestructive) {
      bg = const Color(0xFFEF4444).withValues(alpha: 0.15);
      fg = const Color(0xFFEF4444);
      border = const Color(0xFFEF4444).withValues(alpha: 0.4);
    } else if (isPrimary) {
      bg = AeviqueTheme.accentAmber;
      fg = const Color(0xFF09090C);
      border = Colors.transparent;
    } else {
      bg = const Color(0x66181824);
      fg = Colors.white;
      border = AeviqueTheme.border;
    }

    return SizedBox(
      width: width,
      height: height,
      child: AeviqueGlass(
        borderRadius: BorderRadius.circular(AeviqueTheme.radiusFull),
        backgroundColor: bg,
        borderColor: border,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        onTap: isLoading ? null : onPressed,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: fg),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: fg,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
