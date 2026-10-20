import 'package:flutter/material.dart';
import '../../core/presets/preset_catalogue.dart';
import '../../theme/luma_theme.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original Cinematic Presets',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: LumaTheme.textSecondary,
                ),
              ),
              if (activePresetName != null)
                TextButton(
                  onPressed: onClearPreset,
                  child: const Text(
                    'Clear Preset',
                    style: TextStyle(color: LumaTheme.accent, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isSelected = activePresetName == preset.name;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () => onPresetSelected(preset),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? LumaTheme.accent.withValues(alpha: 0.15)
                          : LumaTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? LumaTheme.accent : LumaTheme.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? LumaTheme.accent
                                : LumaTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.filter_vintage_rounded,
                            size: 16,
                            color: isSelected
                                ? LumaTheme.background
                                : LumaTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          preset.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? LumaTheme.accent
                                : LumaTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          preset.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: LumaTheme.textMuted,
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
        const SizedBox(height: 12),
      ],
    );
  }
}
