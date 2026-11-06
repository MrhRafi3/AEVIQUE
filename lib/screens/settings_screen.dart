import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/native_engine/aevique_ffi.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/aevique_logo.dart';
import '../widgets/aevique_ui_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticFeedback = true;
  String _defaultFormat = 'JPEG';
  double _defaultQuality = 92.0;
  bool _highResPreview = true;

  void _showPrivacyDialog() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14141C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AeviqueTheme.borderLight, width: 0.8),
        ),
        title: const Text(
          'Privacy & Image Data',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'AEVIQUE operates entirely on-device.\n\n'
            'Your original photos never leave your device, are never uploaded to any remote server or cloud service, and are edited completely offline using local image-processing pipelines.\n\n'
            'We respect your privacy, your photographic work, and your creative ownership.',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AeviqueTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Understood',
              style: TextStyle(
                color: AeviqueTheme.accentAmberLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nativeLoaded = AeviqueNativeEngine.isAvailable;

    return Scaffold(
      backgroundColor: AeviqueTheme.deepBlack,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Top Navigation Bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Settings',
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
            const SizedBox(height: 16),

            // 1. About AEVIQUE Glass Card
            AeviqueGlass(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const AeviqueLogo(size: 52),
                  const SizedBox(height: 12),
                  Text(
                    'AEVIQUE',
                    style: AeviqueTheme.wordmarkStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'See Beyond Ordinary.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: AeviqueTheme.accentAmberLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AeviqueTheme.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AeviqueTheme.accentAmber.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'Professional Photo Editor',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AeviqueTheme.accentAmber,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'AEVIQUE is a photo-editing experience built to help you refine colors, enhance details, and express your creative vision.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AeviqueTheme.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x66181824),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AeviqueTheme.borderSubtle, width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: AeviqueTheme.accentAmberLight,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Developed by Mrh Rafi',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. Preferences
            const Text(
              'PREFERENCES & EXPORT',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AeviqueTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            AeviqueGlass(
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Default Export Format',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AeviquePillChip(
                            label: 'JPEG',
                            isSelected: _defaultFormat == 'JPEG',
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            onTap: () => setState(() => _defaultFormat = 'JPEG'),
                          ),
                          const SizedBox(width: 6),
                          AeviquePillChip(
                            label: 'PNG',
                            isSelected: _defaultFormat == 'PNG',
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            onTap: () => setState(() => _defaultFormat = 'PNG'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_defaultFormat == 'JPEG') ...[
                    const Divider(color: AeviqueTheme.borderSubtle, height: 20),
                    AeviquePrecisionSlider(
                      label: 'Default JPEG Quality',
                      value: _defaultQuality,
                      min: 50.0,
                      max: 100.0,
                      valueFormatter: (v) => '${v.round()}%',
                      onChanged: (val) => setState(() => _defaultQuality = val),
                    ),
                  ],
                  const Divider(color: AeviqueTheme.borderSubtle, height: 16),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AeviqueTheme.accentAmber,
                      title: const Text(
                        'High-Precision Preview Cache',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                      ),
                      value: _highResPreview,
                      onChanged: (val) => setState(() => _highResPreview = val),
                    ),
                  ),
                  const Divider(color: AeviqueTheme.borderSubtle, height: 16),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AeviqueTheme.accentAmber,
                      title: const Text(
                        'Haptic Feedback',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                      ),
                      value: _hapticFeedback,
                      onChanged: (val) {
                        if (val) HapticFeedback.selectionClick();
                        setState(() => _hapticFeedback = val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Studio Core Engine & Diagnostics
            const Text(
              'ENGINE & DIAGNOSTICS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AeviqueTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            AeviqueGlass(
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDiagnosticRow(
                    'Native Engine Core',
                    nativeLoaded ? 'v1.2.0 (Loaded)' : 'Dart Fallback',
                    isOk: nativeLoaded,
                  ),
                  const Divider(color: AeviqueTheme.borderSubtle, height: 20),
                  _buildDiagnosticRow(
                    'FFI Pipeline ABI',
                    'Active (C++ SIMD)',
                    isOk: true,
                  ),
                  const Divider(color: AeviqueTheme.borderSubtle, height: 20),
                  _buildDiagnosticRow(
                    'Color Formats',
                    'RGBA8888 • RGB888',
                    isOk: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Privacy & Security
            const Text(
              'SECURITY & PRIVACY',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AeviqueTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            AeviqueGlass(
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(16),
              onTap: _showPrivacyDialog,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '100% On-Device Local Privacy',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 18, color: Colors.white54),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 5. Version Subtitle
            const Center(
              child: Text(
                'AEVIQUE Studio • iOS 26 Glass Edition',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AeviqueTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {required bool isOk}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isOk ? AeviqueTheme.success : AeviqueTheme.warning,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOk ? Colors.white70 : AeviqueTheme.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
