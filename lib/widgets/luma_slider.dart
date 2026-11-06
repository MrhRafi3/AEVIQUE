import 'package:flutter/material.dart';
import 'aevique_ui_components.dart';

/// Backward-compatible adjustment slider wrapping [AeviqueSlider].
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
    return AeviqueSlider(
      title: title,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      onReset: onReset,
      unit: unit,
    );
  }
}
