import 'package:flutter/material.dart';
import '../theme/luma_theme.dart';

enum _Handle { none, inside, topLeft, topRight, bottomLeft, bottomRight }

class CropOverlayWidget extends StatefulWidget {
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final Function(double left, double top, double right, double bottom)
  onCropChanged;

  const CropOverlayWidget({
    super.key,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.onCropChanged,
  });

  @override
  State<CropOverlayWidget> createState() => _CropOverlayWidgetState();
}

class _CropOverlayWidgetState extends State<CropOverlayWidget> {
  _Handle _activeHandle = _Handle.none;
  Offset? _lastPanPos;

  _Handle _hitTest(Offset local, Size size) {
    const handleHitRadius = 30.0;
    final l = widget.cropLeft * size.width;
    final t = widget.cropTop * size.height;
    final r = widget.cropRight * size.width;
    final b = widget.cropBottom * size.height;

    if ((local - Offset(l, t)).distance < handleHitRadius) {
      return _Handle.topLeft;
    }
    if ((local - Offset(r, t)).distance < handleHitRadius) {
      return _Handle.topRight;
    }
    if ((local - Offset(l, b)).distance < handleHitRadius) {
      return _Handle.bottomLeft;
    }
    if ((local - Offset(r, b)).distance < handleHitRadius) {
      return _Handle.bottomRight;
    }

    if (local.dx >= l && local.dx <= r && local.dy >= t && local.dy <= b) {
      return _Handle.inside;
    }

    return _Handle.none;
  }

  void _onPanDown(DragDownDetails details, Size size) {
    _activeHandle = _hitTest(details.localPosition, size);
    _lastPanPos = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_activeHandle == _Handle.none || _lastPanPos == null) return;

    final dx = (details.localPosition.dx - _lastPanPos!.dx) / size.width;
    final dy = (details.localPosition.dy - _lastPanPos!.dy) / size.height;
    _lastPanPos = details.localPosition;

    var newL = widget.cropLeft;
    var newT = widget.cropTop;
    var newR = widget.cropRight;
    var newB = widget.cropBottom;

    const minSize = 0.1;

    switch (_activeHandle) {
      case _Handle.inside:
        final spanX = newR - newL;
        final spanY = newB - newT;
        newL = (newL + dx).clamp(0.0, 1.0 - spanX);
        newR = newL + spanX;
        newT = (newT + dy).clamp(0.0, 1.0 - spanY);
        newB = newT + spanY;
        break;
      case _Handle.topLeft:
        newL = (newL + dx).clamp(0.0, newR - minSize);
        newT = (newT + dy).clamp(0.0, newB - minSize);
        break;
      case _Handle.topRight:
        newR = (newR + dx).clamp(newL + minSize, 1.0);
        newT = (newT + dy).clamp(0.0, newB - minSize);
        break;
      case _Handle.bottomLeft:
        newL = (newL + dx).clamp(0.0, newR - minSize);
        newB = (newB + dy).clamp(newT + minSize, 1.0);
        break;
      case _Handle.bottomRight:
        newR = (newR + dx).clamp(newL + minSize, 1.0);
        newB = (newB + dy).clamp(newT + minSize, 1.0);
        break;
      case _Handle.none:
        break;
    }

    widget.onCropChanged(newL, newT, newR, newB);
  }

  void _onPanEnd(DragEndDetails details) {
    _activeHandle = _Handle.none;
    _lastPanPos = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _onPanDown(d, size),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            size: size,
            painter: _CropPainter(
              cropLeft: widget.cropLeft,
              cropTop: widget.cropTop,
              cropRight: widget.cropRight,
              cropBottom: widget.cropBottom,
            ),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  _CropPainter({
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final l = cropLeft * size.width;
    final t = cropTop * size.height;
    final r = cropRight * size.width;
    final b = cropBottom * size.height;
    final cropRect = Rect.fromLTRB(l, t, r, b);

    // 1. Darken outside the crop box
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, t), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(0, b, size.width, size.height), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(0, t, l, b), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(r, t, size.width, b), overlayPaint);

    // 2. Crop border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(cropRect, borderPaint);

    // 3. Rule-of-Thirds Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final w = r - l;
    final h = b - t;
    canvas.drawLine(Offset(l + w / 3, t), Offset(l + w / 3, b), gridPaint);
    canvas.drawLine(
      Offset(l + 2 * w / 3, t),
      Offset(l + 2 * w / 3, b),
      gridPaint,
    );
    canvas.drawLine(Offset(l, t + h / 3), Offset(r, t + h / 3), gridPaint);
    canvas.drawLine(
      Offset(l, t + 2 * h / 3),
      Offset(r, t + 2 * h / 3),
      gridPaint,
    );

    // 4. Corner Handles
    final handlePaint = Paint()
      ..color = LumaTheme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    const arm = 18.0;
    // Top-Left
    canvas.drawLine(Offset(l, t), Offset(l + arm, t), handlePaint);
    canvas.drawLine(Offset(l, t), Offset(l, t + arm), handlePaint);
    // Top-Right
    canvas.drawLine(Offset(r, t), Offset(r - arm, t), handlePaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + arm), handlePaint);
    // Bottom-Left
    canvas.drawLine(Offset(l, b), Offset(l + arm, b), handlePaint);
    canvas.drawLine(Offset(l, b), Offset(l, b - arm), handlePaint);
    // Bottom-Right
    canvas.drawLine(Offset(r, b), Offset(r - arm, b), handlePaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - arm), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) =>
      cropLeft != oldDelegate.cropLeft ||
      cropTop != oldDelegate.cropTop ||
      cropRight != oldDelegate.cropRight ||
      cropBottom != oldDelegate.cropBottom;
}
