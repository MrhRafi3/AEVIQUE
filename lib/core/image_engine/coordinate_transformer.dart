import 'package:flutter/material.dart';

/// Centralized coordinate transformer ensuring pixel-perfect spatial alignment
/// between viewport gestures, crop overlays, zoom/pan transforms, and mask coordinates.
class ImageCoordinateTransformer {
  /// Computes the exact letterboxed Rect where an image is rendered inside a viewport using BoxFit.contain.
  static Rect getDisplayRect({
    required Size viewportSize,
    required double imageAspectRatio,
  }) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0 || imageAspectRatio <= 0) {
      return Rect.zero;
    }

    final viewportAspect = viewportSize.width / viewportSize.height;
    double renderW;
    double renderH;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (viewportAspect > imageAspectRatio) {
      renderH = viewportSize.height;
      renderW = renderH * imageAspectRatio;
      offsetX = (viewportSize.width - renderW) / 2.0;
    } else {
      renderW = viewportSize.width;
      renderH = renderW / imageAspectRatio;
      offsetY = (viewportSize.height - renderH) / 2.0;
    }

    return Rect.fromLTWH(offsetX, offsetY, renderW, renderH);
  }

  /// Maps a viewport touch position into normalized [0.0 .. 1.0] image coordinates.
  /// Accounts for InteractiveViewer transformation matrix and BoxFit.contain letterboxing.
  static Offset? viewportToNormalized({
    required Offset viewportPos,
    required Size viewportSize,
    required double imageAspectRatio,
    Matrix4? viewTransform,
    bool clampToImage = true,
  }) {
    final displayRect = getDisplayRect(
      viewportSize: viewportSize,
      imageAspectRatio: imageAspectRatio,
    );

    if (displayRect.width <= 0 || displayRect.height <= 0) return null;

    Offset scenePos = viewportPos;
    if (viewTransform != null) {
      final inv = Matrix4.tryInvert(viewTransform);
      if (inv != null) {
        scenePos = MatrixUtils.transformPoint(inv, viewportPos);
      }
    }

    final normX = (scenePos.dx - displayRect.left) / displayRect.width;
    final normY = (scenePos.dy - displayRect.top) / displayRect.height;

    if (!clampToImage) {
      if (normX < 0.0 || normX > 1.0 || normY < 0.0 || normY > 1.0) {
        return null;
      }
    }

    return Offset(
      normX.clamp(0.0, 1.0),
      normY.clamp(0.0, 1.0),
    );
  }

  /// Maps normalized [0.0 .. 1.0] image coordinates back to viewport screen coordinates.
  static Offset normalizedToViewport({
    required Offset normPos,
    required Size viewportSize,
    required double imageAspectRatio,
    Matrix4? viewTransform,
  }) {
    final displayRect = getDisplayRect(
      viewportSize: viewportSize,
      imageAspectRatio: imageAspectRatio,
    );

    var scenePos = Offset(
      displayRect.left + normPos.dx * displayRect.width,
      displayRect.top + normPos.dy * displayRect.height,
    );

    if (viewTransform != null) {
      scenePos = MatrixUtils.transformPoint(viewTransform, scenePos);
    }

    return scenePos;
  }

  /// Transforms a normalized crop rectangle [0..1] when an image is rotated by 90-degree steps or flips.
  static Rect transformCropWithQuarterTurns({
    required Rect cropRect,
    required int rotationQuarterTurns,
    required bool flipHorizontal,
    required bool flipVertical,
  }) {
    var l = cropRect.left;
    var t = cropRect.top;
    var r = cropRect.right;
    var b = cropRect.bottom;

    if (flipHorizontal) {
      final oldL = l;
      l = 1.0 - r;
      r = 1.0 - oldL;
    }
    if (flipVertical) {
      final oldT = t;
      t = 1.0 - b;
      b = 1.0 - oldT;
    }

    return Rect.fromLTRB(l, t, r, b);
  }
}
