import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/edit_state.dart';
import '../../theme/aevique_theme.dart';
import '../aevique_ui_components.dart';

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
                    activeThumbColor: AeviqueTheme.primaryBlueLight,
                    activeTrackColor: AeviqueTheme.primaryBlueSurface,
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
                          : AeviqueTheme.textSecondary,
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
                    color: AeviqueTheme.textMuted,
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
              AeviquePrecisionSlider(
                label: 'Vignette Amount',
                value: vignette.amount,
                min: 0.0,
                max: 100.0,
                onChanged: (v) =>
                    onVignetteChanged(vignette.copyWith(amount: v)),
                onReset: () =>
                    onVignetteChanged(vignette.copyWith(amount: 0.0)),
              ),
              AeviquePrecisionSlider(
                label: 'Film Grain',
                value: effects.grain,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(grain: v)),
                onReset: () => onEffectsChanged(effects.copyWith(grain: 0.0)),
              ),
              AeviquePrecisionSlider(
                label: 'Highlight Bloom',
                value: effects.bloom,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => onEffectsChanged(effects.copyWith(bloom: v)),
                onReset: () => onEffectsChanged(effects.copyWith(bloom: 0.0)),
              ),
              AeviquePrecisionSlider(
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
            ],
          ),
        ),
      ],
    );
  }
}
