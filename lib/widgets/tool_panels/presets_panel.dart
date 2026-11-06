import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/presets/preset_catalogue.dart';
import '../../theme/aevique_theme.dart';
import '../aevique_glass.dart';

class PresetsPanel extends StatelessWidget {
  final String? activePresetName;
  final ValueChanged<PresetItem> onPresetSelected;
  final VoidCallback onClearPreset;

  const PresetsPanel({
    super.key,
    required this.activePresetName,
    required this.onPresetSelected,
    required this.onClearPreset,
  });

  @override
  Widget build(BuildContext context) {
    final presets = PresetCatalogue.presets;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cinematic Presets',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AeviqueTheme.textSecondary,
                ),
              ),
              if (activePresetName != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClearPreset();
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AeviqueTheme.accentAmber,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            itemCount: presets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isSelected = activePresetName == preset.name;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPresetSelected(preset);
                },
                child: SizedBox(
                  width: 100,
                  child: AeviqueGlass(
                    borderRadius: BorderRadius.circular(16),
                    showAmberAccent: isSelected,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : AeviqueTheme.textSecondary,
                          ),
                        ),
                        Text(
                          preset.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AeviqueTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
