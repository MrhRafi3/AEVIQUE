import 'package:flutter/material.dart';
import '../services/image_repository.dart';
import '../theme/luma_theme.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  final ImageRepository imageRepository;

  HomeScreen({super.key, ImageRepository? imageRepository})
    : imageRepository = imageRepository ?? DefaultImageRepository();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  Future<void> _handleImageSelected(
    Future<dynamic> Function() fetchBytes,
    String name,
  ) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await fetchBytes();
      if (!mounted) return;
      if (bytes != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                EditorScreen(initialImageBytes: bytes, imageName: name),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final samples = widget.imageRepository.getSampleImages();

    return Scaffold(
      backgroundColor: LumaTheme.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: LumaTheme.accent),
                    SizedBox(height: 16),
                    Text(
                      'Loading Image...',
                      style: TextStyle(
                        color: LumaTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // App Bar Branding
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: LumaTheme.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                  color: LumaTheme.background,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'LUMA FORGE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.5,
                                  color: LumaTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Precision Mobile Photo Studio',
                            style: TextStyle(
                              fontSize: 13,
                              color: LumaTheme.textSecondary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hero Action: Open Photo
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: GestureDetector(
                        onTap: () => _handleImageSelected(
                          widget.imageRepository.pickImageFromGallery,
                          'Gallery Photo',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 36,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: LumaTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: LumaTheme.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: LumaTheme.surfaceElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: LumaTheme.accent.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: LumaTheme.accent,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Open Photo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: LumaTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Select high-resolution photo from device',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LumaTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Camera Quick Action
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: LumaTheme.surfaceElevated,
                                side: const BorderSide(color: LumaTheme.border),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                                color: LumaTheme.textPrimary,
                              ),
                              label: const Text(
                                'Camera',
                                style: TextStyle(
                                  color: LumaTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => _handleImageSelected(
                                widget.imageRepository.pickImageFromCamera,
                                'Camera Capture',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sample Photos Header
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: Text(
                        'Sample Studio Photos',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: LumaTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // Sample Photos List
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final sample = samples[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _handleImageSelected(
                            () => widget.imageRepository.loadSampleAsset(
                              sample.assetPath,
                            ),
                            sample.title,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: LumaTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: LumaTheme.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: LumaTheme.surfaceHighlight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: LumaTheme.accent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sample.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: LumaTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sample.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: LumaTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: LumaTheme.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: samples.length),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }
}
