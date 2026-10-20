import 'package:flutter/material.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_slider.dart';

class EffectsPanel extends StatelessWidget {
  final EffectsAdjustments effects;
  final VignetteAdjustments vignette;
  final ValueChanged<EffectsAdjustments> onEffectsChanged;
  final ValueChanged<VignetteAdjustments> onVignetteChanged;

  const EffectsPanel({
    super.key,
    required this.effects,
    required this.vignette,
    required this.onEffectsChanged,
    required this.onVignetteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // B&W Switch and Reset Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Switch(
                    value: effects.bwMode,
                    activeThumbColor: LumaTheme.accent,
                    onChanged: (val) =>
                        onEffectsChanged(effects.copyWith(bwMode: val)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'B&W Monochrome',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: effects.bwMode
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: effects.bwMode
                          ? LumaTheme.textPrimary
                          : LumaTheme.textSecondary,
                    ),
                  ),
                ],
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
                onPressed: () {
                  onEffectsChanged(const EffectsAdjustments());
                  onVignetteChanged(const VignetteAdjustments());
                },
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
                title: 'Film Grain',
                value: effects.grain,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(grain: v)),
              ),
              LumaSlider(
                title: 'Highlight Bloom',
                value: effects.bloom,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(bloom: v)),
              ),
              LumaSlider(
                title: 'Drama',
                value: effects.drama,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(drama: v)),
              ),
              LumaSlider(
                title: 'Vintage Fade',
                value: effects.vintage,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onEffectsChanged(effects.copyWith(vintage: v)),
              ),
              LumaSlider(
                title: 'Chromatic Aberration',
                value: effects.chromaticAberration,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onEffectsChanged(effects.copyWith(chromaticAberration: v)),
              ),
              const Divider(color: LumaTheme.border, indent: 16, endIndent: 16),
              LumaSlider(
                title: 'Vignette Outer',
                value: vignette.amount,
                min: -100.0,
                max: 100.0,
                onChanged: (v) =>
                    onVignetteChanged(vignette.copyWith(amount: v)),
              ),
              LumaSlider(
                title: 'Vignette Radius',
                value: vignette.radius,
                min: 10.0,
                max: 100.0,
                onChanged: (v) =>
                    onVignetteChanged(vignette.copyWith(radius: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
