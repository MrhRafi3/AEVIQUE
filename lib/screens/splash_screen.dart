import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_logo.dart';
import 'home_screen.dart';

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

    // Staged Choreography:
    // Stage 1 (0.0 - 0.45): Geometric Logo fade & scale in
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    // Stage 2 (0.35 - 0.75): AEVIQUE wordmark reveal with kerning expansion
    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    );
    _wordmarkSpacing = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    // Stage 3 (0.65 - 1.0): Tagline and Developer Credit soft fade
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOutCubic),
    );
    _creditFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _navigationTimer = Timer(widget.displayDuration, _proceedToNextScreen);
  }

  void _proceedToNextScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen ?? HomeScreen(),
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
      backgroundColor: AeviqueTheme.deepBlack,
      body: Stack(
        children: [
          // Subtle restrained Champagne Gold ambient glow near lower area
          Positioned(
            bottom: -80,
            left: 0,
            right: 0,
            height: 280,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 1.0),
                    radius: 1.2,
                    colors: [
                      AeviqueTheme.champagneGold.withValues(alpha: 0.14),
                      AeviqueTheme.champagneGoldDark.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Center Content: Geometric Logo + Wordmark + Tagline
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stage 1: Geometric Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const AeviqueLogo(size: 88, showGlow: true),
                  ),
                ),
                const SizedBox(height: 28),

                // Stage 2: Brand Wordmark with tracked spacing
                FadeTransition(
                  opacity: _wordmarkFade,
                  child: AnimatedBuilder(
                    animation: _wordmarkSpacing,
                    builder: (context, child) {
                      return Text(
                        'AEVIQUE',
                        style: AeviqueTheme.wordmarkStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: _wordmarkSpacing.value,
                          color: AeviqueTheme.ivory,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Stage 3: Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: const Text(
                    'See Beyond Ordinary.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.2,
                      color: AeviqueTheme.slateGray,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subtle Bottom Developer Credit (Exact spelling: Developed by Mrh Rafi)
          Positioned(
            bottom: 24,
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
                  color: Color(0xFF4A4A58),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
