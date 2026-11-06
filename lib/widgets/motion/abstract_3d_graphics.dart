import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/aevique_theme.dart';

/// Premium Apple-inspired Abstract 3D Motion Graphics.
///
/// Features:
/// - Three-dimensional organic sculptural forms (Cobalt Blue, Creative Orange, Coral Red).
/// - Dynamic multi-harmonic liquid morphing and smooth volumetric deformation.
/// - Realistic simulated 3D lighting: diffuse illumination, specular highlight glints, and Fresnel rim reflections.
/// - Depth-sorted multi-layer rendering with ambient occlusion.
/// - Lifecycle-aware: automatically pauses when screen is inactive or app is in background.
/// - Respects reduced-motion accessibility settings.
class Abstract3DMotionGraphics extends StatefulWidget {
  final bool isInteractive;
  final double speedMultiplier;

  const Abstract3DMotionGraphics({
    super.key,
    this.isInteractive = true,
    this.speedMultiplier = 1.0,
  });

  @override
  State<Abstract3DMotionGraphics> createState() =>
      _Abstract3DMotionGraphicsState();
}

class _Abstract3DMotionGraphicsState extends State<Abstract3DMotionGraphics>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  Offset _pointerOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerEvent event, Size size) {
    if (!widget.isInteractive) return;
    final normalizedX = (event.localPosition.dx / size.width - 0.5) * 2.0;
    final normalizedY = (event.localPosition.dy / size.height - 0.5) * 2.0;
    setState(() {
      _targetOffset = Offset(normalizedX, normalizedY);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Smoothly interpolate pointer for interactive parallax
        _pointerOffset = Offset(
          _pointerOffset.dx + (_targetOffset.dx - _pointerOffset.dx) * 0.05,
          _pointerOffset.dy + (_targetOffset.dy - _pointerOffset.dy) * 0.05,
        );

        return MouseRegion(
          onHover: (e) => _onPointerHover(e, size),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value * 2.0 * math.pi;
                return CustomPaint(
                  size: size,
                  painter: _Abstract3DPainter(
                    time: t,
                    parallax: _pointerOffset,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Dynamic Painter rendering 3D organic sculptural liquid forms
class _Abstract3DPainter extends CustomPainter {
  final double time;
  final Offset parallax;

  _Abstract3DPainter({required this.time, required this.parallax});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final minDim = math.min(size.width, size.height);

    // 0. Base Ambient Atmospheric Lighting
    final bgGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.2 + parallax.dx * 0.15, -0.3 + parallax.dy * 0.15),
        radius: 1.2,
        colors: [
          const Color(0x331E3C72),
          const Color(0x1A0F1E36),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgGlowPaint);

    // --- FORM 3: MODERN CORAL RED FLOATING ACCENT WAVE (Back layer) ---
    final redCenterX =
        cx + math.cos(time * 0.4) * minDim * 0.28 + parallax.dx * 12.0;
    final redCenterY =
        cy - math.sin(time * 0.5) * minDim * 0.22 + parallax.dy * 12.0;
    final redRadius = minDim * 0.22;
    _drawVolumetricSculpture(
      canvas: canvas,
      center: Offset(redCenterX, redCenterY),
      baseRadius: redRadius,
      phaseOffset: time * 0.7 + 1.2,
      harmonics: [
        _Harmonic(frequency: 2.0, amplitude: redRadius * 0.22, speed: 0.8),
        _Harmonic(frequency: 4.0, amplitude: redRadius * 0.10, speed: -1.2),
      ],
      coreColor: const Color(0xFFD62938),
      bodyColor: const Color(0xFFF04452),
      rimColor: const Color(0xFFFFA6AE),
      specularColor: const Color(0xFFFFF0F2),
      lightAngle: -math.pi / 3 + math.sin(time * 0.3) * 0.3,
      rotation: time * 0.2,
    );

    // --- FORM 2: CREATIVE VIBRANT ORANGE LIQUID SCULPTURE (Mid-orbiting layer) ---
    final orangeCenterX =
        cx + math.sin(time * 0.6) * minDim * 0.26 - parallax.dx * 18.0;
    final orangeCenterY =
        cy + math.cos(time * 0.45) * minDim * 0.24 - parallax.dy * 18.0;
    final orangeRadius = minDim * 0.26;
    _drawVolumetricSculpture(
      canvas: canvas,
      center: Offset(orangeCenterX, orangeCenterY),
      baseRadius: orangeRadius,
      phaseOffset: time * 0.9 + 3.14,
      harmonics: [
        _Harmonic(frequency: 3.0, amplitude: orangeRadius * 0.25, speed: 1.1),
        _Harmonic(frequency: 5.0, amplitude: orangeRadius * 0.12, speed: -0.9),
      ],
      coreColor: const Color(0xFFDF6B15),
      bodyColor: const Color(0xFFFF8A32),
      rimColor: const Color(0xFFFFD59E),
      specularColor: const Color(0xFFFFFDF5),
      lightAngle: -math.pi / 4 + math.cos(time * 0.35) * 0.25,
      rotation: -time * 0.25,
    );

    // --- FORM 1: PRIMARY COBALT / ELECTRIC BLUE CORE SCULPTURE (Front Master Form) ---
    final blueCenterX =
        cx - math.sin(time * 0.35) * minDim * 0.12 + parallax.dx * 25.0;
    final blueCenterY =
        cy + math.sin(time * 0.4) * minDim * 0.08 + parallax.dy * 25.0;
    final blueRadius = minDim * 0.34;
    _drawVolumetricSculpture(
      canvas: canvas,
      center: Offset(blueCenterX, blueCenterY),
      baseRadius: blueRadius,
      phaseOffset: time * 0.5,
      harmonics: [
        _Harmonic(frequency: 2.0, amplitude: blueRadius * 0.20, speed: 0.6),
        _Harmonic(frequency: 3.0, amplitude: blueRadius * 0.14, speed: -0.7),
        _Harmonic(frequency: 6.0, amplitude: blueRadius * 0.06, speed: 1.4),
      ],
      coreColor: const Color(0xFF1445B8),
      bodyColor: const Color(0xFF3478F6),
      rimColor: const Color(0xFF86B7FE),
      specularColor: const Color(0xFFFFFFFF),
      lightAngle: -math.pi / 3 + math.sin(time * 0.25) * 0.2,
      rotation: time * 0.15,
    );

    // Subtle atmospheric refraction overlay ring
    _drawRefractionCaustic(
      canvas,
      Offset(blueCenterX, blueCenterY),
      blueRadius * 1.18,
      time,
    );
  }

  /// Draws a single 3D volumetric organic liquid-glass sculptural form
  void _drawVolumetricSculpture({
    required Canvas canvas,
    required Offset center,
    required double baseRadius,
    required double phaseOffset,
    required List<_Harmonic> harmonics,
    required Color coreColor,
    required Color bodyColor,
    required Color rimColor,
    required Color specularColor,
    required double lightAngle,
    required double rotation,
  }) {
    final numPoints = 120;
    final path = Path();
    final points = <Offset>[];

    // Compute organically deformed 3D perimeter
    for (int i = 0; i < numPoints; i++) {
      final theta = (i / numPoints) * 2 * math.pi;
      double r = baseRadius;

      for (final h in harmonics) {
        r +=
            h.amplitude *
            math.sin(h.frequency * theta + phaseOffset * h.speed + rotation);
      }

      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);
      points.add(Offset(x, y));
    }

    // Generate smooth cubic bezier spline through points
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < numPoints; i++) {
      final p0 = points[i];
      final p1 = points[(i + 1) % numPoints];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.close();

    // 1. Ambient Occlusion & Soft Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.save();
    canvas.translate(0, 16);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. Volumetric 3D Radial Core Gradient
    final lightOffset = Offset(
      center.dx + math.cos(lightAngle) * baseRadius * 0.45,
      center.dy + math.sin(lightAngle) * baseRadius * 0.45,
    );

    final volumetricShader = RadialGradient(
      center: Alignment(
        (lightOffset.dx - center.dx) / baseRadius,
        (lightOffset.dy - center.dy) / baseRadius,
      ),
      radius: 1.15,
      colors: [
        rimColor.withValues(alpha: 0.95),
        bodyColor.withValues(alpha: 0.88),
        coreColor.withValues(alpha: 0.95),
        const Color(0xFF060912).withValues(alpha: 0.95),
      ],
      stops: const [0.0, 0.35, 0.72, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.3));

    final bodyPaint = Paint()
      ..shader = volumetricShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    // 3. Fresnel Luminous Edge Rim (Optical refraction highlight)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          rimColor.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.9),
          bodyColor.withValues(alpha: 0.2),
          rimColor.withValues(alpha: 0.7),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius * 1.2));
    canvas.drawPath(path, rimPaint);

    // 4. Glossy Specular Highlight Spot (Apple-inspired liquid polymer sheen)
    final specularOffset = Offset(
      center.dx + math.cos(lightAngle) * baseRadius * 0.48,
      center.dy + math.sin(lightAngle) * baseRadius * 0.48,
    );
    final specularPaint = Paint()
      ..shader =
          RadialGradient(
            center: Alignment.center,
            radius: 0.5,
            colors: [
              specularColor.withValues(alpha: 0.85),
              specularColor.withValues(alpha: 0.25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(
            Rect.fromCircle(center: specularOffset, radius: baseRadius * 0.38),
          );

    canvas.save();
    canvas.translate(specularOffset.dx, specularOffset.dy);
    canvas.rotate(lightAngle + math.pi / 4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: baseRadius * 0.45,
        height: baseRadius * 0.22,
      ),
      specularPaint,
    );
    canvas.restore();
  }

  /// Draws a secondary caustic light loop floating around the main form
  void _drawRefractionCaustic(
    Canvas canvas,
    Offset center,
    double radius,
    double time,
  ) {
    final causticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: time * 0.3,
        endAngle: time * 0.3 + 2 * math.pi,
        colors: [
          Colors.transparent,
          AeviqueTheme.primaryBlueLight.withValues(alpha: 0.3),
          AeviqueTheme.creativeOrangeLight.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, causticPaint);
  }

  @override
  bool shouldRepaint(covariant _Abstract3DPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.parallax != parallax;
  }
}

class _Harmonic {
  final double frequency;
  final double amplitude;
  final double speed;

  const _Harmonic({
    required this.frequency,
    required this.amplitude,
    required this.speed,
  });
}
