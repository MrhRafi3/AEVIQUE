import 'package:flutter/material.dart';
import '../../core/models/edit_state.dart';
import '../../theme/aevique_theme.dart';
import '../luma_slider.dart';

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
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              _buildSubToolTab(
                subTool: PortraitSubTool.smooth,
                label: 'Skin Smooth',
                icon: Icons.auto_fix_high_rounded,
                valueText: '${widget.portrait.skinSmooth.round()}',
                isActive: widget.portrait.skinSmooth > 0,
              ),
              const SizedBox(width: 8),
              _buildSubToolTab(
                subTool: PortraitSubTool.brighten,
                label: 'Skin Glow',
                icon: Icons.wb_sunny_outlined,
                valueText: '${widget.portrait.skinBrighten.round()}',
                isActive: widget.portrait.skinBrighten.abs() > 0,
              ),
              const SizedBox(width: 8),
              _buildSubToolTab(
                subTool: PortraitSubTool.blemish,
                label: 'Blemish Heal',
                icon: Icons.healing_rounded,
                valueText: widget.portrait.blemishes.isNotEmpty
                    ? '${widget.portrait.blemishes.length}'
                    : null,
                isActive:
                    widget.portrait.blemishes.isNotEmpty ||
                    widget.isBlemishModeActive,
              ),
            ],
          ),
        ),

        const Divider(color: AeviqueTheme.border, height: 1),

        // Active tool controls
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildActiveControls(),
        ),
      ],
    );
  }

  Widget _buildSubToolTab({
    required PortraitSubTool subTool,
    required String label,
    required IconData icon,
    String? valueText,
    required bool isActive,
  }) {
    final isSelected = _activeSubTool == subTool;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeSubTool = subTool);
          if (subTool == PortraitSubTool.blemish) {
            widget.onBlemishModeChanged(true);
          } else {
            widget.onBlemishModeChanged(false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AeviqueTheme.champagneGold.withValues(alpha: 0.16)
                : AeviqueTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AeviqueTheme.champagneGold
                  : (isActive
                        ? AeviqueTheme.champagneGold.withValues(alpha: 0.4)
                        : AeviqueTheme.border),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AeviqueTheme.champagneGold
                    : (isActive
                          ? AeviqueTheme.champagneGoldLight
                          : AeviqueTheme.slateGray),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AeviqueTheme.ivory
                      : AeviqueTheme.textSecondary,
                ),
              ),
              if (valueText != null) ...[
                const SizedBox(height: 2),
                Text(
                  valueText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AeviqueTheme.champagneGold
                        : AeviqueTheme.slateGray,
                  ),
                ),
              ],
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
            LumaSlider(
              title: 'Skin Smoothing',
              value: widget.portrait.skinSmooth,
              min: 0.0,
              max: 100.0,
              onReset: () =>
                  widget.onChanged(widget.portrait.copyWith(skinSmooth: 0.0)),
              unit: '',
              onChanged: (val) {
                widget.onChanged(widget.portrait.copyWith(skinSmooth: val));
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Preserves eyes, eyebrows, lips and hair with edge-guided bilateral filtering.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AeviqueTheme.slateGray,
                ),
              ),
            ),
          ],
        );

      case PortraitSubTool.brighten:
        return Column(
          children: [
            LumaSlider(
              title: 'Radiant Skin Tone Glow',
              value: widget.portrait.skinBrighten,
              min: -50.0,
              max: 50.0,
              onReset: () =>
                  widget.onChanged(widget.portrait.copyWith(skinBrighten: 0.0)),
              unit: '',
              onChanged: (val) {
                widget.onChanged(widget.portrait.copyWith(skinBrighten: val));
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Selectively brightens facial midtones without clipping or washing out shadows.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AeviqueTheme.slateGray,
                ),
              ),
            ),
          ],
        );

      case PortraitSubTool.blemish:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AeviqueTheme.champagneGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AeviqueTheme.champagneGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      color: AeviqueTheme.champagneGold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.portrait.blemishes.isEmpty
                            ? 'Tap on any blemish or pimple on the photo to heal it.'
                            : '${widget.portrait.blemishes.length} blemish spot(s) healed. Tap photo to heal more.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AeviqueTheme.ivory,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Spot size slider
              Row(
                children: [
                  const Text(
                    'Heal Radius',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AeviqueTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AeviqueTheme.champagneGold,
                        inactiveTrackColor: AeviqueTheme.border,
                        thumbColor: AeviqueTheme.champagneGold,
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                      ),
                      child: Slider(
                        value: widget.blemishRadius,
                        min: 0.015,
                        max: 0.06,
                        onChanged: widget.onBlemishRadiusChanged,
                      ),
                    ),
                  ),
                  Text(
                    '${(widget.blemishRadius * 1000).round()}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AeviqueTheme.champagneGold,
                    ),
                  ),
                ],
              ),
              if (widget.portrait.blemishes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: widget.onUndoLastBlemish,
                      icon: const Icon(Icons.undo_rounded, size: 16),
                      label: const Text(
                        'Undo Last Spot',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AeviqueTheme.champagneGold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: widget.onClearBlemishes,
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text(
                        'Clear All',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF5350),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
    }
  }
}
