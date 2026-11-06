import 'package:flutter/material.dart';
import '../core/native_engine/aevique_ffi.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';

/// Minimal, premium creative Profile screen for AEVIQUE.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nativeEngineActive = AeviqueNativeEngine.isAvailable;

    return Scaffold(
      backgroundColor: AeviqueTheme.deepCanvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            // Top Navigation Bar
            Row(
              children: [
                LiquidGlassPanel(
                  variant: LiquidGlassVariant.ultraClear,
                  borderRadius: BorderRadius.circular(AeviqueTheme.radiusFull),
                  padding: const EdgeInsets.all(10),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Creator Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Profile Header Glass Card
            LiquidGlassPanel(
              variant: LiquidGlassVariant.standard,
              borderRadius: BorderRadius.circular(AeviqueTheme.radiusXl),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar with Liquid Glass Rim & Gradient
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AeviqueTheme.primaryBlue,
                          AeviqueTheme.creativeOrange,
                          AeviqueTheme.coralRed,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AeviqueTheme.primaryBlueGlow,
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AeviqueTheme.deepCanvas,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'AEVIQUE Studio Creator',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Local Creative Workspace · Offline On-Device',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AeviqueTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Studio Capabilities & Metrics
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
              child: Text(
                'STUDIO CAPABILITIES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AeviqueTheme.textSecondary,
                ),
              ),
            ),

            LiquidGlassPanel(
              variant: LiquidGlassVariant.standard,
              borderRadius: BorderRadius.circular(AeviqueTheme.radiusLg),
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  _buildStatRow(
                    icon: Icons.memory_rounded,
                    iconColor: AeviqueTheme.primaryBlueLight,
                    title: 'Native Image Processing Engine',
                    value: nativeEngineActive
                        ? 'C++ Accelerated (v1.2.0)'
                        : 'Dart Engine Mode',
                    isHighlight: nativeEngineActive,
                  ),
                  const Divider(
                    color: AeviqueTheme.glassBorderSubtle,
                    height: 24,
                  ),
                  _buildStatRow(
                    icon: Icons.palette_outlined,
                    iconColor: AeviqueTheme.creativeOrangeLight,
                    title: 'Processing Color Model',
                    value: 'Wide Gamut 32-bit Float',
                  ),
                  const Divider(
                    color: AeviqueTheme.glassBorderSubtle,
                    height: 24,
                  ),
                  _buildStatRow(
                    icon: Icons.security_rounded,
                    iconColor: AeviqueTheme.success,
                    title: 'Privacy & Data Integrity',
                    value: '100% On-Device Offline',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Export & Device Workspace Info
            LiquidGlassPanel(
              variant: LiquidGlassVariant.standard,
              borderRadius: BorderRadius.circular(AeviqueTheme.radiusLg),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AeviqueTheme.creativeOrangeSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AeviqueTheme.creativeOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Master Grade Exporting',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Supports lossless PNG and high-fidelity JPEG exports up to full sensor resolution.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12.5,
                                color: AeviqueTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AeviqueTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isHighlight
                      ? AeviqueTheme.primaryBlueLight
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
