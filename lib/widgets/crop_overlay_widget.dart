import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/image_engine/coordinate_transformer.dart';
import '../theme/luma_theme.dart';

enum _Handle {
  none,
  inside,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  edgeTop,
  edgeBottom,
  edgeLeft,
  edgeRight,
}

class CropOverlayWidget extends StatefulWidget {
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final double imageAspectRatio;
  final double? lockedAspectRatio;
  final Function(double left, double top, double right, double bottom) onCropChanged;

  const CropOverlayWidget({
    super.key,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    this.imageAspectRatio = 1.0,
    this.lockedAspectRatio,
    required this.onCropChanged,
  });

  @override
  State<CropOverlayWidget> createState() => _CropOverlayWidgetState();
}

class _CropOverlayWidgetState extends State<CropOverlayWidget> {
  _Handle _activeHandle = _Handle.none;
  Offset? _lastPanPos;

  Rect _getDisplayRect(Size size) {
    return ImageCoordinateTransformer.getDisplayRect(
      viewportSize: size,
      imageAspectRatio: widget.imageAspectRatio > 0 ? widget.imageAspectRatio : 1.0,
    );
  }

  _Handle _hitTest(Offset local, Size size) {
    final dRect = _getDisplayRect(size);
    if (dRect.width <= 0 || dRect.height <= 0) return _Handle.none;

    const cornerRadius = 36.0;
    const edgeRadius = 24.0;

    final l = dRect.left + widget.cropLeft * dRect.width;
    final t = dRect.top + widget.cropTop * dRect.height;
    final r = dRect.left + widget.cropRight * dRect.width;
    final b = dRect.top + widget.cropBottom * dRect.height;

    // 1. Check 4 corners first
    if ((local - Offset(l, t)).distance < cornerRadius) return _Handle.topLeft;
    if ((local - Offset(r, t)).distance < cornerRadius) return _Handle.topRight;
    if ((local - Offset(l, b)).distance < cornerRadius) return _Handle.bottomLeft;
    if ((local - Offset(r, b)).distance < cornerRadius) return _Handle.bottomRight;

    // 2. Check 4 edges
    if ((local.dy - t).abs() < edgeRadius && local.dx >= l - edgeRadius && local.dx <= r + edgeRadius) {
      return _Handle.edgeTop;
    }
    if ((local.dy - b).abs() < edgeRadius && local.dx >= l - edgeRadius && local.dx <= r + edgeRadius) {
      return _Handle.edgeBottom;
    }
    if ((local.dx - l).abs() < edgeRadius && local.dy >= t - edgeRadius && local.dy <= b + edgeRadius) {
      return _Handle.edgeLeft;
    }
    if ((local.dx - r).abs() < edgeRadius && local.dy >= t - edgeRadius && local.dy <= b + edgeRadius) {
      return _Handle.edgeRight;
    }

    // 3. Inside crop area
    if (local.dx >= l && local.dx <= r && local.dy >= t && local.dy <= b) {
      return _Handle.inside;
    }

    return _Handle.none;
  }

  void _onPanDown(DragDownDetails details, Size size) {
    _activeHandle = _hitTest(details.localPosition, size);
    _lastPanPos = details.localPosition;
    if (_activeHandle != _Handle.none) {
      HapticFeedback.selectionClick();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_activeHandle == _Handle.none || _lastPanPos == null) return;

    final dRect = _getDisplayRect(size);
    if (dRect.width <= 0 || dRect.height <= 0) return;

    final dx = (details.localPosition.dx - _lastPanPos!.dx) / dRect.width;
    final dy = (details.localPosition.dy - _lastPanPos!.dy) / dRect.height;
    _lastPanPos = details.localPosition;

    var newL = widget.cropLeft;
    var newT = widget.cropTop;
    var newR = widget.cropRight;
    var newB = widget.cropBottom;

    const minSpan = 0.08;
    final rNorm = widget.lockedAspectRatio != null
        ? (widget.lockedAspectRatio! / (widget.imageAspectRatio > 0 ? widget.imageAspectRatio : 1.0))
        : null;

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
        newL = (newL + dx).clamp(0.0, newR - minSpan);
        if (rNorm != null) {
          final spanX = newR - newL;
          final spanY = spanX / rNorm;
          newT = (newB - spanY).clamp(0.0, newB - minSpan);
          newL = newR - (newB - newT) * rNorm;
        } else {
          newT = (newT + dy).clamp(0.0, newB - minSpan);
        }
        break;

      case _Handle.topRight:
        newR = (newR + dx).clamp(newL + minSpan, 1.0);
        if (rNorm != null) {
          final spanX = newR - newL;
          final spanY = spanX / rNorm;
          newT = (newB - spanY).clamp(0.0, newB - minSpan);
          newR = newL + (newB - newT) * rNorm;
        } else {
          newT = (newT + dy).clamp(0.0, newB - minSpan);
        }
        break;

      case _Handle.bottomLeft:
        newL = (newL + dx).clamp(0.0, newR - minSpan);
        if (rNorm != null) {
          final spanX = newR - newL;
          final spanY = spanX / rNorm;
          newB = (newT + spanY).clamp(newT + minSpan, 1.0);
          newL = newR - (newB - newT) * rNorm;
        } else {
          newB = (newB + dy).clamp(newT + minSpan, 1.0);
        }
        break;

      case _Handle.bottomRight:
        newR = (newR + dx).clamp(newL + minSpan, 1.0);
        if (rNorm != null) {
          final spanX = newR - newL;
          final spanY = spanX / rNorm;
          newB = (newT + spanY).clamp(newT + minSpan, 1.0);
          newR = newL + (newB - newT) * rNorm;
        } else {
          newB = (newB + dy).clamp(newT + minSpan, 1.0);
        }
        break;

      case _Handle.edgeTop:
        newT = (newT + dy).clamp(0.0, newB - minSpan);
        if (rNorm != null) {
          final spanY = newB - newT;
          final spanX = (spanY * rNorm).clamp(minSpan, 1.0);
          final midX = (newL + newR) / 2.0;
          newL = (midX - spanX / 2.0).clamp(0.0, 1.0 - spanX);
          newR = newL + spanX;
        }
        break;

      case _Handle.edgeBottom:
        newB = (newB + dy).clamp(newT + minSpan, 1.0);
        if (rNorm != null) {
          final spanY = newB - newT;
          final spanX = (spanY * rNorm).clamp(minSpan, 1.0);
          final midX = (newL + newR) / 2.0;
          newL = (midX - spanX / 2.0).clamp(0.0, 1.0 - spanX);
          newR = newL + spanX;
        }
        break;

      case _Handle.edgeLeft:
        newL = (newL + dx).clamp(0.0, newR - minSpan);
        if (rNorm != null) {
          final spanX = newR - newL;
          final spanY = (spanX / rNorm).clamp(minSpan, 1.0);
          final midY = (newT + newB) / 2.0;
          newT = (midY - spanY / 2.0).clamp(0.0, 1.0 - spanY);
          newB = newT + spanY;
        }
        break;

      case _Handle.edgeRight:
        newR = (newR + dx).clamp(newL + minSpan, 1.0);
        if (rNorm != null) {
          final spanX = newR - newL;
          final spanY = (spanX / rNorm).clamp(minSpan, 1.0);
          final midY = (newT + newB) / 2.0;
          newT = (midY - spanY / 2.0).clamp(0.0, 1.0 - spanY);
          newB = newT + spanY;
        }
        break;

      case _Handle.none:
        break;
    }

