import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_repository.dart';
import '../services/recent_edits_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/liquid_glass_components.dart';
import '../widgets/motion/abstract_3d_graphics.dart';
import 'camera_screen.dart';
import 'editor_screen.dart';
import 'gallery_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// AEVIQUE Minimal Home Screen.
///
/// Features ONLY the four required main elements:
/// 1. Start Editing (Primary Action — opens system image picker / gallery into Editor)
/// 2. Open Camera (Real live camera viewfinder & capture into Editor)
/// 3. Profile (Creator workspace & system capabilities)
/// 4. Settings (Clean, organized preferences & engine status)
///
/// Anchored by continuous, high-performance Abstract 3D Motion Graphics.
class HomeScreen extends StatefulWidget {
  final ImageRepository imageRepository;
  final RecentEditsRepository recentEditsRepository;

  HomeScreen({
    super.key,
    ImageRepository? imageRepository,
    RecentEditsRepository? recentEditsRepository,
  }) : imageRepository = imageRepository ?? DefaultImageRepository(),
       recentEditsRepository =
           recentEditsRepository ?? InMemoryRecentEditsRepository();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  Future<void> _handleStartEditing() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      // Pick image from device gallery
      final bytes = await widget.imageRepository.pickImageFromGallery();
      if (!mounted) return;

      if (bytes != null && bytes.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditorScreen(
              initialImageBytes: bytes,
              imageName: 'Photo_${DateTime.now().millisecondsSinceEpoch}',
            ),
          ),
        );
      } else {
        // If system picker was cancelled or empty on desktop, allow browsing sample gallery
        _openGalleryScreen();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image: $e'),
          backgroundColor: AeviqueTheme.coralRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openGalleryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GalleryScreen(
          imageRepository: widget.imageRepository,
          recentEditsRepository: widget.recentEditsRepository,
          onBackToHome: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _handleOpenCamera() {
    HapticFeedback.mediumImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CameraScreen()));
  }

  void _handleOpenProfile() {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }

  void _handleOpenSettings() {
    HapticFeedback.selectionClick();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeviqueTheme.deepCanvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Apple-inspired Abstract 3D Motion Graphics
          const Positioned.fill(child: Abstract3DMotionGraphics()),

          // 2. Subtle Dark Studio Vignette Overlay to guarantee text contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    AeviqueTheme.deepCanvas.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),

          // 3. UI Overlay Layer: Top Bar, Center Wordmark, Bottom Actions
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth < 360 ? 12.0 : 20.0,
                          vertical: 14.0,
                        ),
                        child: Column(
                          children: [
                            // --- TOP BAR: Profile (Element C) & Settings (Element D) ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Profile Entry Point
                                LiquidGlassPanel(
                                  variant: LiquidGlassVariant.ultraClear,
                                  borderRadius: BorderRadius.circular(
                                    AeviqueTheme.radiusFull,
                                  ),
                                  blur: 24.0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  onTap: _handleOpenProfile,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Profile',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Settings Entry Point
                                LiquidGlassPanel(
                                  variant: LiquidGlassVariant.ultraClear,
                                  borderRadius: BorderRadius.circular(
                                    AeviqueTheme.radiusFull,
                                  ),
                                  blur: 24.0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  onTap: _handleOpenSettings,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Settings',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(flex: 2),

                            // --- CENTER: Minimal AEVIQUE Branding ---
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Liquid Glass Brand Mark Pill
                                LiquidGlassPanel(
                                  variant: LiquidGlassVariant.ultraClear,
                                  borderRadius: BorderRadius.circular(
                                    AeviqueTheme.radiusFull,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AeviqueTheme.primaryBlueLight,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'CREATIVE PHOTO ENGINE',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                            color: AeviqueTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Primary Wordmark
                                Text(
                                  'AEVIQUE',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 44,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 8.0,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                      Shadow(
                                        color: AeviqueTheme.primaryBlueGlow,
                                        blurRadius: 32,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 8),

                                const Text(
                                  'Transparent Optical Glass · On-Device Precision',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.2,
                                    color: AeviqueTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(flex: 3),

                            // --- BOTTOM: Start Editing (Element A) & Open Camera (Element B) ---
                            LiquidGlassPanel(
                              variant: LiquidGlassVariant.standard,
                              borderRadius: BorderRadius.circular(
                                AeviqueTheme.radiusXl,
                              ),
                              blur: 28.0,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Primary Action: Start Editing
                                  LiquidGlassButton(
                                    label: 'Start Editing',
                                    icon: Icons.add_photo_alternate_rounded,
                                    variant:
                                        LiquidGlassButtonVariant.primaryBlue,
                                    height: 56.0,
                                    isLoading: _isLoading,
                                    onPressed: _handleStartEditing,
                                  ),

                                  const SizedBox(height: 12),

                                  // Secondary Action: Open Camera & Gallery
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LiquidGlassButton(
                                          label: 'Open Camera',
                                          icon: Icons.camera_alt_rounded,
                                          variant: LiquidGlassButtonVariant
                                              .creativeOrange,
                                          height: 50.0,
                                          onPressed: _handleOpenCamera,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Quick Sample Gallery Browse Access
                                      LiquidGlassPanel(
                                        variant: LiquidGlassVariant.ultraClear,
                                        borderRadius: BorderRadius.circular(
                                          AeviqueTheme.radiusLg,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 13.0,
                                        ),
                                        onTap: _openGalleryScreen,
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.photo_library_outlined,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Gallery',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
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

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
