import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../core/image_engine/image_pipeline.dart';
import '../../core/presets/filter_catalogue.dart';
import '../../theme/luma_theme.dart';
import '../luma_slider.dart';

class FiltersPanel extends StatefulWidget {
  final String? activeFilterId;
  final double filterIntensity;
  final img.Image? thumbnailBase;
  final Function(LumaFilter filter, double intensity) onFilterSelected;
  final ValueChanged<double> onIntensityChanged;
  final VoidCallback onClearFilter;

  const FiltersPanel({
    super.key,
    required this.activeFilterId,
    required this.filterIntensity,
    this.thumbnailBase,
    required this.onFilterSelected,
    required this.onIntensityChanged,
    required this.onClearFilter,
  });

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  FilterCategory _selectedCategory = FilterCategory.all;
  final Map<String, Uint8List> _thumbCache = {};

  @override
  void initState() {
    super.initState();
    _generateThumbnails();
  }

  @override
  void didUpdateWidget(covariant FiltersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thumbnailBase != oldWidget.thumbnailBase) {
      _thumbCache.clear();
      _generateThumbnails();
    }
  }

  void _generateThumbnails() {
    final base = widget.thumbnailBase;
    if (base == null) return;

    // Asynchronously generate thumbnails so the UI remains fluid
    Future.microtask(() async {
      for (final filter in FilterCatalogue.allFilters) {
        if (!mounted) return;
        if (filter.id == 'original') continue;
        if (_thumbCache.containsKey(filter.id)) continue;

        // Yield between filters to preserve 60/120fps frame rendering
        await Future<void>.delayed(Duration.zero);
        if (!mounted) return;

        final processed = ImagePipeline.processRawImage(base, filter.state);
        final encoded = Uint8List.fromList(
          img.encodeJpg(processed, quality: 75),
        );
        if (mounted) {
          setState(() {
            _thumbCache[filter.id] = encoded;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCategoryFilters = FilterCatalogue.getByCategory(_selectedCategory);
    final filters = allCategoryFilters
        .where((f) => f.id != 'original')
        .toList();
    final isFilterActive = widget.activeFilterId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Intensity Slider (Visible when any filter is selected)
        if (isFilterActive) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: LumaSlider(
              title: 'Filter Intensity',
              value: widget.filterIntensity,
              min: 0.0,
              max: 100.0,
              unit: '%',
              onChanged: widget.onIntensityChanged,
            ),
          ),
          const Divider(color: LumaTheme.border, height: 1),
        ],

        // Category Navigation Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(FilterCategory.all, 'All'),
                const SizedBox(width: 6),
                _buildCategoryChip(FilterCategory.vivid, 'Vivid'),
                const SizedBox(width: 6),
                _buildCategoryChip(FilterCategory.dramatic, 'Dramatic'),
                const SizedBox(width: 6),
                _buildCategoryChip(FilterCategory.bw, 'B&W'),
              ],
            ),
          ),
        ),

        // Horizontal Filter Cards Carousel
        SizedBox(
          height: 125,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length + 1, // +1 for "Original" card
            itemBuilder: (context, index) {
              if (index == 0) {
                // Original / No Filter Card
                final isOriginal = widget.activeFilterId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: GestureDetector(
                    onTap: widget.onClearFilter,
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: isOriginal
                            ? LumaTheme.surfaceHighlight
                            : LumaTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOriginal
                              ? LumaTheme.accent
                              : LumaTheme.border,
                          width: isOriginal ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: LumaTheme.surfaceElevated,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isOriginal
                                    ? LumaTheme.accent
                                    : LumaTheme.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.raw_on_rounded,
                              size: 22,
                              color: isOriginal
                                  ? LumaTheme.accent
                                  : LumaTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Original',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isOriginal
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isOriginal
                                  ? LumaTheme.accent
                                  : LumaTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'No Filter',
                            style: TextStyle(
                              fontSize: 9,
                              color: LumaTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final filter = filters[index - 1];
              final isSelected = widget.activeFilterId == filter.id;
              final thumbBytes = _thumbCache[filter.id];

              return Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: GestureDetector(
                  onTap: () =>
                      widget.onFilterSelected(filter, widget.filterIntensity),
                  child: Container(
                    width: 92,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? LumaTheme.accent.withValues(alpha: 0.15)
                          : LumaTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? LumaTheme.accent : LumaTheme.border,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Live Thumbnail image
                        Expanded(
                          child: thumbBytes != null
                              ? Image.memory(thumbBytes, fit: BoxFit.cover)
                              : Container(
                                  color: LumaTheme.surfaceElevated,
                                  child: const Center(
                                    child: Icon(
                                      Icons.photo_filter_rounded,
                                      size: 22,
                                      color: LumaTheme.textMuted,
                                    ),
                                  ),
                                ),
                        ),
                        // Filter Name
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          color: isSelected
                              ? LumaTheme.surfaceElevated
                              : LumaTheme.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                filter.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? LumaTheme.accent
                                      : LumaTheme.textPrimary,
                                ),
                              ),
                              if (isSelected)
                                Text(
                                  '${widget.filterIntensity.round()}%',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: LumaTheme.accent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCategoryChip(FilterCategory category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? LumaTheme.accent.withValues(alpha: 0.2)
              : LumaTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? LumaTheme.accent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? LumaTheme.accent : LumaTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
