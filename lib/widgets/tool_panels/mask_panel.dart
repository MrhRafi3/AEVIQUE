import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/mask_model.dart';
import '../../theme/luma_theme.dart';
import '../luma_ui_components.dart';

/// Professional Selective Masking tool panel supporting Brush, Linear, and Radial masks.
class MaskPanel extends StatefulWidget {
  final List<SelectiveMask> masks;
  final bool showMaskOverlay;
  final ValueChanged<List<SelectiveMask>> onMasksChanged;
  final ValueChanged<bool> onOverlayToggled;
  final ValueChanged<int?> onActiveMaskChanged;

  const MaskPanel({
    super.key,
    required this.masks,
    required this.showMaskOverlay,
    required this.onMasksChanged,
    required this.onOverlayToggled,
    required this.onActiveMaskChanged,
  });

  @override
  State<MaskPanel> createState() => _MaskPanelState();
}

class _MaskPanelState extends State<MaskPanel> {
  int _selectedMaskIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.masks.isNotEmpty) {
      widget.onActiveMaskChanged(0);
    }
  }

  void _addNewMask(MaskType type) {
    HapticFeedback.lightImpact();
    final newId = 'mask_${DateTime.now().millisecondsSinceEpoch}';
    final count = widget.masks.length + 1;
    String name;
    switch (type) {
      case MaskType.brush:
        name = 'Brush Mask $count';
        break;
      case MaskType.linearGradient:
        name = 'Linear Gradient $count';
        break;
      case MaskType.radialGradient:
        name = 'Radial Mask $count';
        break;
    }

    final newMask = SelectiveMask(
      id: newId,
      name: name,
      type: type,
      opacity: 1.0,
      isVisible: true,
      adjustments: const MaskToneAdjustments(exposure: 15.0),
    );

    final updated = List<SelectiveMask>.from(widget.masks)..add(newMask);
    setState(() {
      _selectedMaskIndex = updated.length - 1;
    });
    widget.onMasksChanged(updated);
    widget.onActiveMaskChanged(_selectedMaskIndex);
  }

  void _deleteMask(int index) {
    HapticFeedback.lightImpact();
    final updated = List<SelectiveMask>.from(widget.masks)..removeAt(index);
    setState(() {
      _selectedMaskIndex = updated.isEmpty ? 0 : (_selectedMaskIndex.clamp(0, updated.length - 1));
    });
    widget.onMasksChanged(updated);
    widget.onActiveMaskChanged(updated.isEmpty ? null : _selectedMaskIndex);
  }

  void _updateActiveMask(SelectiveMask modified) {
    if (_selectedMaskIndex < 0 || _selectedMaskIndex >= widget.masks.length) return;
    final updated = List<SelectiveMask>.from(widget.masks);
    updated[_selectedMaskIndex] = modified;
    widget.onMasksChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hasMasks = widget.masks.isNotEmpty;
    final activeMask = hasMasks && _selectedMaskIndex < widget.masks.length
        ? widget.masks[_selectedMaskIndex]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Action Bar: Add Mask Dropdown & Overlay Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Add Mask Menu
              PopupMenuButton<MaskType>(
                tooltip: 'Add Mask',
                color: const Color(0xFF1E1E2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: LumaTheme.borderLight, width: 0.8),
                ),
                onSelected: _addNewMask,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: MaskType.brush,
                    child: Row(
                      children: [
                        Icon(Icons.brush_rounded, size: 18, color: LumaTheme.primaryBlueLight),
                        SizedBox(width: 10),
                        Text('Brush Mask', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: MaskType.linearGradient,
                    child: Row(
                      children: [
                        Icon(Icons.linear_scale_rounded, size: 18, color: LumaTheme.creativeOrangeLight),
                        SizedBox(width: 10),
                        Text('Linear Gradient Mask', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: MaskType.radialGradient,
                    child: Row(
                      children: [
                        Icon(Icons.radio_button_checked_rounded, size: 18, color: LumaTheme.coralRedLight),
                        SizedBox(width: 10),
                        Text('Radial Gradient Mask', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: LumaTheme.primaryBlue.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LumaTheme.primaryBlueLight, width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Add Mask',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Rubylith Mask Overlay Toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Rubylith Overlay',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: widget.showMaskOverlay,
                    activeThumbColor: LumaTheme.coralRedLight,
                    activeTrackColor: LumaTheme.coralRed.withValues(alpha: 0.35),
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.white12,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      widget.onOverlayToggled(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mask Layer Tabs (if masks exist)
        if (hasMasks)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.masks.length, (idx) {
                  final mask = widget.masks[idx];
                  final isSelected = idx == _selectedMaskIndex;
                  IconData icon;
                  switch (mask.type) {
                    case MaskType.brush:
                      icon = Icons.brush_rounded;
                      break;
                    case MaskType.linearGradient:
                      icon = Icons.linear_scale_rounded;
                      break;
                    case MaskType.radialGradient:
                      icon = Icons.radio_button_checked_rounded;
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMaskIndex = idx);
                        widget.onActiveMaskChanged(idx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? LumaTheme.primaryBlue.withValues(alpha: 0.3)
                              : const Color(0x331E1E2A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? LumaTheme.primaryBlueLight : LumaTheme.border,
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white60),
                            const SizedBox(width: 6),
                            Text(
                              mask.name,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _deleteMask(idx),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: LumaTheme.coralRedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'No masks created yet. Tap "Add Mask" to apply localized adjustments.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          ),

        // Active Mask Controls
        if (activeMask != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Invert Mask Toggle
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        activeMask.inverted ? Icons.invert_colors_rounded : Icons.invert_colors_off_rounded,
                        size: 20,
                        color: activeMask.inverted ? LumaTheme.creativeOrange : Colors.white60,
                      ),
                      tooltip: 'Invert Mask',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _updateActiveMask(activeMask.copyWith(inverted: !activeMask.inverted));
                      },
                    ),
                    Text(
                      activeMask.inverted ? 'Inverted' : 'Standard',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                // Clear Strokes (for Brush mask)
                if (activeMask.type == MaskType.brush && activeMask.brushPoints.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _updateActiveMask(activeMask.copyWith(brushPoints: const []));
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Clear Strokes',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: LumaTheme.coralRedLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Mask Opacity Slider
                LumaPrecisionSlider(
                  label: 'Mask Opacity',
                  value: activeMask.opacity * 100.0,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (v) => _updateActiveMask(activeMask.copyWith(opacity: v / 100.0)),
                  onReset: () => _updateActiveMask(activeMask.copyWith(opacity: 1.0)),
                ),

                // Local Adjustments inside Mask
                LumaPrecisionSlider(
                  label: 'Mask Exposure',
                  value: activeMask.adjustments.exposure,
                  min: -100.0,
                  max: 100.0,
                  onChanged: (v) => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(exposure: v),
                    ),
                  ),
                  onReset: () => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(exposure: 0.0),
                    ),
                  ),
                ),
                LumaPrecisionSlider(
                  label: 'Mask Contrast',
                  value: activeMask.adjustments.contrast,
                  min: -100.0,
                  max: 100.0,
                  onChanged: (v) => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(contrast: v),
                    ),
                  ),
                  onReset: () => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(contrast: 0.0),
                    ),
                  ),
                ),
                LumaPrecisionSlider(
                  label: 'Mask Saturation',
                  value: activeMask.adjustments.saturation,
                  min: -100.0,
                  max: 100.0,
                  onChanged: (v) => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(saturation: v),
                    ),
                  ),
                  onReset: () => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(saturation: 0.0),
                    ),
                  ),
                ),
                LumaPrecisionSlider(
                  label: 'Mask Warmth',
                  value: activeMask.adjustments.warmth,
                  min: -100.0,
                  max: 100.0,
                  onChanged: (v) => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(warmth: v),
                    ),
                  ),
                  onReset: () => _updateActiveMask(
                    activeMask.copyWith(
                      adjustments: activeMask.adjustments.copyWith(warmth: 0.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
