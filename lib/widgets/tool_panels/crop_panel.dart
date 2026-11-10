import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_glass.dart';
import '../luma_ui_components.dart';

class CropPanel extends StatefulWidget {
  final GeometryAdjustments geometry;
  final ValueChanged<GeometryAdjustments> onChanged;

  const CropPanel({super.key, required this.geometry, required this.onChanged});

  @override
  State<CropPanel> createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  double _angleDegrees = 0.0;
  String _selectedRatio = 'Free';

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

  void _setAspectRatio(String name, double? ratio) {
    HapticFeedback.selectionClick();
    setState(() => _selectedRatio = name);

    if (ratio == null) {
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

    if (ratio >= 1.0) {
      final h = 1.0 / ratio;
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
      final w = ratio;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Angle Ruler with Floating Degree Badge (Phone 3)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LumaRulerSlider(
            value: _angleDegrees,
            min: -45.0,
            max: 45.0,
            onChanged: (val) {
              setState(() => _angleDegrees = val);
              // Map continuous angle or micro-rotations
            },
            onReset: () {
              setState(() => _angleDegrees = 0.0);
            },
          ),
        ),

        const SizedBox(height: 12),

        // 2. Aspect Ratio Selector Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildRatioChip('Free', null),
              const SizedBox(width: 8),
              _buildRatioChip('1:1', 1.0),
              const SizedBox(width: 8),
              _buildRatioChip('Story (9:16)', 9.0 / 16.0),
              const SizedBox(width: 8),
              _buildRatioChip('Post (4:5)', 4.0 / 5.0),
              const SizedBox(width: 8),
              _buildRatioChip('16:9', 16.0 / 9.0),
              const SizedBox(width: 8),
              _buildRatioChip('3:2', 3.0 / 2.0),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Rotate & Flip Quick Actions
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
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? LumaTheme.primaryBlueLight : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.white : LumaTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
