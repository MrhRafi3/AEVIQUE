import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_ui_components.dart';

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // B&W Switch and Reset Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Switch(
                    value: effects.bwMode,
                    activeThumbColor: LumaTheme.primaryBlueLight,
                    activeTrackColor: LumaTheme.primaryBlueSurface,
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.white12,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      onEffectsChanged(effects.copyWith(bwMode: val));
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'B&W Monochrome',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: effects.bwMode
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: effects.bwMode
                          ? Colors.white
                          : LumaTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onEffectsChanged(const EffectsAdjustments());
                  onVignetteChanged(const VignetteAdjustments());
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: LumaTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              LumaPrecisionSlider(
                label: 'Vignette Amount',
                value: vignette.amount,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onVignetteChanged(vignette.copyWith(amount: v)),
                onReset: () =>
                    onVignetteChanged(vignette.copyWith(amount: 0.0)),
              ),
              LumaPrecisionSlider(
                label: 'Film Grain',
                value: effects.grain,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(grain: v)),
                onReset: () => onEffectsChanged(effects.copyWith(grain: 0.0)),
              ),
              LumaPrecisionSlider(
                label: 'Highlight Bloom',
                value: effects.bloom,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(bloom: v)),
                onReset: () => onEffectsChanged(effects.copyWith(bloom: 0.0)),
              ),
              LumaPrecisionSlider(
                label: 'Diffusion Glow',
                value: effects.glow,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(glow: v)),
                onReset: () => onEffectsChanged(effects.copyWith(glow: 0.0)),
              ),
              LumaPrecisionSlider(
                label: 'Chromatic Aberration',
                value: effects.chromaticAberration,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onEffectsChanged(effects.copyWith(chromaticAberration: v)),
                onReset: () => onEffectsChanged(
                  effects.copyWith(chromaticAberration: 0.0),
                ),
              ),
              LumaPrecisionSlider(
                label: 'Lens Blur / Bokeh',
                value: effects.lensBlur,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onEffectsChanged(effects.copyWith(lensBlur: v)),
                onReset: () =>
                    onEffectsChanged(effects.copyWith(lensBlur: 0.0)),
              ),
              LumaPrecisionSlider(
                label: 'Vintage Film',
                value: effects.vintage,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onEffectsChanged(effects.copyWith(vintage: v)),
                onReset: () =>
                    onEffectsChanged(effects.copyWith(vintage: 0.0)),
              ),
              LumaPrecisionSlider(
                label: 'Dramatic Contrast',
                value: effects.drama,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onEffectsChanged(effects.copyWith(drama: v)),
                onReset: () =>
                    onEffectsChanged(effects.copyWith(drama: 0.0)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
