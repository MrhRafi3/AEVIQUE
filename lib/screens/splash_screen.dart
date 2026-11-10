import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/luma_theme.dart';
import '../widgets/luma_logo.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final Duration displayDuration;
  final Widget? nextScreen;

  const SplashScreen({
    super.key,
    this.displayDuration = const Duration(milliseconds: 1600),
    this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _wordmarkFade;
  late Animation<double> _wordmarkSpacing;
  late Animation<double> _taglineFade;
  late Animation<double> _creditFade;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    );
    _wordmarkSpacing = Tween<double>(begin: 2.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.90, curve: Curves.easeOutCubic),
    );
    _creditFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _navigationTimer = Timer(widget.displayDuration, _proceedToNextScreen);
  }

  void _proceedToNextScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen ?? const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaTheme.deepCanvas,
      body: Stack(
        children: [
          // Ambient 3-color atmospheric light diffusion
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            height: 420,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.2),
                    radius: 1.2,
                    colors: [
                      LumaTheme.primaryBlue.withValues(alpha: 0.15),
                      LumaTheme.creativeOrange.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const LumaLogo(size: 80, showGlow: true),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _wordmarkFade,
                  child: AnimatedBuilder(
                    animation: _wordmarkSpacing,
                    builder: (context, child) {
                      return Text(
                        'LUMAFIX',
                        style: LumaTheme.wordmarkStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: _wordmarkSpacing.value,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _taglineFade,
                  child: const Text(
                    'See Beyond Ordinary.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.0,
                      color: LumaTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Developer Credit
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _creditFade,
              child: const Text(
                'Developed by Mrh Rafi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: Color(0xFF555562),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
