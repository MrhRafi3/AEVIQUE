import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_repository.dart';
import '../services/recent_edits_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_ui_components.dart';
import 'editor_screen.dart';
import 'gallery_screen.dart';
import 'presets_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ImageRepository imageRepository;
  final RecentEditsRepository recentEditsRepository;

  HomeScreen({
    super.key,
    ImageRepository? imageRepository,
    RecentEditsRepository? recentEditsRepository,
  })  : imageRepository = imageRepository ?? DefaultImageRepository(),
        recentEditsRepository =
            recentEditsRepository ?? InMemoryRecentEditsRepository();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  int _currentNavIndex = 0; // 0: Home, 1: Gallery, 2: Presets/Editor, 3: Settings
  int _selectedCategoryIndex = 2; // Default "Vintage" selected like Phone 1 in reference

  final List<String> _categories = const [
    'Reel',
    'Post',
    'Vintage',
    'Classic',
    'Travel',
    'Portrait',
  ];

  final List<Map<String, String>> _templates = const [
    {
      'title': 'Year in\nReview',
      'tag': '(06)',
      'author': 'by Gijack.en',
      'asset': 'assets/images/sample_portrait.jpg',
      'presetId': 'vintage_70s',
    },
    {
      'title': 'Golden\nHour',
      'tag': '(04)',
      'author': 'by Studio.aev',
      'asset': 'assets/images/sample_nature.jpg',
      'presetId': 'warm_glow',
    },
    {
      'title': 'Year in\nReview',
      'tag': '(06)',
      'author': 'by Gijack.en',
      'asset': 'assets/images/sample_portrait.jpg',
      'presetId': 'vintage_70s',
    },
    {
      'title': 'Modern\nCinema',
      'tag': '(12)',
      'author': 'by Alex.m',
      'asset': 'assets/images/sample_architecture.jpg',
      'presetId': 'cinematic_teal',
    },
  ];

  Future<void> _openPhotograph(
    Future<dynamic> Function() fetchBytes,
    String name, {
    String? initialTool,
    String? initialPresetId,
  }) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await fetchBytes();
      if (!mounted) return;
      if (bytes != null && (bytes as Uint8List).isNotEmpty) {
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
          content: Text('Failed to load photograph: $e'),
          backgroundColor: AeviqueTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;
    HapticFeedback.selectionClick();
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
      return;
    }
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentNavIndex == 1) {
      return GalleryScreen(
        imageRepository: widget.imageRepository,
        recentEditsRepository: widget.recentEditsRepository,
        onBackToHome: () => setState(() => _currentNavIndex = 0),
      );
    }

    if (_currentNavIndex == 2) {
      return PresetsScreen(
        imageRepository: widget.imageRepository,
        onBackToHome: () => setState(() => _currentNavIndex = 0),
      );
    }

    return Scaffold(
      backgroundColor: AeviqueTheme.deepBlack,
      body: Stack(
        children: [
          // Background subtle ambient lighting
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            height: 350,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.4),
                    radius: 1.0,
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.01),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AeviqueTheme.accentAmber,
                      strokeWidth: 2.0,
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 768;

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // 1. Top Bar: "Explore templates" centered (Phone 1)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Text(
                                    'Explore templates',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Colors.white70,
                                        size: 22,
                                      ),
                                      tooltip: 'Open from Gallery',
                                      onPressed: () {
                                        _openPhotograph(
                                          widget.imageRepository.pickImageFromGallery,
                                          'Selected Photo',
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 2. Horizontally scrolling Category Pills (Phone 1)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 38,
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 48 : 20,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final isSelected = index == _selectedCategoryIndex;
                                  return AeviquePillChip(
                                    label: cat,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() => _selectedCategoryIndex = index);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 20)),

                          // 3. Main Showcase Card (Phone 1: "Year in Review", (06), by Gijack.en, Amber FAB)
                          SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isDesktop ? 600 : double.infinity,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 32 : 20,
                                  ),
                                  child: _buildShowcaseCard(context, constraints),
                                ),
                              ),
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 120)),
                        ],
                      );
                    },
                  ),
          ),

          // 4. Floating Frosted Glass Bottom Navigation Dock (Phone 1)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Center(
                child: AeviqueFloatingDock(
                  width: 280,
                  children: [
                    _buildDockIcon(
                      icon: Icons.star_rounded,
                      index: 0,
                      label: 'Featured',
                    ),
                    _buildDockIcon(
                      icon: Icons.grid_view_rounded,
                      index: 1,
                      label: 'Gallery',
                    ),
                    _buildDockIcon(
                      icon: Icons.tune_rounded,
                      index: 2,
                      label: 'Presets',
                    ),
                    _buildDockIcon(
                      icon: Icons.person_outline_rounded,
                      index: 3,
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowcaseCard(BuildContext context, BoxConstraints constraints) {
    final template = _templates[_selectedCategoryIndex % _templates.length];
    final isDesktop = constraints.maxWidth >= 768;
    final cardHeight = isDesktop ? 520.0 : 480.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openPhotograph(
          () => widget.imageRepository.loadSampleAsset(template['asset']!),
          template['title']!.replaceAll('\n', ' '),
          initialPresetId: template['presetId'],
        );
      },
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo filling card
              Image.asset(
                template['asset']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF161620),
                  child: const Center(
                    child: Icon(Icons.image, size: 48, color: Colors.white24),
                  ),
                ),
              ),

              // Smooth glass dark gradient overlays
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.25, 0.65, 1.0],
                  ),
                ),
              ),

              // Thin specular border inside card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
              ),

              // Top details: "(06)" badge top right
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    template['tag']!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

              // Top title: "Year in\nReview" (bold clean sans-serif)
              Positioned(
                top: 24,
                left: 24,
                child: Text(
                  template['title']!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // Bottom left: "by Gijack.en"
              Positioned(
                bottom: 28,
                left: 24,
                child: Text(
                  template['author']!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Bottom right: Amber Floating Action Button "+" with warm bloom
              Positioned(
                bottom: 22,
                right: 22,
                child: AeviqueAmberFab(
                  icon: Icons.add,
                  size: 50,
                  iconSize: 26,
                  onPressed: () {
                    _openPhotograph(
                      () => widget.imageRepository.loadSampleAsset(template['asset']!),
                      template['title']!.replaceAll('\n', ' '),
                      initialPresetId: template['presetId'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockIcon({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;

    return GestureDetector(
      onTap: () => _onBottomNavTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AeviqueTheme.accentAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? AeviqueTheme.accentAmberLight : AeviqueTheme.textSecondary,
        ),
      ),
    );
  }
}
