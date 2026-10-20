import 'package:flutter/material.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_slider.dart';

class TunePanel extends StatelessWidget {
  final TuneAdjustments tune;
  final ValueChanged<TuneAdjustments> onChanged;

  const TunePanel({super.key, required this.tune, required this.onChanged});

  void _applyAutoTune() {
    onChanged(
      tune.copyWith(
        exposure: 5.0,
        contrast: 12.0,
        vibrance: 18.0,
        highlights: -12.0,
        shadows: 14.0,
        warmth: 4.0,
        clarity: 8.0,
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
                onPressed: _applyAutoTune,
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
          height: 230,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              LumaSlider(
                title: 'Exposure',
                value: tune.exposure,
                onChanged: (v) => onChanged(tune.copyWith(exposure: v)),
              ),
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
                title: 'Whites',
                value: tune.whites,
                onChanged: (v) => onChanged(tune.copyWith(whites: v)),
              ),
              LumaSlider(
                title: 'Blacks',
                value: tune.blacks,
                onChanged: (v) => onChanged(tune.copyWith(blacks: v)),
              ),
              LumaSlider(
                title: 'Vibrance',
                value: tune.vibrance,
                onChanged: (v) => onChanged(tune.copyWith(vibrance: v)),
              ),
              LumaSlider(
                title: 'Saturation',
                value: tune.saturation,
                onChanged: (v) => onChanged(tune.copyWith(saturation: v)),
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
              LumaSlider(
                title: 'Clarity',
                value: tune.clarity,
                onChanged: (v) => onChanged(tune.copyWith(clarity: v)),
              ),
              LumaSlider(
                title: 'Ambiance',
                value: tune.ambiance,
                onChanged: (v) => onChanged(tune.copyWith(ambiance: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
