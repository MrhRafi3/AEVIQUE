import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/edit_state.dart';
import '../../theme/aevique_theme.dart';
import '../aevique_ui_components.dart';
import '../curve_editor_widget.dart';

enum TuneMode { all, light, color, detail }

class TunePanel extends StatefulWidget {
  final TuneAdjustments tune;
  final ValueChanged<TuneAdjustments> onChanged;
  final ToneCurves? curves;
  final ValueChanged<ToneCurves>? onCurvesChanged;
  final TuneMode mode;

  const TunePanel({
    super.key,
    required this.tune,
    required this.onChanged,
    this.curves,
    this.onCurvesChanged,
    this.mode = TuneMode.all,
  });

  @override
  State<TunePanel> createState() => _TunePanelState();
}

class _TunePanelState extends State<TunePanel> {
  double _grainValue = 0.0;

  void _applyAutoTune() {
    HapticFeedback.lightImpact();
    widget.onChanged(
      widget.tune.copyWith(
        exposure: 6.0,
        contrast: 14.0,
        vibrance: 16.0,
        highlights: -10.0,
        shadows: 12.0,
        warmth: 4.0,
        clarity: 8.0,
      ),
    );
  }

  void _resetTune() {
    HapticFeedback.lightImpact();
    widget.onChanged(const TuneAdjustments());
    setState(() => _grainValue = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Row of Circular Rotary Dials with Perimeter Ticks (Phone 5)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AeviqueCircularDial(
                label: 'Exposure',
                icon: Icons.wb_sunny_outlined,
                value: widget.tune.exposure,
                min: -100,
                max: 100,
                onChanged: (v) =>
                    widget.onChanged(widget.tune.copyWith(exposure: v)),
              ),
              AeviqueCircularDial(
                label: 'Contrast',
                icon: Icons.contrast_rounded,
                value: widget.tune.contrast,
                min: -100,
                max: 100,
                onChanged: (v) =>
                    widget.onChanged(widget.tune.copyWith(contrast: v)),
              ),
              AeviqueCircularDial(
                label: 'Grain',
                icon: Icons.grain_rounded,
                value: _grainValue,
                min: 0,
                max: 100,
                onChanged: (v) => setState(() => _grainValue = v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Side-by-Side: Precision Sliders (Left) & Tone Curve Box (Right) (Phone 5)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Sliders
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 180,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      AeviquePrecisionSlider(
                        label: 'Brightness',
                        value: widget.tune.brightness,
                        onChanged: (v) => widget.onChanged(
                          widget.tune.copyWith(brightness: v),
                        ),
                        onReset: () => widget.onChanged(
                          widget.tune.copyWith(brightness: 0.0),
                        ),
                      ),
                      AeviquePrecisionSlider(
                        label: 'Contrast',
                        value: widget.tune.contrast,
                        onChanged: (v) =>
                            widget.onChanged(widget.tune.copyWith(contrast: v)),
                        onReset: () => widget.onChanged(
                          widget.tune.copyWith(contrast: 0.0),
                        ),
                      ),
                      AeviquePrecisionSlider(
                        label: 'Saturation',
                        value: widget.tune.saturation,
                        onChanged: (v) => widget.onChanged(
                          widget.tune.copyWith(saturation: v),
                        ),
                        onReset: () => widget.onChanged(
                          widget.tune.copyWith(saturation: 0.0),
                        ),
                      ),
                      AeviquePrecisionSlider(
                        label: 'Warmth',
                        value: widget.tune.warmth,
                        onChanged: (v) =>
                            widget.onChanged(widget.tune.copyWith(warmth: v)),
                        onReset: () =>
                            widget.onChanged(widget.tune.copyWith(warmth: 0.0)),
                      ),
                      AeviquePrecisionSlider(
                        label: 'Highlights',
                        value: widget.tune.highlights,
                        onChanged: (v) => widget.onChanged(
                          widget.tune.copyWith(highlights: v),
                        ),
                        onReset: () => widget.onChanged(
                          widget.tune.copyWith(highlights: 0.0),
                        ),
                      ),
                      AeviquePrecisionSlider(
                        label: 'Shadows',
                        value: widget.tune.shadows,
                        onChanged: (v) =>
                            widget.onChanged(widget.tune.copyWith(shadows: v)),
                        onReset: () => widget.onChanged(
                          widget.tune.copyWith(shadows: 0.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Right Column: Tone Curve Box (Phone 5)
              if (widget.curves != null && widget.onCurvesChanged != null)
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CurveEditorWidget(
                    curves: widget.curves!,
                    onCurvesChanged: widget.onCurvesChanged!,
                    compactMode: true,
                  ),
                ),
            ],
          ),
        ),

        // Quick Auto & Reset bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _applyAutoTune,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AeviqueTheme.primaryBlueLight,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Auto',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: _resetTune,
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AeviqueTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
