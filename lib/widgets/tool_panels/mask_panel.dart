import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/mask_model.dart';
import '../../core/models/hsl_adjustments.dart';
import '../../theme/luma_theme.dart';
import '../luma_ui_components.dart';

/// Professional Selective Masking tool panel supporting Brush, Subject Auto-Selection,
/// Linear, and Radial masks with comprehensive Light, Color, 8-channel HSL, and Effects adjustments.
class MaskPanel extends StatefulWidget {
  final List<SelectiveMask> masks;
  final bool showMaskOverlay;
  final int? activeMaskIndex;
  final ValueChanged<List<SelectiveMask>> onMasksChanged;
  final ValueChanged<bool> onOverlayToggled;
  final ValueChanged<int?> onActiveMaskChanged;

  // Brush controls
  final double brushSize;
  final double brushHardness;
  final double brushOpacity;
  final bool isEraseMode;
  final ValueChanged<double> onBrushSizeChanged;
  final ValueChanged<double> onBrushHardnessChanged;
  final ValueChanged<double> onBrushOpacityChanged;
  final ValueChanged<bool> onEraseModeChanged;
  final VoidCallback onUndoStroke;
  final bool canUndoStroke;

  // Subject selection
  final VoidCallback onSelectSubject;
  final bool isSegmentingSubject;

  const MaskPanel({
    super.key,
    required this.masks,
    required this.showMaskOverlay,
    this.activeMaskIndex,
    required this.onMasksChanged,
    required this.onOverlayToggled,
    required this.onActiveMaskChanged,
    this.brushSize = 35.0,
    this.brushHardness = 0.7,
    this.brushOpacity = 1.0,
    this.isEraseMode = false,
    required this.onBrushSizeChanged,
    required this.onBrushHardnessChanged,
    required this.onBrushOpacityChanged,
    required this.onEraseModeChanged,
    required this.onUndoStroke,
    this.canUndoStroke = false,
    required this.onSelectSubject,
    this.isSegmentingSubject = false,
  });

  @override
  State<MaskPanel> createState() => _MaskPanelState();
}

class _MaskPanelState extends State<MaskPanel> {
  late int _selectedMaskIndex;
  String _activeAdjustmentTab = 'Light'; // 'Light', 'Color', 'HSL', 'Effects'
  HslColorBand _selectedHslBand = HslColorBand.red;
  bool _showBrushSliders = false;

  @override
  void initState() {
    super.initState();
    _selectedMaskIndex = widget.activeMaskIndex ?? 0;
    if (widget.masks.isNotEmpty && widget.activeMaskIndex == null) {
      widget.onActiveMaskChanged(0);
    }
  }

  @override
  void didUpdateWidget(covariant MaskPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeMaskIndex != null) {
      _selectedMaskIndex = widget.activeMaskIndex!;
    }
    if (widget.masks.isNotEmpty && _selectedMaskIndex >= widget.masks.length) {
      _selectedMaskIndex = widget.masks.length - 1;
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
      case MaskType.subject:
        name = 'Subject Mask $count';
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
      density: 1.0,
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
    final newIdx = updated.isEmpty ? 0 : (_selectedMaskIndex.clamp(0, updated.length - 1));
    setState(() {
      _selectedMaskIndex = newIdx;
    });
    widget.onMasksChanged(updated);
    widget.onActiveMaskChanged(updated.isEmpty ? null : newIdx);
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
        // 1. Top Action Bar: Select Subject, Add Mask, Rubylith Overlay
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Select Subject Button
                ElevatedButton.icon(
                  onPressed: widget.isSegmentingSubject ? null : widget.onSelectSubject,
                  icon: widget.isSegmentingSubject
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_search_rounded, size: 16),
                  label: Text(
                    widget.isSegmentingSubject ? 'Detecting...' : 'Select Subject',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LumaTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 8),

                // Add Mask Dropdown Menu
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LumaTheme.border, width: 0.8),
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
                const SizedBox(width: 12),

