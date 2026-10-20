import 'package:flutter/material.dart';
import '../services/image_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_logo.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ImageRepository imageRepository;

  HomeScreen({super.key, ImageRepository? imageRepository})
    : imageRepository = imageRepository ?? DefaultImageRepository();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  int _currentNavIndex = 0;

  Future<void> _handleImageSelected(
    Future<dynamic> Function() fetchBytes,
    String name, {
    String? initialTool,
    String? initialPresetId,
  }) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await fetchBytes();
      if (!mounted) return;
      if (bytes != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditorScreen(
              initialImageBytes: bytes,
              imageName: name,
              initialTool: initialTool,
              initialPresetId: initialPresetId,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image: $e'),
          backgroundColor: const Color(0xFFEF5350),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex && index == 0) return;

    if (index == 1) {
      // Library -> open system photo library
      _handleImageSelected(
        widget.imageRepository.pickImageFromGallery,
        'Photo Library',
      );
    } else if (index == 2) {
      // Presets / Filters -> Open default sample image directly into Filters panel
      final samples = widget.imageRepository.getSampleImages();
      final sample = samples.isNotEmpty ? samples.first : null;
      if (sample != null) {
        _handleImageSelected(
          () => widget.imageRepository.loadSampleAsset(sample.assetPath),
          sample.title,
          initialTool: 'filters',
        );
      } else {
        _handleImageSelected(
          widget.imageRepository.pickImageFromGallery,
          'Selected Photo',
          initialTool: 'filters',
        );
      }
    } else {
      setState(() => _currentNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final samples = widget.imageRepository.getSampleImages();

    return Scaffold(
      backgroundColor: AeviqueTheme.deepBlack,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AeviqueTheme.champagneGold,
                      strokeWidth: 2.5,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Preparing Studio Canvas...',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AeviqueTheme.textSecondary,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // 1. Top Header with Brand Wordmark & Settings
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const AeviqueLogo(size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'AEVIQUE',
                                style: AeviqueTheme.wordmarkStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: AeviqueTheme.ivory,
                              size: 22,
                            ),
                            tooltip: 'Settings & About',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Hero Area: Photographic Presentation Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Container(
                        height: 240,
                        decoration: BoxDecoration(
                          color: AeviqueTheme.charcoalSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AeviqueTheme.champagneGold.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AeviqueTheme.champagneGold.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Hero Background Image with Subtle Vignette
                            Positioned.fill(
                              child: Image.asset(
                                'assets/images/sample.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: AeviqueTheme.charcoalSurface,
                                ),
                              ),
                            ),
                            // Dark Gradient Scrim for readable text
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Transform Your Photos',
                                    style: AeviqueTheme.wordmarkStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: AeviqueTheme.ivory,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Professional tools. Stunning results.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AeviqueTheme.champagneGoldLight,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AeviqueTheme.champagneGold,
                                      foregroundColor: AeviqueTheme.deepBlack,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Start Editing',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    onPressed: () => _handleImageSelected(
                                      widget
                                          .imageRepository
                                          .pickImageFromGallery,
                                      'Photo',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Quick Tools Section (Crop, Adjust, Portrait, Filters, Effects)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUICK TOOLS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AeviqueTheme.slateGray,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildQuickToolItem(
                                  icon: Icons.crop_rounded,
                                  label: 'Crop',
                                  toolId: 'crop',
                                ),
                                const SizedBox(width: 10),
                                _buildQuickToolItem(
                                  icon: Icons.tune_rounded,
                                  label: 'Adjust',
                                  toolId: 'tune',
                                ),
                                const SizedBox(width: 10),
                                _buildQuickToolItem(
                                  icon: Icons.face_retouching_natural_rounded,
                                  label: 'Portrait',
                                  toolId: 'portrait',
                                ),
                                const SizedBox(width: 10),
                                _buildQuickToolItem(
                                  icon: Icons.filter_vintage_rounded,
                                  label: 'Filters',
                                  toolId: 'filters',
                                ),
                                const SizedBox(width: 10),
                                _buildQuickToolItem(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'Effects',
                                  toolId: 'effects',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. Camera Quick Capture Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AeviqueTheme.charcoalSurface,
                          side: const BorderSide(color: AeviqueTheme.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: AeviqueTheme.champagneGold,
                        ),
                        label: const Text(
                          'Open Camera',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AeviqueTheme.ivory,
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
                  ),

                  // 5. Curated Presets Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CURATED PRESETS',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: AeviqueTheme.slateGray,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _onBottomNavTapped(2),
                                child: const Text(
                                  'Explore All',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AeviqueTheme.champagneGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 130,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildCuratedPresetCard(
                                  id: 'vivid',
                                  name: 'Vivid',
                                  subtitle: 'Rich & Natural',
                                  badge: 'POPULAR',
                                  accentColor: const Color(0xFFE5A93C),
                                  samples: samples,
                                ),
                                const SizedBox(width: 12),
                                _buildCuratedPresetCard(
                                  id: 'vivid_warm',
                                  name: 'Vivid Warm',
                                  subtitle: 'Golden Hour',
                                  accentColor: const Color(0xFFD97736),
                                  samples: samples,
                                ),
                                const SizedBox(width: 12),
                                _buildCuratedPresetCard(
                                  id: 'dramatic',
                                  name: 'Dramatic',
                                  subtitle: 'Bold Contrast',
                                  accentColor: const Color(0xFF8B5CF6),
                                  samples: samples,
                                ),
                                const SizedBox(width: 12),
                                _buildCuratedPresetCard(
                                  id: 'mono',
                                  name: 'Mono',
                                  subtitle: 'Pure B&W',
                                  accentColor: const Color(0xFFA1A1AA),
                                  samples: samples,
                                ),
                                const SizedBox(width: 12),
                                _buildCuratedPresetCard(
                                  id: 'noir',
                                  name: 'Noir',
                                  subtitle: 'Crushed Shadows',
                                  accentColor: const Color(0xFF52525B),
                                  samples: samples,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 6. Featured Section (Landscape, Portrait, Architecture, Food, Nature)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: Text(
                        'FEATURED INSPIRATION',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: AeviqueTheme.slateGray,
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = samples[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _handleImageSelected(
                              () => widget.imageRepository.loadSampleAsset(
                                item.assetPath,
                              ),
                              item.title,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AeviqueTheme.charcoalSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AeviqueTheme.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 76,
                                      height: 76,
                                      child: Image.asset(
                                        item.assetPath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            Container(
                                              color:
                                                  AeviqueTheme.elevatedCharcoal,
                                              child: const Icon(
                                                Icons.photo_outlined,
                                                color: AeviqueTheme.textMuted,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AeviqueTheme.ivory,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: AeviqueTheme.textMuted,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AeviqueTheme.champagneGold,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: samples.length),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AeviqueTheme.charcoalSurface,
          border: Border(top: BorderSide(color: AeviqueTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onBottomNavTapped,
          backgroundColor: AeviqueTheme.charcoalSurface,
          selectedItemColor: AeviqueTheme.champagneGold,
          unselectedItemColor: AeviqueTheme.slateGray,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.filter_vintage_outlined),
              label: 'Presets',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuratedPresetCard({
    required String id,
    required String name,
    required String subtitle,
    String? badge,
    required Color accentColor,
    required List<SampleImageItem> samples,
  }) {
    return InkWell(
      onTap: () {
        final sample = samples.isNotEmpty ? samples.first : null;
        if (sample != null) {
          _handleImageSelected(
            () => widget.imageRepository.loadSampleAsset(sample.assetPath),
            sample.title,
            initialTool: 'filters',
            initialPresetId: id,
          );
        } else {
          _handleImageSelected(
            widget.imageRepository.pickImageFromGallery,
            'Photo',
            initialTool: 'filters',
            initialPresetId: id,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AeviqueTheme.charcoalSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.12),
              AeviqueTheme.charcoalSurface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    Icons.filter_vintage_rounded,
                    size: 15,
                    color: accentColor,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AeviqueTheme.champagneGold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AeviqueTheme.deepBlack,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AeviqueTheme.ivory,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AeviqueTheme.slateGray,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToolItem({
    required IconData icon,
    required String label,
    required String toolId,
  }) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: () {
          // Open gallery picker and navigate directly into that tool
          _handleImageSelected(
            widget.imageRepository.pickImageFromGallery,
            'Photo',
            initialTool: toolId,
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AeviqueTheme.charcoalSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AeviqueTheme.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AeviqueTheme.champagneGold),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AeviqueTheme.ivory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
