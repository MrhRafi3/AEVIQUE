import 'package:flutter/material.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';

class CropPanel extends StatelessWidget {
  final GeometryAdjustments geometry;
  final ValueChanged<GeometryAdjustments> onChanged;

  const CropPanel({super.key, required this.geometry, required this.onChanged});

  void _rotateClockwise() {
    onChanged(
      geometry.copyWith(
        rotationQuarterTurns: (geometry.rotationQuarterTurns + 1) % 4,
      ),
    );
  }

  void _flipH() {
    onChanged(geometry.copyWith(flipHorizontal: !geometry.flipHorizontal));
  }

  void _flipV() {
    onChanged(geometry.copyWith(flipVertical: !geometry.flipVertical));
  }

  void _setAspectRatio(double? ratio) {
    if (ratio == null) {
      // Freeform or reset
      onChanged(
        geometry.copyWith(
          cropLeft: 0.0,
          cropTop: 0.0,
          cropRight: 1.0,
          cropBottom: 1.0,
        ),
      );
      return;
    }

    // Set centered aspect ratio box
    if (ratio >= 1.0) {
      // Wide ratio
      final h = 1.0 / ratio;
      final t = (1.0 - h) / 2.0;
      onChanged(
        geometry.copyWith(
          cropLeft: 0.0,
          cropRight: 1.0,
          cropTop: t,
          cropBottom: t + h,
        ),
      );
    } else {
      // Tall ratio
      final w = ratio;
      final l = (1.0 - w) / 2.0;
      onChanged(
        geometry.copyWith(
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
        // Rotation and Flip Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.rotate_90_degrees_cw_outlined,
                label: 'Rotate',
                onTap: _rotateClockwise,
              ),
              _buildActionButton(
                icon: Icons.flip_outlined,
                label: 'Flip H',
                isActive: geometry.flipHorizontal,
                onTap: _flipH,
              ),
              _buildActionButton(
                icon: Icons.swap_vert_outlined,
                label: 'Flip V',
                isActive: geometry.flipVertical,
                onTap: _flipV,
              ),
              _buildActionButton(
                icon: Icons.crop_free_outlined,
                label: 'Reset',
                onTap: () => _setAspectRatio(null),
              ),
            ],
          ),
        ),
        const Divider(color: LumaTheme.border),
        // Aspect Ratio Presets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRatioChip('Free', null),
                const SizedBox(width: 8),
                _buildRatioChip('1:1 Square', 1.0),
                const SizedBox(width: 8),
                _buildRatioChip('4:5 Portrait', 4.0 / 5.0),
                const SizedBox(width: 8),
                _buildRatioChip('16:9 Cinema', 16.0 / 9.0),
                const SizedBox(width: 8),
                _buildRatioChip('9:16 Story', 9.0 / 16.0),
                const SizedBox(width: 8),
                _buildRatioChip('3:2 Photo', 3.0 / 2.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? LumaTheme.accent : LumaTheme.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? LumaTheme.accent : LumaTheme.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioChip(String label, double? ratio) {
    return ActionChip(
      backgroundColor: LumaTheme.surfaceElevated,
      side: const BorderSide(color: LumaTheme.border),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: LumaTheme.textPrimary),
      ),
      onPressed: () => _setAspectRatio(ratio),
    );
  }
}
