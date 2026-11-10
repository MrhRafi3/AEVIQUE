import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/edit_state.dart';
import '../../theme/luma_theme.dart';
import '../luma_glass.dart';
import '../luma_ui_components.dart';

enum PortraitSubTool { smooth, brighten, blemish }

class PortraitPanel extends StatefulWidget {
  final PortraitAdjustments portrait;
  final ValueChanged<PortraitAdjustments> onChanged;
  final bool isBlemishModeActive;
  final ValueChanged<bool> onBlemishModeChanged;
  final double blemishRadius;
  final ValueChanged<double> onBlemishRadiusChanged;
  final VoidCallback onUndoLastBlemish;
  final VoidCallback onClearBlemishes;

  const PortraitPanel({
    super.key,
    required this.portrait,
    required this.onChanged,
    required this.isBlemishModeActive,
    required this.onBlemishModeChanged,
    required this.blemishRadius,
    required this.onBlemishRadiusChanged,
    required this.onUndoLastBlemish,
    required this.onClearBlemishes,
  });

  @override
  State<PortraitPanel> createState() => _PortraitPanelState();
}

class _PortraitPanelState extends State<PortraitPanel> {
  PortraitSubTool _activeSubTool = PortraitSubTool.smooth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-tool switcher chips (Smooth, Tone, Blemish)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              _buildSubToolTab(
                subTool: PortraitSubTool.smooth,
                label: 'Smooth',
                icon: Icons.auto_fix_high_rounded,
                isActive: widget.portrait.skinSmooth > 0,
              ),
              const SizedBox(width: 8),
              _buildSubToolTab(
                subTool: PortraitSubTool.brighten,
                label: 'Skin Glow',
                icon: Icons.wb_sunny_outlined,
                isActive: widget.portrait.skinBrighten.abs() > 0,
              ),
              const SizedBox(width: 8),
              _buildSubToolTab(
                subTool: PortraitSubTool.blemish,
                label: 'Blemish',
                icon: Icons.healing_rounded,
                isActive:
                    widget.portrait.blemishes.isNotEmpty ||
                    widget.isBlemishModeActive,
              ),
            ],
          ),
        ),

        // Active tool controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: _buildActiveControls(),
        ),
      ],
    );
  }

  Widget _buildSubToolTab({
    required PortraitSubTool subTool,
    required String label,
    required IconData icon,
    required bool isActive,
  }) {
    final isSelected = _activeSubTool == subTool;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeSubTool = subTool);
          if (subTool == PortraitSubTool.blemish) {
            widget.onBlemishModeChanged(true);
          } else {
            widget.onBlemishModeChanged(false);
          }
        },
        child: LumaGlass(
          borderRadius: BorderRadius.circular(14),
          showAmberAccent: isSelected,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? LumaTheme.primaryBlueLight
                    : (isActive ? Colors.white : LumaTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : LumaTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveControls() {
    switch (_activeSubTool) {
      case PortraitSubTool.smooth:
        return Column(
          children: [
            LumaPrecisionSlider(
              label: 'Skin Smoothing',
              value: widget.portrait.skinSmooth,
              min: 0.0,
              max: 100.0,
              onChanged: (val) {
                widget.onChanged(widget.portrait.copyWith(skinSmooth: val));
              },
              onReset: () =>
                  widget.onChanged(widget.portrait.copyWith(skinSmooth: 0.0)),
            ),
          ],
        );

      case PortraitSubTool.brighten:
        return Column(
          children: [
            LumaPrecisionSlider(
              label: 'Skin Tone Glow',
              value: widget.portrait.skinBrighten,
              min: -50.0,
              max: 50.0,
              onChanged: (val) {
                widget.onChanged(widget.portrait.copyWith(skinBrighten: val));
              },
              onReset: () =>
                  widget.onChanged(widget.portrait.copyWith(skinBrighten: 0.0)),
            ),
          ],
        );

      case PortraitSubTool.blemish:
        return Column(
          children: [
            LumaPrecisionSlider(
              label: 'Heal Brush Radius',
              value: widget.blemishRadius * 1000.0,
              min: 10.0,
              max: 60.0,
              onChanged: (val) => widget.onBlemishRadiusChanged(val / 1000.0),
              onReset: () => widget.onBlemishRadiusChanged(0.025),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: widget.onUndoLastBlemish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.undo, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Undo Spot',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: widget.onClearBlemishes,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.clear_all, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Clear All',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}
