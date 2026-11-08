import 'package:flutter/material.dart';
import '../../core/models/hsl_adjustments.dart';
import '../../theme/aevique_theme.dart';
import '../aevique_ui_components.dart';

/// Professional 8-channel HSL Color Mixer panel with Liquid Glass styling.
class HslPanel extends StatefulWidget {
  final HslAdjustments adjustments;
  final ValueChanged<HslAdjustments> onChanged;

  const HslPanel({
    super.key,
    required this.adjustments,
    required this.onChanged,
  });

  @override
  State<HslPanel> createState() => _HslPanelState();
}

class _HslPanelState extends State<HslPanel> {
  HslColorBand _activeBand = HslColorBand.red;
  late HslAdjustments _adjustments;

  @override
  void initState() {
    super.initState();
    _adjustments = widget.adjustments;
  }

  @override
  void didUpdateWidget(covariant HslPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adjustments != oldWidget.adjustments) {
      _adjustments = widget.adjustments;
    }
  }

  Color _getBandColor(HslColorBand band) {
    switch (band) {
      case HslColorBand.red:
        return const Color(0xFFEF4444);
      case HslColorBand.orange:
        return const Color(0xFFF97316);
      case HslColorBand.yellow:
        return const Color(0xFFEAB308);
      case HslColorBand.green:
        return const Color(0xFF22C55E);
      case HslColorBand.aqua:
        return const Color(0xFF06B6D4);
      case HslColorBand.blue:
        return const Color(0xFF3B82F6);
      case HslColorBand.purple:
        return const Color(0xFF8B5CF6);
      case HslColorBand.magenta:
        return const Color(0xFFEC4899);
    }
  }

  void _onBandChanged({double? hue, double? saturation, double? luminance}) {
    final updated = _adjustments.updateBand(
      _activeBand,
      hue: hue,
      saturation: saturation,
      luminance: luminance,
    );
    setState(() {
      _adjustments = updated;
    });
    widget.onChanged(updated);
  }

  void _resetActiveBand() {
    final updated = _adjustments.updateBand(
      _activeBand,
      hue: 0.0,
      saturation: 0.0,
      luminance: 0.0,
    );
    setState(() {
      _adjustments = updated;
    });
    widget.onChanged(updated);
  }

  void _resetAllBands() {
    const updated = HslAdjustments();
    setState(() {
      _adjustments = updated;
    });
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final currentAdj = _adjustments.getBand(_activeBand);
    final bandColor = _getBandColor(_activeBand);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Color Band Selector Swatches
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HslColorBand.values.map((band) {
                final isSelected = band == _activeBand;
                final color = _getBandColor(band);
                final hasEdits = !_adjustments.getBand(band).isIdentity;

                return GestureDetector(
                  onTap: () {
                    setState(() => _activeBand = band);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (hasEdits ? color.withValues(alpha: 0.8) : Colors.transparent),
                        width: isSelected ? 2.2 : (hasEdits ? 1.5 : 0.0),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: const Color(0x33FFFFFF),
                          width: 1,
                        ),
                      ),
                      child: hasEdits && !isSelected
                          ? Center(
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Active Band Title & Reset Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bandColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_activeBand.displayName} Channel',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (!currentAdj.isIdentity)
                    GestureDetector(
                      onTap: _resetActiveBand,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Reset ${_activeBand.displayName}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AeviqueTheme.primaryBlueLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (!_adjustments.isIdentity) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _resetAllBands,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Reset All',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AeviqueTheme.coralRedLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 3 Sliders: Hue, Saturation, Luminance
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              AeviquePrecisionSlider(
                label: 'Hue',
                value: currentAdj.hue,
                min: -100,
                max: 100,
                onChanged: (val) => _onBandChanged(hue: val),
                onReset: () => _onBandChanged(hue: 0.0),
                activeColor: bandColor,
              ),
              AeviquePrecisionSlider(
                label: 'Saturation',
                value: currentAdj.saturation,
                min: -100,
                max: 100,
                onChanged: (val) => _onBandChanged(saturation: val),
                onReset: () => _onBandChanged(saturation: 0.0),
                activeColor: bandColor,
              ),
              AeviquePrecisionSlider(
                label: 'Luminance',
                value: currentAdj.luminance,
                min: -100,
                max: 100,
                onChanged: (val) => _onBandChanged(luminance: val),
                onReset: () => _onBandChanged(luminance: 0.0),
                activeColor: bandColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
