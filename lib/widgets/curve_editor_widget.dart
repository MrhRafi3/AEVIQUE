import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/edit_state.dart';
import '../core/image_engine/lut_generator.dart';
import '../theme/luma_theme.dart';
import 'luma_glass.dart';

enum CurveChannel { rgb, red, green, blue }

class CurveEditorWidget extends StatefulWidget {
  final ToneCurves curves;
  final ValueChanged<ToneCurves> onCurvesChanged;
  final bool compactMode;

  const CurveEditorWidget({
    super.key,
    required this.curves,
    required this.onCurvesChanged,
    this.compactMode = false,
  });

  @override
  State<CurveEditorWidget> createState() => _CurveEditorWidgetState();
}

class _CurveEditorWidgetState extends State<CurveEditorWidget> {
  CurveChannel _selectedChannel = CurveChannel.rgb;
  int? _activePointIndex;

  List<CurvePoint> get _activePoints {
    switch (_selectedChannel) {
      case CurveChannel.rgb:
        return widget.curves.rgb;
      case CurveChannel.red:
        return widget.curves.red;
      case CurveChannel.green:
        return widget.curves.green;
      case CurveChannel.blue:
        return widget.curves.blue;
    }
  }

  Color get _activeColor {
    switch (_selectedChannel) {
      case CurveChannel.rgb:
        return LumaTheme.primaryBlueLight;
      case CurveChannel.red:
        return const Color(0xFFEF4444);
      case CurveChannel.green:
        return const Color(0xFF10B981);
      case CurveChannel.blue:
        return const Color(0xFF3B82F6);
    }
  }

  void _updateChannelPoints(List<CurvePoint> newPoints) {
    ToneCurves updated;
    switch (_selectedChannel) {
      case CurveChannel.rgb:
        updated = widget.curves.copyWith(rgb: newPoints);
        break;
      case CurveChannel.red:
        updated = widget.curves.copyWith(red: newPoints);
        break;
      case CurveChannel.green:
        updated = widget.curves.copyWith(green: newPoints);
        break;
      case CurveChannel.blue:
        updated = widget.curves.copyWith(blue: newPoints);
        break;
    }
    widget.onCurvesChanged(updated);
  }

  void _handlePanDown(Offset localPosition, Size size) {
    final points = List<CurvePoint>.from(_activePoints);
    final normX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normY = (1.0 - (localPosition.dy / size.height)).clamp(0.0, 1.0);

    int? nearestIndex;
    var minDistance = 32.0;

    for (var i = 0; i < points.length; i++) {
      final px = points[i].x * size.width;
      final py = (1.0 - points[i].y) * size.height;
      final dist = (Offset(px, py) - localPosition).distance;
      if (dist < minDistance) {
        minDistance = dist;
        nearestIndex = i;
      }
    }

    if (nearestIndex != null) {
      _activePointIndex = nearestIndex;
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
      // Add a new control point at the tapped location
      points.add(CurvePoint(normX, normY));
      points.sort((a, b) => a.x.compareTo(b.x));
      _activePointIndex = points.indexWhere((p) => (p.x - normX).abs() < 1e-4);
      _updateChannelPoints(points);
    }
    setState(() {});
  }

  void _handlePanStart(Offset localPosition, Size size) {
    if (_activePointIndex == null) {
      _handlePanDown(localPosition, size);
    }
  }

  void _handlePanUpdate(Offset localPosition, Size size) {
    if (_activePointIndex == null) return;

    final points = List<CurvePoint>.from(_activePoints);
    if (_activePointIndex! < 0 || _activePointIndex! >= points.length) return;

    final normX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normY = (1.0 - (localPosition.dy / size.height)).clamp(0.0, 1.0);

    if (_activePointIndex == 0) {
      // First endpoint fixed at x=0.0
      points[0] = CurvePoint(0.0, normY);
    } else if (_activePointIndex == points.length - 1) {
      // Last endpoint fixed at x=1.0
      points[points.length - 1] = CurvePoint(1.0, normY);
    } else {
      // Interior points bounded between neighbor points
      final minX = points[_activePointIndex! - 1].x + 0.01;
      final maxX = points[_activePointIndex! + 1].x - 0.01;
      final clampedX = minX < maxX ? normX.clamp(minX, maxX) : points[_activePointIndex!].x;
      points[_activePointIndex!] = CurvePoint(clampedX, normY);
    }

    _updateChannelPoints(points);
    setState(() {});
  }

  void _handlePanEnd() {
    setState(() {});
  }

