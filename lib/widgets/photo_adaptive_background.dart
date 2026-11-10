import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/luma_theme.dart';

/// Photo-Adaptive Ambient Background for the LumaFix Editor.
///
/// Implements Layer 1 of the Editor workspace:
/// - Derived purely from the active photo bytes.
/// - Scaled with cover fit and heavily blurred via [ImageFiltered].
/// - Darkened and softened with an adaptive gradient overlay for guaranteed glass control readability.
/// - Completely isolated from the editing canvas (Layer 2) and the export pipeline.
class PhotoAdaptiveBackground extends StatelessWidget {
  final Uint8List? imageBytes;
  final Widget? child;

  const PhotoAdaptiveBackground({
    super.key,
    required this.imageBytes,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes == null || imageBytes!.isEmpty) {
      return Container(color: LumaTheme.deepCanvas, child: child);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Photo-derived Ambient Background (Heavily Blurred)
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: Transform.scale(
                scale:
                    1.25, // Slight scale prevents blurred edges from showing transparent borders
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 50.0,
                    sigmaY: 50.0,
                    tileMode: TileMode.mirror,
                  ),
                  child: Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. Adaptive Studio Gradient & Vignette Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LumaTheme.deepCanvas.withValues(alpha: 0.72),
                    LumaTheme.deepCanvas.withValues(alpha: 0.48),
                    LumaTheme.deepCanvas.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. Subtle Vignette Rim
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    LumaTheme.deepCanvas.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 4. Foreground (Canvas, Toolbars, Liquid Glass Controls)
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}
