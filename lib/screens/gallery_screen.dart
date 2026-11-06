import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/image_repository.dart';
import '../services/recent_edits_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/aevique_ui_components.dart';
import 'editor_screen.dart';

class GalleryScreen extends StatefulWidget {
  final ImageRepository imageRepository;
  final RecentEditsRepository recentEditsRepository;
  final VoidCallback? onBackToHome;

  GalleryScreen({
    super.key,
    ImageRepository? imageRepository,
    RecentEditsRepository? recentEditsRepository,
    this.onBackToHome,
  }) : imageRepository = imageRepository ?? DefaultImageRepository(),
       recentEditsRepository =
           recentEditsRepository ?? InMemoryRecentEditsRepository();

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String _selectedCategory = 'All';
  bool _isLoading = false;
  int _selectedSampleIndex = 0; // Default first photo selected

  final List<String> _categories = const [
    'All',
    'Portraits',
    'Landscapes',
    'Architecture',
    'Food',
    'Recent',
  ];

  Future<void> _openPhotoFromBytes(
    Uint8List bytes,
    String name, {
    String? presetId,
  }) async {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          initialImageBytes: bytes,
          imageName: name,
          initialPresetId: presetId,
        ),
      ),
    );
  }

  Future<void> _handleImagePicker(
    Future<Uint8List?> Function() picker,
    String title,
  ) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await picker();
      if (!mounted) return;
      if (bytes != null && bytes.isNotEmpty) {
        _openPhotoFromBytes(bytes, title);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load image: $e'),
          backgroundColor: AeviqueTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSampleAssetTap(SampleImageItem item, int index) async {
    setState(() => _selectedSampleIndex = index);
    HapticFeedback.selectionClick();
    _showPhotoActionsSheet(item);
  }

  void _showPhotoActionsSheet(SampleImageItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPhone2ActionSheet(item),
    );
  }

  Widget _buildPhone2ActionSheet(SampleImageItem item) {
    String selectedFormat = 'Story';

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: AeviqueGlass(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            hasGrabHandle: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aspect Ratio Selector Cards (Phone 2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAspectCard(
                      'Reel',
                      Icons.video_library_outlined,
                      selectedFormat == 'Reel',
                      () {
                        setSheetState(() => selectedFormat = 'Reel');
                      },
                    ),
                    _buildAspectCard(
                      'Story',
                      Icons.crop_portrait_outlined,
                      selectedFormat == 'Story',
                      () {
                        setSheetState(() => selectedFormat = 'Story');
                      },
                    ),
                    _buildAspectCard(
                      'Post',
                      Icons.crop_square_outlined,
                      selectedFormat == 'Post',
                      () {
                        setSheetState(() => selectedFormat = 'Post');
                      },
                    ),
                    _buildAspectCard(
                      'Carousel',
                      Icons.view_carousel_outlined,
                      selectedFormat == 'Carousel',
                      () {
                        setSheetState(() => selectedFormat = 'Carousel');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Sleek Glass Action Rows (Phone 2)
                AeviqueGlassActionRow(
                  icon: Icons.edit_outlined,
                  title: 'Open in Studio Editor',
                  subtitle: item.title,
                  onTap: () async {
                    Navigator.pop(context);
                    final bytes = await widget.imageRepository.loadSampleAsset(
                      item.assetPath,
                    );
                    if (bytes != null && mounted) {
                      _openPhotoFromBytes(bytes, item.title);
                    }
                  },
                ),
                const SizedBox(height: 8),
                AeviqueGlassActionRow(
                  icon: Icons.auto_fix_high_outlined,
                  title: 'Remove background',
                  subtitle: 'Neural portrait cutout',
                  onTap: () async {
                    Navigator.pop(context);
                    final bytes = await widget.imageRepository.loadSampleAsset(
                      item.assetPath,
                    );
                    if (bytes != null && mounted) {
                      _openPhotoFromBytes(bytes, '${item.title} (Cutout)');
                    }
                  },
                ),
                const SizedBox(height: 8),
                AeviqueGlassActionRow(
                  icon: Icons.link_outlined,
                  title: 'Create link in bio',
                  subtitle: 'Export social showcase',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Showcase link copied to clipboard'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AeviqueGlassActionRow(
                  icon: Icons.movie_creation_outlined,
                  title: 'Edit video / motion',
                  subtitle: 'Cinematic crop presets',
                  onTap: () async {
                    Navigator.pop(context);
                    final bytes = await widget.imageRepository.loadSampleAsset(
                      item.assetPath,
                    );
                    if (bytes != null && mounted) {
                      _openPhotoFromBytes(bytes, item.title);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAspectCard(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AeviqueGlass(
        borderRadius: BorderRadius.circular(16),
        showAmberAccent: isSelected,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AeviqueTheme.primaryBlueLight
                  : Colors.white70,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AeviqueTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SampleImageItem> _filterSamples(List<SampleImageItem> all) {
    if (_selectedCategory == 'All') return all;
    if (_selectedCategory == 'Portraits') {
      return all
          .where((s) => s.title.toLowerCase().contains('portrait'))
          .toList();
    }
    if (_selectedCategory == 'Landscapes') {
      return all
          .where(
            (s) =>
                s.title.toLowerCase().contains('landscape') ||
                s.title.toLowerCase().contains('nature'),
          )
          .toList();
    }
    if (_selectedCategory == 'Architecture') {
      return all
          .where((s) => s.title.toLowerCase().contains('architecture'))
          .toList();
    }
    if (_selectedCategory == 'Food') {
      return all.where((s) => s.title.toLowerCase().contains('food')).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final samples = widget.imageRepository.getSampleImages();
    final filteredSamples = _filterSamples(samples);
    final recentEdits = widget.recentEditsRepository.getRecentEdits();
    final showRecentOnly = _selectedCategory == 'Recent';

    return Scaffold(
      backgroundColor: AeviqueTheme.deepBlack,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AeviqueTheme.primaryBlue,
                  strokeWidth: 2.0,
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Minimal Top Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (widget.onBackToHome != null) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  onPressed: widget.onBackToHome,
                                ),
                                const SizedBox(width: 8),
                              ],
                              const Text(
                                'Gallery',
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
                          IconButton(
                            icon: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                            ),
                            tooltip: 'Import from Library',
                            onPressed: () => _handleImagePicker(
                              widget.imageRepository.pickImageFromGallery,
                              'Imported Photo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Compact Category Selector Pills
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return AeviquePillChip(
                            label: cat,
                            isSelected: isSelected,
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // 3. Photography Grid
                  if (showRecentOnly)
                    _buildRecentEditsGrid(recentEdits)
                  else
                    _buildSamplesGrid(filteredSamples),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentEditsGrid(List<RecentEditItem> edits) {
    if (edits.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Text(
              'No recent edits',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AeviqueTheme.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = edits[index];
          return _buildGridCard(
            title: item.name,
            imageWidget: Image.memory(item.imageBytes, fit: BoxFit.cover),
            isSelected: false,
            onTap: () => _openPhotoFromBytes(item.imageBytes, item.name),
          );
        }, childCount: edits.length),
      ),
    );
  }

  Widget _buildSamplesGrid(List<SampleImageItem> samples) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = samples[index];
          final isSelected = index == _selectedSampleIndex;
          return _buildGridCard(
            title: item.title,
            imageWidget: Image.asset(
              item.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                color: const Color(0xFF14141A),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            isSelected: isSelected,
            onTap: () => _handleSampleAssetTap(item, index),
          );
        }, childCount: samples.length),
      ),
    );
  }

  Widget _buildGridCard({
    required String title,
    required Widget imageWidget,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AeviqueTheme.primaryBlue
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.8 : 0.8,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AeviqueTheme.primaryBlueGlow,
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