    widget.onCropChanged(
      newL.clamp(0.0, 1.0),
      newT.clamp(0.0, 1.0),
      newR.clamp(0.0, 1.0),
      newB.clamp(0.0, 1.0),
    );
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
        final dRect = _getDisplayRect(size);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _onPanDown(d, size),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            size: size,
            painter: _CropPainter(
              displayRect: dRect,
              cropLeft: widget.cropLeft,
              cropTop: widget.cropTop,
              cropRight: widget.cropRight,
              cropBottom: widget.cropBottom,
              activeHandle: _activeHandle,
            ),
          ),
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect displayRect;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final _Handle activeHandle;

  _CropPainter({
    required this.displayRect,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.activeHandle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (displayRect.width <= 0 || displayRect.height <= 0) return;

    final l = displayRect.left + cropLeft * displayRect.width;
    final t = displayRect.top + cropTop * displayRect.height;
    final r = displayRect.left + cropRight * displayRect.width;
    final b = displayRect.top + cropBottom * displayRect.height;
    final cropRect = Rect.fromLTRB(l, t, r, b);

    // 1. Shaded overlay for uncropped region
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(bgPath, dimPaint);

    // 2. Rule of thirds grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    final w = cropRect.width;
    final h = cropRect.height;
    canvas.drawLine(Offset(l + w / 3, t), Offset(l + w / 3, b), gridPaint);
    canvas.drawLine(Offset(l + 2 * w / 3, t), Offset(l + 2 * w / 3, b), gridPaint);
    canvas.drawLine(Offset(l, t + h / 3), Offset(r, t + h / 3), gridPaint);
    canvas.drawLine(Offset(l, t + 2 * h / 3), Offset(r, t + 2 * h / 3), gridPaint);

    // 3. Crisp crop outline
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(cropRect, borderPaint);

    // 4. Corner L-Brackets
    final cornerPaint = Paint()
      ..color = LumaTheme.primaryBlueLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.square;

    const cLen = 18.0;

    // Top-Left
    canvas.drawLine(Offset(l - 1, t), Offset(l + cLen, t), cornerPaint);
    canvas.drawLine(Offset(l, t - 1), Offset(l, t + cLen), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(r + 1, t), Offset(r - cLen, t), cornerPaint);
    canvas.drawLine(Offset(r, t - 1), Offset(r, t + cLen), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(l - 1, b), Offset(l + cLen, b), cornerPaint);
    canvas.drawLine(Offset(l, b + 1), Offset(l, b - cLen), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(r + 1, b), Offset(r - cLen, b), cornerPaint);
    canvas.drawLine(Offset(r, b + 1), Offset(r, b - cLen), cornerPaint);

    // 5. Edge Mid-Ticks
    final edgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const eLen = 16.0;
    // Top
    canvas.drawLine(Offset(l + w / 2 - eLen / 2, t), Offset(l + w / 2 + eLen / 2, t), edgePaint);
    // Bottom
    canvas.drawLine(Offset(l + w / 2 - eLen / 2, b), Offset(l + w / 2 + eLen / 2, b), edgePaint);
    // Left
    canvas.drawLine(Offset(l, t + h / 2 - eLen / 2), Offset(l, t + h / 2 + eLen / 2), edgePaint);
    // Right
    canvas.drawLine(Offset(r, t + h / 2 - eLen / 2), Offset(r, t + h / 2 + eLen / 2), edgePaint);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return displayRect != oldDelegate.displayRect ||
        cropLeft != oldDelegate.cropLeft ||
        cropTop != oldDelegate.cropTop ||
        cropRight != oldDelegate.cropRight ||
        cropBottom != oldDelegate.cropBottom ||
        activeHandle != oldDelegate.activeHandle;
  }
}
