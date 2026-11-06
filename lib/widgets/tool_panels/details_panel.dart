import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/edit_state.dart';
import '../../theme/aevique_theme.dart';
import '../aevique_ui_components.dart';

class DetailsPanel extends StatelessWidget {
  final DetailsAdjustments details;
  final ValueChanged<DetailsAdjustments> onChanged;

  const DetailsPanel({
    super.key,
    required this.details,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChanged(const DetailsAdjustments());
                },
                child: const Text(
                  'Reset Details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AeviqueTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          AeviquePrecisionSlider(
            label: 'Sharpening',
            value: details.sharpening,
            min: 0.0,
            max: 100.0,
            onChanged: (v) => onChanged(details.copyWith(sharpening: v)),
            onReset: () => onChanged(details.copyWith(sharpening: 0.0)),
          ),
          AeviquePrecisionSlider(
            label: 'Structure',
            value: details.structure,
            min: 0.0,
            max: 100.0,
            onChanged: (v) => onChanged(details.copyWith(structure: v)),
            onReset: () => onChanged(details.copyWith(structure: 0.0)),
          ),
        ],
      ),
    );
  }
}
