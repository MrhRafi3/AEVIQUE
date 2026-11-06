import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../core/image_engine/image_pipeline.dart';
import '../../core/presets/filter_catalogue.dart';
import '../../theme/aevique_theme.dart';
import '../aevique_ui_components.dart';

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

    Future.microtask(() async {
      for (final filter in FilterCatalogue.allFilters) {
        if (!mounted) return;
        if (filter.id == 'original') continue;
        if (_thumbCache.containsKey(filter.id)) continue;

        await Future<void>.value();
        if (!mounted) return;

        final processed = ImagePipeline.processRawImage(base, filter.state);
        final encoded = Uint8List.fromList(img.encodeJpg(processed, quality: 75));
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
    final filters = FilterCatalogue.allFilters.where((f) => f.id != 'original').toList();
    final isFilterActive = widget.activeFilterId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Intensity Slider (Visible when a filter is active)
        if (isFilterActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: AeviquePrecisionSlider(
              label: 'Intensity',
              value: widget.filterIntensity,
              min: 0.0,
              max: 100.0,
              valueFormatter: (v) => '${v.round()}%',
              onChanged: widget.onIntensityChanged,
              onReset: () => widget.onIntensityChanged(100.0),
            ),
          ),

        // 2. Horizontal Filter Preset Cards Carousel (Phone 4)
        SizedBox(
          height: 110,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length + 1, // +1 for "Original / None"
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = widget.activeFilterId == null;
                return _buildFilterThumbnailCard(
                  name: 'Original',
                  imageBytes: null,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onClearFilter();
                  },
                );
              }

              final filter = filters[index - 1];
              final isSelected = widget.activeFilterId == filter.id;
              final cachedBytes = _thumbCache[filter.id];

              return _buildFilterThumbnailCard(
                name: filter.name,
                imageBytes: cachedBytes,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onFilterSelected(filter, widget.filterIntensity);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterThumbnailCard({
    required String name,
    required Uint8List? imageBytes,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AeviqueTheme.accentAmber : Colors.white.withValues(alpha: 0.12),
                width: isSelected ? 1.8 : 0.8,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AeviqueTheme.accentAmber.withValues(alpha: 0.35),
                    blurRadius: 12,
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: imageBytes != null
                ? Image.memory(imageBytes, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF1E1E28),
                    child: Center(
                      child: Icon(
                        Icons.filter_hdr_outlined,
                        size: 24,
                        color: isSelected ? AeviqueTheme.accentAmberLight : Colors.white38,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AeviqueTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