                // Rubylith Overlay Switch
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
        ),

        // 2. Mask Layer Tabs
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
                    case MaskType.subject:
                      icon = Icons.person_rounded;
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
                            const SizedBox(width: 6),
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
                'No masks created yet. Tap "Select Subject" or "Add Mask" to begin.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          ),

        // 3. Active Mask Controls
        if (activeMask != null) ...[
          // Brush & Tool Strip (for Brush and Subject masks)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Paint / Erase Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x331E1E2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LumaTheme.border, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniModePill(
                          label: 'Paint',
                          icon: Icons.brush_rounded,
                          active: !widget.isEraseMode,
                          onTap: () => widget.onEraseModeChanged(false),
                        ),
                        _buildMiniModePill(
                          label: 'Erase',
                          icon: Icons.auto_fix_normal_rounded,
                          active: widget.isEraseMode,
                          onTap: () => widget.onEraseModeChanged(true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Brush Settings Expand Toggle
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _showBrushSliders ? Icons.tune_rounded : Icons.brush_outlined,
                      size: 18,
                      color: _showBrushSliders ? LumaTheme.primaryBlueLight : Colors.white70,
                    ),
                    tooltip: 'Brush Settings',
                    onPressed: () => setState(() => _showBrushSliders = !_showBrushSliders),
                  ),

                  // Undo Stroke Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    tooltip: 'Undo Stroke',
                    color: widget.canUndoStroke ? Colors.white : Colors.white24,
                    onPressed: widget.canUndoStroke ? widget.onUndoStroke : null,
                  ),

                  const SizedBox(width: 8),

                  // Invert Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      activeMask.inverted ? Icons.invert_colors_rounded : Icons.invert_colors_off_rounded,
                      size: 18,
                      color: activeMask.inverted ? LumaTheme.creativeOrange : Colors.white60,
                    ),
                    tooltip: 'Invert Mask',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _updateActiveMask(activeMask.copyWith(inverted: !activeMask.inverted));
                    },
                  ),

                  // Clear Mask
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: LumaTheme.coralRedLight),
                    tooltip: 'Clear Mask Data',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _updateActiveMask(
                        activeMask.copyWith(
                          maskBytes: null,
                          brushPoints: const [],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Brush Settings (Size, Hardness, Opacity)
          if (_showBrushSliders)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x331E1E2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LumaTheme.border, width: 0.8),
                ),
                child: Column(
                  children: [
                    LumaPrecisionSlider(
                      label: 'Brush Size',
                      value: widget.brushSize,
                      min: 5.0,
                      max: 120.0,
                      onChanged: widget.onBrushSizeChanged,
                      onReset: () => widget.onBrushSizeChanged(35.0),
                    ),
                    LumaPrecisionSlider(
                      label: 'Brush Hardness',
                      value: widget.brushHardness * 100.0,
                      min: 0.0,
                      max: 100.0,
                      onChanged: (v) => widget.onBrushHardnessChanged(v / 100.0),
                      onReset: () => widget.onBrushHardnessChanged(0.7),
                    ),
                    LumaPrecisionSlider(
                      label: 'Brush Flow / Opacity',
                      value: widget.brushOpacity * 100.0,
                      min: 5.0,
                      max: 100.0,
                      onChanged: (v) => widget.onBrushOpacityChanged(v / 100.0),
                      onReset: () => widget.onBrushOpacityChanged(1.0),
                    ),
                  ],
                ),
              ),
            ),

          // Mask Refinement Section (Density, Feather, Overall Opacity)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              children: [
                LumaPrecisionSlider(
                  label: 'Mask Density',
                  value: activeMask.density * 100.0,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (v) => _updateActiveMask(activeMask.copyWith(density: v / 100.0)),
                  onReset: () => _updateActiveMask(activeMask.copyWith(density: 1.0)),
                ),
                LumaPrecisionSlider(
                  label: 'Mask Opacity',
                  value: activeMask.opacity * 100.0,
                  min: 0.0,
                  max: 100.0,
                  onChanged: (v) => _updateActiveMask(activeMask.copyWith(opacity: v / 100.0)),
                  onReset: () => _updateActiveMask(activeMask.copyWith(opacity: 1.0)),
                ),
              ],
            ),
          ),

          const Divider(color: LumaTheme.border, height: 16),

          // 4. Local Adjustments Category Selector Tabs (Light, Color, HSL, Effects)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Light', 'Color', 'HSL', 'Effects'].map((tab) {
                  final isSelected = _activeAdjustmentTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _activeAdjustmentTab = tab);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? LumaTheme.primaryBlue : Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? LumaTheme.primaryBlueLight : LumaTheme.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Adjustment Sliders based on selected tab
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: _buildAdjustmentTabContent(activeMask),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniModePill({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? LumaTheme.primaryBlue.withValues(alpha: 0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? LumaTheme.primaryBlueLight : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentTabContent(SelectiveMask activeMask) {
    final tone = activeMask.adjustments;

    switch (_activeAdjustmentTab) {
      case 'Light':
        return Column(
          children: [
            LumaPrecisionSlider(
              label: 'Exposure',
              value: tone.exposure,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(exposure: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(exposure: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Brightness',
              value: tone.brightness,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(brightness: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(brightness: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Contrast',
              value: tone.contrast,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(contrast: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(contrast: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Highlights',
              value: tone.highlights,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(highlights: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(highlights: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Shadows',
              value: tone.shadows,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(shadows: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(shadows: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Whites',
              value: tone.whites,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(whites: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(whites: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Blacks',
              value: tone.blacks,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(blacks: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(blacks: 0.0)),
              ),
            ),
          ],
        );

      case 'Color':
        return Column(
          children: [
            LumaPrecisionSlider(
              label: 'Warmth / Temp',
              value: tone.warmth,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(warmth: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(warmth: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Tint',
              value: tone.tint,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(tint: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(tint: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Saturation',
              value: tone.saturation,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(saturation: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(saturation: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Vibrance',
              value: tone.vibrance,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(vibrance: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(vibrance: 0.0)),
              ),
            ),
          ],
        );

      case 'HSL':
        final currentBandAdj = _getHslChannel(tone.hsl, _selectedHslBand);
        return Column(
          children: [
            // Color band selector chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HslColorBand.values.map((band) {
                  final isSelected = _selectedHslBand == band;
                  final bandColor = _getBandSwatch(band);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedHslBand = band);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? bandColor.withValues(alpha: 0.35) : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? bandColor : LumaTheme.border,
                            width: isSelected ? 1.5 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: bandColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              band.displayName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Sliders for selected band
            LumaPrecisionSlider(
              label: '${_selectedHslBand.displayName} Hue',
              value: currentBandAdj.hue,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateHslBand(activeMask, currentBandAdj.copyWith(hue: v)),
              onReset: () => _updateHslBand(activeMask, currentBandAdj.copyWith(hue: 0.0)),
            ),
            LumaPrecisionSlider(
              label: '${_selectedHslBand.displayName} Saturation',
              value: currentBandAdj.saturation,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateHslBand(activeMask, currentBandAdj.copyWith(saturation: v)),
              onReset: () => _updateHslBand(activeMask, currentBandAdj.copyWith(saturation: 0.0)),
            ),
            LumaPrecisionSlider(
              label: '${_selectedHslBand.displayName} Luminance',
              value: currentBandAdj.luminance,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateHslBand(activeMask, currentBandAdj.copyWith(luminance: v)),
              onReset: () => _updateHslBand(activeMask, currentBandAdj.copyWith(luminance: 0.0)),
            ),
          ],
        );

      case 'Effects':
        return Column(
          children: [
            LumaPrecisionSlider(
              label: 'Clarity',
              value: tone.clarity,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(clarity: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(clarity: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Texture',
              value: tone.texture,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(texture: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(texture: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Dehaze',
              value: tone.dehaze,
              min: -100.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(dehaze: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(dehaze: 0.0)),
              ),
            ),
            LumaPrecisionSlider(
              label: 'Sharpness',
              value: tone.sharpness,
              min: 0.0,
              max: 100.0,
              onChanged: (v) => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(sharpness: v)),
              ),
              onReset: () => _updateActiveMask(
                activeMask.copyWith(adjustments: tone.copyWith(sharpness: 0.0)),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  HslChannelAdjustment _getHslChannel(HslAdjustments hsl, HslColorBand band) {
    switch (band) {
      case HslColorBand.red:
        return hsl.red;
      case HslColorBand.orange:
        return hsl.orange;
      case HslColorBand.yellow:
        return hsl.yellow;
      case HslColorBand.green:
        return hsl.green;
      case HslColorBand.aqua:
        return hsl.aqua;
      case HslColorBand.blue:
        return hsl.blue;
      case HslColorBand.purple:
        return hsl.purple;
      case HslColorBand.magenta:
        return hsl.magenta;
    }
  }

  void _updateHslBand(SelectiveMask activeMask, HslChannelAdjustment updatedBand) {
    final hsl = activeMask.adjustments.hsl;
    HslAdjustments newHsl;
    switch (_selectedHslBand) {
      case HslColorBand.red:
        newHsl = hsl.copyWith(red: updatedBand);
        break;
      case HslColorBand.orange:
        newHsl = hsl.copyWith(orange: updatedBand);
        break;
      case HslColorBand.yellow:
        newHsl = hsl.copyWith(yellow: updatedBand);
        break;
      case HslColorBand.green:
        newHsl = hsl.copyWith(green: updatedBand);
        break;
      case HslColorBand.aqua:
        newHsl = hsl.copyWith(aqua: updatedBand);
        break;
      case HslColorBand.blue:
        newHsl = hsl.copyWith(blue: updatedBand);
        break;
      case HslColorBand.purple:
        newHsl = hsl.copyWith(purple: updatedBand);
        break;
      case HslColorBand.magenta:
        newHsl = hsl.copyWith(magenta: updatedBand);
        break;
    }

    _updateActiveMask(
      activeMask.copyWith(
        adjustments: activeMask.adjustments.copyWith(hsl: newHsl),
      ),
    );
  }

  Color _getBandSwatch(HslColorBand band) {
    switch (band) {
      case HslColorBand.red:
        return const Color(0xFFE53935);
      case HslColorBand.orange:
        return const Color(0xFFFB8C00);
      case HslColorBand.yellow:
        return const Color(0xFFFDD835);
      case HslColorBand.green:
        return const Color(0xFF43A047);
      case HslColorBand.aqua:
        return const Color(0xFF00ACC1);
      case HslColorBand.blue:
        return const Color(0xFF1E88E5);
      case HslColorBand.purple:
        return const Color(0xFF8E24AA);
      case HslColorBand.magenta:
        return const Color(0xFFD81B60);
    }
  }
}