  void _resetCurrentChannel() {
    HapticFeedback.lightImpact();
    _activePointIndex = null;
    _updateChannelPoints(const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)]);
    setState(() {});
  }

  void _resetAllChannels() {
    HapticFeedback.lightImpact();
    _activePointIndex = null;
    widget.onCurvesChanged(const ToneCurves());
    setState(() {});
  }

  void _deleteSelectedPoint() {
    if (_activePointIndex == null) return;
    final points = List<CurvePoint>.from(_activePoints);
    if (_activePointIndex! > 0 && _activePointIndex! < points.length - 1) {
      HapticFeedback.lightImpact();
      points.removeAt(_activePointIndex!);
      _activePointIndex = null;
      _updateChannelPoints(points);
      setState(() {});
    }
  }

  void _handleDoubleTapDown(TapDownDetails details, Size size) {
    final points = List<CurvePoint>.from(_activePoints);
    for (var i = 1; i < points.length - 1; i++) {
      final px = points[i].x * size.width;
      final py = (1.0 - points[i].y) * size.height;
      final dist = (Offset(px, py) - details.localPosition).distance;
      if (dist < 32.0) {
        HapticFeedback.lightImpact();
        points.removeAt(i);
        _activePointIndex = null;
        _updateChannelPoints(points);
        setState(() {});
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compactMode) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: LumaGlass(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanDown: (d) => _handlePanDown(d.localPosition, size),
                onPanUpdate: (d) => _handlePanUpdate(d.localPosition, size),
                onPanEnd: (_) => _handlePanEnd(),
                child: CustomPaint(
                  size: size,
                  painter: _CurvePainter(
                    points: _activePoints,
                    curveColor: _activeColor,
                    activePointIndex: _activePointIndex,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    final activePoint = (_activePointIndex != null &&
            _activePointIndex! >= 0 &&
            _activePointIndex! < _activePoints.length)
        ? _activePoints[_activePointIndex!]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Channel Selector Tabs & Actions (Responsive & Overflow-Free)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              // Scrollable Channel Pills
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildChannelTab(CurveChannel.rgb, 'RGB', LumaTheme.primaryBlueLight),
                      const SizedBox(width: 6),
                      _buildChannelTab(CurveChannel.red, 'Red', const Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      _buildChannelTab(CurveChannel.green, 'Green', const Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      _buildChannelTab(CurveChannel.blue, 'Blue', const Color(0xFF3B82F6)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_activePointIndex != null &&
                      _activePointIndex! > 0 &&
                      _activePointIndex! < _activePoints.length - 1)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: LumaTheme.coralRedLight,
                      ),
                      tooltip: 'Delete Point',
                      onPressed: _deleteSelectedPoint,
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    tooltip: 'Reset Channel',
                    onPressed: _resetCurrentChannel,
                  ),
                  if (!widget.curves.isIdentity) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.restart_alt_rounded,
                        size: 18,
                        color: LumaTheme.coralRedLight,
                      ),
                      tooltip: 'Reset All Channels',
                      onPressed: _resetAllChannels,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Value readout badge if point is active
        if (activePoint != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'In: ${(activePoint.x * 255).round()}   Out: ${(activePoint.y * 255).round()}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),

        // 2. Interactive Tone Curve Canvas with Responsive Bounded Sizing
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = math.min(constraints.maxWidth, 260.0);
              return Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: LumaGlass(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final size = Size(
                          innerConstraints.maxWidth,
                          innerConstraints.maxHeight,
                        );
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTapDown: (d) => _handleDoubleTapDown(d, size),
                          onPanDown: (d) => _handlePanDown(d.localPosition, size),
                          onPanStart: (d) => _handlePanStart(d.localPosition, size),
                          onPanUpdate: (d) => _handlePanUpdate(d.localPosition, size),
                          onPanEnd: (_) => _handlePanEnd(),
                          child: CustomPaint(
                            size: size,
                            painter: _CurvePainter(
                              points: _activePoints,
                              curveColor: _activeColor,
                              activePointIndex: _activePointIndex,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChannelTab(CurveChannel channel, String label, Color color) {
    final isSelected = _selectedChannel == channel;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedChannel = channel;
          _activePointIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : const Color(0x401E1E26),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : LumaTheme.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : LumaTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<CurvePoint> points;
  final Color curveColor;
  final int? activePointIndex;

  _CurvePainter({
    required this.points,
    required this.curveColor,
    required this.activePointIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Grid lines (subtle dark lines)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.6;

    for (var i = 1; i < 4; i++) {
      final x = (w / 4) * i;
      final y = (h / 4) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Diagonal neutral baseline
    final diagPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, h), Offset(w, 0), diagPaint);

    if (points.length < 2) return;

    // 3. Monotone Cubic Spline curve path
    final curvePath = Path();
    final firstPx = points.first.x * w;
    final firstPy = (1.0 - points.first.y) * h;
    curvePath.moveTo(firstPx, firstPy);

    for (var x = 0; x <= w; x += 2) {
      final normX = x / w;
      final normY = LutGenerator.evaluateMonotoneSpline(normX, points);
      final py = (1.0 - normY) * h;
      curvePath.lineTo(x.toDouble(), py);
    }

    // Ambient curve glow
    final glowPaint = Paint()
      ..color = curveColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawPath(curvePath, glowPaint);

    final linePaint = Paint()
      ..color = curveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, linePaint);

    // 4. Draggable Node points
    final pointBgPaint = Paint()
      ..color = const Color(0xFF0C0C10)
      ..style = PaintingStyle.fill;

    final pointStrokePaint = Paint()
      ..color = curveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < points.length; i++) {
      final px = points[i].x * w;
      final py = (1.0 - points[i].y) * h;
      final isActive = i == activePointIndex;
      final radius = isActive ? 7.0 : 4.5;

      canvas.drawCircle(Offset(px, py), radius, pointBgPaint);
      canvas.drawCircle(Offset(px, py), radius, pointStrokePaint);

      if (isActive) {
        final activeFill = Paint()
          ..color = curveColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), radius * 0.5, activeFill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) => true;
}
