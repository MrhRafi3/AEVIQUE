import 'package:flutter/material.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_logo.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AeviqueTheme.charcoalSurface,
        title: Text(
          'Privacy & Image Data',
          style: AeviqueTheme.wordmarkStyle(fontSize: 18, letterSpacing: 0.5),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'AEVIQUE operates entirely on-device.\n\n'
            'Your original photos never leave your device, are never uploaded to any remote server or cloud service, and are edited completely offline using local image-processing pipelines.\n\n'
            'We respect your privacy, your photographic work, and your creative ownership.',
            style: TextStyle(
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
                color: AeviqueTheme.champagneGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetPreferences() {
    setState(() {
      _hapticFeedback = true;
      _defaultFormat = 'JPEG';
      _defaultQuality = 92.0;
      _highResPreview = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences restored to factory defaults'),
        backgroundColor: AeviqueTheme.elevatedCharcoal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeviqueTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: AeviqueTheme.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AeviqueTheme.ivory,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SETTINGS',
          style: AeviqueTheme.wordmarkStyle(
            fontSize: 16,
            letterSpacing: 3.0,
            color: AeviqueTheme.ivory,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Section: About AEVIQUE
          _buildAboutCard(),

          const SizedBox(height: 24),
          _buildSectionHeader('IMAGE PIPELINE & EXPORT'),
          const SizedBox(height: 10),

          // Export Format Preference
          _buildCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Default Export Format',
                    style: TextStyle(
                      color: AeviqueTheme.ivory,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _defaultFormat == 'JPEG'
                        ? 'Lossy compression with adjustable quality'
                        : 'Lossless preservation for maximum fidelity',
                    style: const TextStyle(
                      color: AeviqueTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    value: _defaultFormat,
                    dropdownColor: AeviqueTheme.elevatedCharcoal,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AeviqueTheme.champagneGold,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'JPEG',
                        child: Text(
                          'JPEG',
                          style: TextStyle(
                            color: AeviqueTheme.champagneGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'PNG',
                        child: Text(
                          'PNG',
                          style: TextStyle(
                            color: AeviqueTheme.champagneGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _defaultFormat = val);
                    },
                  ),
                ),
                if (_defaultFormat == 'JPEG') ...[
                  const Divider(color: AeviqueTheme.border),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Default JPEG Quality',
                        style: TextStyle(
                          color: AeviqueTheme.ivory,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${_defaultQuality.round()}%',
                        style: const TextStyle(
                          color: AeviqueTheme.champagneGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _defaultQuality,
                    min: 60.0,
                    max: 100.0,
                    divisions: 8,
                    activeColor: AeviqueTheme.champagneGold,
                    inactiveColor: AeviqueTheme.elevatedCharcoal,
                    onChanged: (val) => setState(() => _defaultQuality = val),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('PERFORMANCE & BEHAVIOR'),
          const SizedBox(height: 10),

          _buildCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AeviqueTheme.champagneGold,
                  title: const Text(
                    'High-Precision Preview Cache',
                    style: TextStyle(
                      color: AeviqueTheme.ivory,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Pre-scales preview buffer for lag-free slider response',
                    style: TextStyle(
                      color: AeviqueTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  value: _highResPreview,
                  onChanged: (val) => setState(() => _highResPreview = val),
                ),
                const Divider(color: AeviqueTheme.border),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AeviqueTheme.champagneGold,
                  title: const Text(
                    'Haptic Feedback',
                    style: TextStyle(
                      color: AeviqueTheme.ivory,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Tactile vibrations when adjusting sliders and toggles',
                    style: TextStyle(
                      color: AeviqueTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  value: _hapticFeedback,
                  onChanged: (val) => setState(() => _hapticFeedback = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('APPLICATION & PRIVACY'),
          const SizedBox(height: 10),

          _buildCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.security_rounded,
                    color: AeviqueTheme.champagneGold,
                    size: 20,
                  ),
                  title: const Text(
                    'Privacy Information',
                    style: TextStyle(color: AeviqueTheme.ivory, fontSize: 14),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AeviqueTheme.textMuted,
                    size: 20,
                  ),
                  onTap: _showPrivacyDialog,
                ),
                const Divider(color: AeviqueTheme.border),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.restart_alt_rounded,
                    color: Color(0xFFEF5350),
                    size: 20,
                  ),
                  title: const Text(
                    'Reset All Preferences',
                    style: TextStyle(color: Color(0xFFEF5350), fontSize: 14),
                  ),
                  onTap: _resetPreferences,
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Subtitle Developer Credit at Bottom of Settings
          const Center(
            child: Text(
              'Developed by Mrh Rafi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                color: AeviqueTheme.slateGray,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'AEVIQUE • Version 1.0.0 (Build 1)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF4A4A58),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        color: AeviqueTheme.slateGray,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Material(
      color: AeviqueTheme.charcoalSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AeviqueTheme.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AeviqueTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AeviqueTheme.champagneGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AeviqueTheme.champagneGold.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const AeviqueLogo(size: 64, showGlow: true),
          const SizedBox(height: 16),
          Text(
            'AEVIQUE',
            style: AeviqueTheme.wordmarkStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 4.5,
              color: AeviqueTheme.ivory,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'See Beyond Ordinary.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: AeviqueTheme.champagneGoldLight,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AeviqueTheme.elevatedCharcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AeviqueTheme.champagneGold.withValues(alpha: 0.25),
              ),
            ),
            child: const Text(
              'Professional Photo Editor',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AeviqueTheme.champagneGold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'AEVIQUE is a photo-editing experience built to help you refine colors, enhance details, and express your creative vision.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: AeviqueTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AeviqueTheme.elevatedCharcoal,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AeviqueTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: AeviqueTheme.champagneGold,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Developed by Mrh Rafi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AeviqueTheme.ivory,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
