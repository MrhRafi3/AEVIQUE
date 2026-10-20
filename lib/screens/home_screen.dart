import 'package:flutter/material.dart';
import '../services/image_repository.dart';
import '../services/recent_edits_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/aevique_logo.dart';
import 'editor_screen.dart';
import 'presets_screen.dart';
import 'settings_screen.dart';

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
  int _currentNavIndex = 0; // 0: Home, 1: Presets

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
          content: Text('Failed to load photograph: $e'),
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
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentNavIndex == 1) {
      // Functional Presets Screen
      return PresetsScreen(
        imageRepository: widget.imageRepository,
        onBackToHome: () => setState(() => _currentNavIndex = 0),
      );
    }

    // Home Screen View
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
                  // 1. Top Header with Brand Wordmark & Single Settings Icon
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

                  // 2. Editorial Hero Presentation: Large Photographic Preview & Prominent Open Photo CTA
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Container(
                        height: 290,
                        decoration: BoxDecoration(
                          color: AeviqueTheme.charcoalSurface,
                          borderRadius: BorderRadius.circular(22),
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
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Atmospheric photographic background
                            Image.asset(
                              'assets/images/sample.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: AeviqueTheme.charcoalSurface,
                              ),
                            ),
                            // Dark gradient scrim for editorial legibility
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.black.withValues(alpha: 0.88),
                                  ],
                                ),
                              ),
                            ),
                            // Content & Prominent Open Photo Button
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'See Beyond Ordinary.',
                                    style: AeviqueTheme.wordmarkStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: AeviqueTheme.ivory,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Professional color science and portrait retouching.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AeviqueTheme.champagneGoldLight,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Prominent Primary Action: Open Photo
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AeviqueTheme.champagneGold,
                                        foregroundColor: AeviqueTheme.deepBlack,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 20,
                                        color: AeviqueTheme.deepBlack,
                                      ),
                                      label: const Text(
                                        'Open Photo',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: AeviqueTheme.deepBlack,
                                        ),
                                      ),
                                      onPressed: () => _handleImageSelected(
                                        widget
                                            .imageRepository
                                            .pickImageFromGallery,
                                        'Photo',
                                      ),
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

                  // 3. Quick Camera Capture Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
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

                  // 4. Recent Edits Section (Real Edits or Elegant Empty State)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECENT EDITS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: AeviqueTheme.slateGray,
                            ),
                          ),
                          if (widget.recentEditsRepository
                              .getRecentEdits()
                              .isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  widget.recentEditsRepository.clear();
                                });
                              },
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AeviqueTheme.slateGray,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildRecentEditsSection(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Center(
                        child: Text(
                          'Developed by Mrh Rafi',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: AeviqueTheme.slateGray.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
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
              icon: Icon(Icons.filter_vintage_outlined),
              label: 'Presets',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEditsSection() {
    final recentEdits = widget.recentEditsRepository.getRecentEdits();

    if (recentEdits.isEmpty) {
      // Elegant Obsidian Glass Empty State
      return AeviqueGlass(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        showGoldAccent: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AeviqueTheme.champagneGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_mosaic_outlined,
                color: AeviqueTheme.champagneGold,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Studio Canvas Ready',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AeviqueTheme.ivory,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your exported photographs and recent edits will appear here.\nOpen a photo above to begin creating.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AeviqueTheme.slateGray,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentEdits.length,
        itemBuilder: (context, index) {
          final item = recentEdits[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditorScreen(
                      initialImageBytes: item.imageBytes,
                      imageName: item.name,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: AeviqueTheme.charcoalSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AeviqueTheme.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.memory(
                        item.imageBytes,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AeviqueTheme.ivory,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
