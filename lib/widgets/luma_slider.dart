import 'package:flutter/material.dart';
import '../theme/luma_theme.dart';

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

  String get formattedValue {
    final rounded = value.round();
    if (min < 0 && rounded > 0) {
      return '+$rounded$unit';
    }
    return '$rounded$unit';
  }

  @override
  Widget build(BuildContext context) {
    final isNonZero = value.abs() > 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onDoubleTap: () => onReset != null ? onReset!() : onChanged(0.0),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isNonZero ? FontWeight.w600 : FontWeight.w500,
                        color: isNonZero ? LumaTheme.textPrimary : LumaTheme.textSecondary,
                      ),
                    ),
                    if (isNonZero) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: LumaTheme.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onReset != null ? onReset!() : onChanged(0.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isNonZero
                        ? LumaTheme.accent.withValues(alpha: 0.15)
                        : LumaTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isNonZero
                          ? LumaTheme.accent.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    formattedValue,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isNonZero ? LumaTheme.accent : LumaTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Stack(
            alignment: Alignment.center,
            children: [
              // Center zero detent tick when range spans negative and positive
              if (min < 0 && max > 0)
                Positioned(
                  child: Container(
                    width: 2,
                    height: 10,
                    decoration: BoxDecoration(
                      color: LumaTheme.borderLight,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
