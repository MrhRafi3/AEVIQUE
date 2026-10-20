import 'package:flutter/material.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_slider.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: LumaTheme.textMuted,
                ),
                label: const Text(
                  'Reset Details',
                  style: TextStyle(color: LumaTheme.textMuted, fontSize: 12),
                ),
                onPressed: () => onChanged(const DetailsAdjustments()),
              ),
            ],
          ),
        ),
        LumaSlider(
          title: 'Sharpening',
          value: details.sharpening,
          min: 0.0,
          max: 100.0,
          onChanged: (v) => onChanged(details.copyWith(sharpening: v)),
        ),
        LumaSlider(
          title: 'Structure',
          value: details.structure,
          min: 0.0,
          max: 100.0,
          onChanged: (v) => onChanged(details.copyWith(structure: v)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
