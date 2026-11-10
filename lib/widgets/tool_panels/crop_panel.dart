import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_glass.dart';
import '../luma_ui_components.dart';

class CropPanel extends StatefulWidget {
  final GeometryAdjustments geometry;
  final ValueChanged<GeometryAdjustments> onChanged;
  final double? imageAspectRatio;
  final ValueChanged<double?>? onAspectRatioChanged;

  const CropPanel({
    super.key,
    required this.geometry,
    required this.onChanged,
    this.imageAspectRatio,
    this.onAspectRatioChanged,
  });

  @override
  State<CropPanel> createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  late double _angleDegrees;
  String _selectedRatio = 'Free';

  @override
  void initState() {
    super.initState();
    _angleDegrees = widget.geometry.rotationAngle;
  }

  @override
  void didUpdateWidget(covariant CropPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.geometry.rotationAngle - _angleDegrees).abs() > 0.01 &&
        (widget.geometry.rotationAngle - oldWidget.geometry.rotationAngle).abs() > 0.01) {
      _angleDegrees = widget.geometry.rotationAngle;
    }
  }

  void _updateAngle(double val) {
    final clamped = val.clamp(-45.0, 45.0);
    setState(() => _angleDegrees = clamped);
    widget.onChanged(widget.geometry.copyWith(rotationAngle: clamped));
  }

  void _nudgeAngle(double delta) {
    HapticFeedback.selectionClick();
    _updateAngle(_angleDegrees + delta);
  }

  void _resetRotation() {
    HapticFeedback.lightImpact();
    _updateAngle(0.0);
  }

  void _rotateClockwise() {
    HapticFeedback.lightImpact();
    widget.onChanged(
      widget.geometry.copyWith(
        rotationQuarterTurns: (widget.geometry.rotationQuarterTurns + 1) % 4,
      ),
    );
  }

  void _flipH() {
    HapticFeedback.selectionClick();
    widget.onChanged(
      widget.geometry.copyWith(flipHorizontal: !widget.geometry.flipHorizontal),
    );
  }

  void _flipV() {
    HapticFeedback.selectionClick();
    widget.onChanged(
      widget.geometry.copyWith(flipVertical: !widget.geometry.flipVertical),
    );
  }

  void _resetCrop() {
    HapticFeedback.lightImpact();
    setState(() => _selectedRatio = 'Free');
    widget.onAspectRatioChanged?.call(null);
    widget.onChanged(
      widget.geometry.copyWith(
        cropLeft: 0.0,
        cropTop: 0.0,
        cropRight: 1.0,
        cropBottom: 1.0,
      ),
    );
  }

  void _setAspectRatio(String name, double? targetRatio) {
    HapticFeedback.selectionClick();
    setState(() => _selectedRatio = name);
    widget.onAspectRatioChanged?.call(targetRatio);

    if (targetRatio == null) {
      widget.onChanged(
        widget.geometry.copyWith(
          cropLeft: 0.0,
          cropTop: 0.0,
          cropRight: 1.0,
          cropBottom: 1.0,
        ),
      );
      return;
    }

    final imgAspect = (widget.imageAspectRatio != null && widget.imageAspectRatio! > 0)
        ? widget.imageAspectRatio!
        : 1.0;

    // Calculate crop rectangle in normalized [0..1] coordinates
    // (cropW * imgW) / (cropH * imgH) = targetRatio
    // cropW / cropH = targetRatio / imgAspect
    final rNorm = targetRatio / imgAspect;

    if (rNorm >= 1.0) {
      // Crop height is smaller than crop width
      final h = (1.0 / rNorm).clamp(0.1, 1.0);
      final t = (1.0 - h) / 2.0;
      widget.onChanged(
        widget.geometry.copyWith(
          cropLeft: 0.0,
          cropRight: 1.0,
          cropTop: t,
          cropBottom: t + h,
        ),
      );
    } else {
      // Crop width is smaller than crop height
      final w = rNorm.clamp(0.1, 1.0);
      final l = (1.0 - w) / 2.0;
      widget.onChanged(
        widget.geometry.copyWith(
          cropLeft: l,
          cropRight: l + w,
          cropTop: 0.0,
          cropBottom: 1.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalAspect = widget.imageAspectRatio ?? 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Angle Ruler with Live Numeric Degree Badge & Reset
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.straighten_rounded, size: 16, color: LumaTheme.primaryBlueLight),
                      const SizedBox(width: 6),
                      Text(
                        'Straighten',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LumaTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Nudge -1°
                      _buildNudgeBtn('-1°', () => _nudgeAngle(-1.0)),
                      const SizedBox(width: 4),
                      // Degree Badge
                      GestureDetector(
                        onTap: _resetRotation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _angleDegrees.abs() > 0.01
                                ? LumaTheme.primaryBlue.withValues(alpha: 0.25)
                                : const Color(0x401E1E26),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _angleDegrees.abs() > 0.01
                                  ? LumaTheme.primaryBlueLight
                                  : LumaTheme.border,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${_angleDegrees >= 0 ? '+' : ''}${_angleDegrees.toStringAsFixed(1)}°',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _angleDegrees.abs() > 0.01 ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Nudge +1°
                      _buildNudgeBtn('+1°', () => _nudgeAngle(1.0)),
                      const SizedBox(width: 6),
                      if (_angleDegrees.abs() > 0.01)
                        GestureDetector(
                          onTap: _resetRotation,
                          child: const Icon(Icons.refresh_rounded, size: 16, color: LumaTheme.coralRedLight),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LumaRulerSlider(
                value: _angleDegrees,
                min: -45.0,
                max: 45.0,
                onChanged: _updateAngle,
                onReset: _resetRotation,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Aspect Ratio Selector Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildRatioChip('Free', null),
              const SizedBox(width: 8),
              _buildRatioChip('Original', originalAspect),
              const SizedBox(width: 8),
              _buildRatioChip('1:1', 1.0),
              const SizedBox(width: 8),
              _buildRatioChip('4:3', 4.0 / 3.0),
              const SizedBox(width: 8),
              _buildRatioChip('3:2', 3.0 / 2.0),
              const SizedBox(width: 8),
              _buildRatioChip('16:9', 16.0 / 9.0),
              const SizedBox(width: 8),
              _buildRatioChip('Story (9:16)', 9.0 / 16.0),
              const SizedBox(width: 8),
              _buildRatioChip('Post (4:5)', 4.0 / 5.0),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 3. Quick Action Buttons: Rotate 90°, Flip H, Flip V, Reset Crop
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionGlassBtn(
                icon: Icons.rotate_90_degrees_cw_outlined,
                label: 'Rotate 90°',
                onTap: _rotateClockwise,
              ),
              _buildActionGlassBtn(
                icon: Icons.flip_outlined,
                label: 'Flip H',
                isActive: widget.geometry.flipHorizontal,
                onTap: _flipH,
              ),
              _buildActionGlassBtn(
                icon: Icons.swap_vert_outlined,
                label: 'Flip V',
                isActive: widget.geometry.flipVertical,
                onTap: _flipV,
              ),
              if (widget.geometry.hasCrop)
                _buildActionGlassBtn(
                  icon: Icons.crop_free_rounded,
                  label: 'Reset Crop',
                  onTap: _resetCrop,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNudgeBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x301E1E26),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: LumaTheme.border, width: 0.6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRatioChip(String name, double? ratio) {
    final isSelected = _selectedRatio == name;
    return LumaPillChip(
      label: name,
      isSelected: isSelected,
      onTap: () => _setAspectRatio(name, ratio),
    );
  }

  Widget _buildActionGlassBtn({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return LumaGlass(
      borderRadius: BorderRadius.circular(12),
      showAmberAccent: isActive,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isActive ? LumaTheme.primaryBlueLight : Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : LumaTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
