import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/presets/preset_catalogue.dart';
import '../../services/preset_repository.dart';
import '../../theme/aevique_theme.dart';
import '../aevique_glass.dart';

/// Professional Presets panel with Built-in and Custom user presets tabs and Save action.
class PresetsPanel extends StatefulWidget {
  final String? activePresetName;
  final ValueChanged<PresetItem> onPresetSelected;
  final ValueChanged<CustomPreset>? onCustomPresetSelected;
  final VoidCallback onClearPreset;
  final VoidCallback? onSaveCurrentAsPreset;

  const PresetsPanel({
    super.key,
    required this.activePresetName,
    required this.onPresetSelected,
    this.onCustomPresetSelected,
    required this.onClearPreset,
    this.onSaveCurrentAsPreset,
  });

  @override
  State<PresetsPanel> createState() => _PresetsPanelState();
}

class _PresetsPanelState extends State<PresetsPanel> {
  int _selectedTab = 0; // 0 = Built-in, 1 = Custom
  List<CustomPreset> _customPresets = [];

  @override
  void initState() {
    super.initState();
    _loadCustomPresets();
  }

  Future<void> _loadCustomPresets() async {
    final list = await PresetRepository.getCustomPresets();
    if (mounted) {
      setState(() => _customPresets = list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final builtInPresets = PresetCatalogue.presets;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs Header: Built-in | Custom | Save As Preset
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? AeviqueTheme.primaryBlue.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTab == 0
                              ? AeviqueTheme.primaryBlueLight
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Built-in',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.w400,
                          color: _selectedTab == 0 ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTab = 1);
                      _loadCustomPresets();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? AeviqueTheme.primaryBlue.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTab == 1
                              ? AeviqueTheme.primaryBlueLight
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'My Presets (${_customPresets.length})',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.w400,
                          color: _selectedTab == 1 ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (widget.onSaveCurrentAsPreset != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onSaveCurrentAsPreset!();
                        _loadCustomPresets();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AeviqueTheme.creativeOrangeSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AeviqueTheme.creativeOrange, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bookmark_add_outlined, size: 13, color: AeviqueTheme.creativeOrange),
                            SizedBox(width: 4),
                            Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AeviqueTheme.creativeOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.activePresetName != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onClearPreset();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AeviqueTheme.coralRedLight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Carousel of Presets
        SizedBox(
          height: 105,
          child: _selectedTab == 0
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: builtInPresets.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final preset = builtInPresets[index];
                    final isSelected = widget.activePresetName == preset.name;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onPresetSelected(preset);
                      },
                      child: SizedBox(
                        width: 110,
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
                )
              : (_customPresets.isEmpty
                  ? Center(
                      child: Text(
                        'No custom presets yet. Tap "Save" to save your edits.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: _customPresets.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final custom = _customPresets[index];
                        final isSelected = widget.activePresetName == custom.name;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onCustomPresetSelected?.call(custom);
                          },
                          child: SizedBox(
                            width: 115,
                            child: AeviqueGlass(
                              borderRadius: BorderRadius.circular(16),
                              showAmberAccent: isSelected,
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          custom.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? Colors.white : AeviqueTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          await PresetRepository.deletePreset(custom.id);
                                          _loadCustomPresets();
                                        },
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 13,
                                          color: AeviqueTheme.coralRedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    custom.description,
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
                    )),
        ),
      ],
    );
  }
}
