import 'package:flutter/material.dart';
import '../core/models/edit_state.dart';
import '../theme/luma_theme.dart';

enum CurveChannel { rgb, red, green, blue }

class CurveEditorWidget extends StatefulWidget {
  final ToneCurves curves;
  final ValueChanged<ToneCurves> onCurvesChanged;

  const CurveEditorWidget({
    super.key,
    required this.curves,
    required this.onCurvesChanged,
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
        return LumaTheme.textPrimary;
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

    // Find nearest point within radius 24px
    int? nearestIndex;
    var minDistance = 24.0;

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
    } else {
      // Add new point
      points.add(CurvePoint(normX, normY));
      points.sort((a, b) => a.x.compareTo(b.x));
      _activePointIndex = points.indexWhere((p) => (p.x - normX).abs() < 1e-4);
      _updateChannelPoints(points);
    }
    setState(() {});
  }

  void _handlePanUpdate(Offset localPosition, Size size) {
    if (_activePointIndex == null) return;

    final points = List<CurvePoint>.from(_activePoints);
    if (_activePointIndex! < 0 || _activePointIndex! >= points.length) return;

    final normX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final normY = (1.0 - (localPosition.dy / size.height)).clamp(0.0, 1.0);

    // End points only move vertically
    if (_activePointIndex == 0) {
      points[0] = CurvePoint(0.0, normY);
    } else if (_activePointIndex == points.length - 1) {
      points[points.length - 1] = CurvePoint(1.0, normY);
    } else {
      points[_activePointIndex!] = CurvePoint(normX, normY);
      points.sort((a, b) => a.x.compareTo(b.x));
      _activePointIndex = points.indexWhere((p) => (p.x - normX).abs() < 1e-4);
    }

    _updateChannelPoints(points);
    setState(() {});
  }

  void _handlePanEnd() {
    _activePointIndex = null;
    setState(() {});
  }

  void _resetCurrentChannel() {
    _updateChannelPoints(const [CurvePoint(0.0, 0.0), CurvePoint(1.0, 1.0)]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Channel Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildChannelTab(
                    CurveChannel.rgb,
                    'RGB',
                    LumaTheme.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  _buildChannelTab(
                    CurveChannel.red,
                    'Red',
                    const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 8),
                  _buildChannelTab(
                    CurveChannel.green,
                    'Green',
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  _buildChannelTab(
                    CurveChannel.blue,
                    'Blue',
                    const Color(0xFF3B82F6),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: LumaTheme.textSecondary,
                ),
                tooltip: 'Reset Channel Curve',
                onPressed: _resetCurrentChannel,
              ),
            ],
          ),
        ),
        // Interactive Curve Canvas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: LumaTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LumaTheme.border, width: 1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
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
          ),
        ),
      ],
    );
  }

  Widget _buildChannelTab(CurveChannel channel, String label, Color color) {
    final isSelected = _selectedChannel == channel;
    return GestureDetector(
      onTap: () => setState(() => _selectedChannel = channel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : LumaTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? LumaTheme.textPrimary
                    : LumaTheme.textSecondary,
              ),
            ),
          ],
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
    this.activePointIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = LumaTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw 4x4 Grid
    for (var i = 1; i < 4; i++) {
      final dx = size.width * (i / 4.0);
      final dy = size.height * (i / 4.0);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // Diagonal reference line
    final diagPaint = Paint()
      ..color = LumaTheme.borderLight.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), diagPaint);

    if (points.isEmpty) return;

    // Draw Smooth Spline
    final path = Path();
    for (var i = 0; i < 256; i++) {
      final normX = i / 255.0;
      final normY = _interpolate(normX, points);
      final px = normX * size.width;
      final py = (1.0 - normY) * size.height;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }

    final curvePaint = Paint()
      ..color = curveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, curvePaint);

    // Draw Control Points
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final px = p.x * size.width;
      final py = (1.0 - p.y) * size.height;
      final isActive = i == activePointIndex;

      // Outer glow/ring
      final ringPaint = Paint()
        ..color = isActive ? curveColor : LumaTheme.surfaceHighlight
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), isActive ? 7.0 : 5.0, ringPaint);

      // Inner dot
      final dotPaint = Paint()
        ..color = isActive ? LumaTheme.background : curveColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), isActive ? 3.5 : 2.5, dotPaint);
    }
  }

  double _interpolate(double normX, List<CurvePoint> pts) {
    if (pts.isEmpty) return normX;
    if (normX <= pts.first.x) return pts.first.y;
    if (normX >= pts.last.x) return pts.last.y;

    var idx = 0;
    while (idx < pts.length - 1 && pts[idx + 1].x < normX) {
      idx++;
    }
    final p0 = pts[idx];
    final p1 = pts[idx + 1];
    final dx = p1.x - p0.x;
    final t = dx > 0 ? (normX - p0.x) / dx : 0.0;
    final smoothT = t * t * (3.0 - 2.0 * t);
    return p0.y + (p1.y - p0.y) * smoothT;
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) => true;
}
