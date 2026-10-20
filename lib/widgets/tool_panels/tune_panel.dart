import 'package:flutter/material.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_slider.dart';

class TunePanel extends StatelessWidget {
  final TuneAdjustments tune;
  final ValueChanged<TuneAdjustments> onChanged;

  const TunePanel({super.key, required this.tune, required this.onChanged});

  void _applyAutoTone() {
    onChanged(
      tune.copyWith(
        brightness: 8.0,
        contrast: 14.0,
        saturation: 12.0,
        ambiance: 15.0,
        highlights: -10.0,
        shadows: 12.0,
        warmth: 4.0,
      ),
    );
  }

  void _resetTune() {
    onChanged(const TuneAdjustments());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: LumaTheme.surfaceElevated,
                  side: const BorderSide(color: LumaTheme.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.auto_fix_high_rounded,
                  size: 14,
                  color: LumaTheme.accent,
                ),
                label: const Text(
                  'Auto Tune',
                  style: TextStyle(color: LumaTheme.textPrimary, fontSize: 12),
                ),
                onPressed: _applyAutoTone,
              ),
              TextButton.icon(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: LumaTheme.textMuted,
                ),
                label: const Text(
                  'Reset',
                  style: TextStyle(color: LumaTheme.textMuted, fontSize: 12),
                ),
                onPressed: _resetTune,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              LumaSlider(
                title: 'Brightness',
                value: tune.brightness,
                onChanged: (v) => onChanged(tune.copyWith(brightness: v)),
              ),
              LumaSlider(
                title: 'Contrast',
                value: tune.contrast,
                onChanged: (v) => onChanged(tune.copyWith(contrast: v)),
              ),
              LumaSlider(
                title: 'Saturation',
                value: tune.saturation,
                onChanged: (v) => onChanged(tune.copyWith(saturation: v)),
              ),
              LumaSlider(
                title: 'Ambiance',
                value: tune.ambiance,
                onChanged: (v) => onChanged(tune.copyWith(ambiance: v)),
              ),
              LumaSlider(
                title: 'Highlights',
                value: tune.highlights,
                onChanged: (v) => onChanged(tune.copyWith(highlights: v)),
              ),
              LumaSlider(
                title: 'Shadows',
                value: tune.shadows,
                onChanged: (v) => onChanged(tune.copyWith(shadows: v)),
              ),
              LumaSlider(
                title: 'Warmth',
                value: tune.warmth,
                onChanged: (v) => onChanged(tune.copyWith(warmth: v)),
              ),
              LumaSlider(
                title: 'Tint',
                value: tune.tint,
                onChanged: (v) => onChanged(tune.copyWith(tint: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
