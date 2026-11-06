import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../core/image_engine/image_pipeline.dart';
import '../core/presets/filter_catalogue.dart';
import '../services/image_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_ui_components.dart';
import 'editor_screen.dart';

class PresetsScreen extends StatefulWidget {
  final ImageRepository imageRepository;
  final VoidCallback? onBackToHome;

  PresetsScreen({
    super.key,
    ImageRepository? imageRepository,
    this.onBackToHome,
  }) : imageRepository = imageRepository ?? DefaultImageRepository();

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  static const String _defaultDemoAsset = 'assets/images/sample_portrait.jpg';

  Uint8List? _sourceImageBytes;
  img.Image? _basePreviewImage;
  img.Image? _thumbnailImage;
  Uint8List? _originalPreviewBytes;
  Uint8List? _displayedPreviewBytes;

  String _imageTitle = 'Studio Portrait';
  bool _isUserPhoto = false;
  bool _isLoadingImage = true;
  bool _isRenderingPreset = false;

  String _selectedPresetId = 'original';
  double _presetIntensity = 100.0;
  bool _isComparingOriginal = false;

  final Map<String, Uint8List> _thumbCache = {};
  Timer? _renderDebounce;
  int _renderRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialDemoPhoto();
  }

  @override
  void dispose() {
    _renderDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialDemoPhoto() async {
    setState(() => _isLoadingImage = true);
    try {
      final bytes = await widget.imageRepository.loadSampleAsset(
        _defaultDemoAsset,
      );
      if (bytes != null && bytes.isNotEmpty) {
        await _setupImageBundle(
          bytes: bytes,
          title: 'Studio Portrait',
          isUserPhoto: false,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  Future<void> _setupImageBundle({
    required Uint8List bytes,
    required String title,
    required bool isUserPhoto,
  }) async {
    try {
      final bundle = await ImagePipeline.prepareImageBundle(
        bytes,
        maxPreviewDimension: 1200,
        thumbnailDimension: 80,
      );

      if (!mounted) return;
      setState(() {
        _sourceImageBytes = bytes;
        _imageTitle = title;
        _isUserPhoto = isUserPhoto;
        _basePreviewImage = bundle.previewImage;
        _thumbnailImage = bundle.thumbnailImage;
        _originalPreviewBytes = bundle.originalPreviewBytes;
        _displayedPreviewBytes = bundle.originalPreviewBytes;
        _thumbCache.clear();
        _isLoadingImage = false;
      });

      _generateFilterThumbnails();

      if (_selectedPresetId != 'original') {
        _renderSelectedPreset();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  void _generateFilterThumbnails() {
    final baseThumb = _thumbnailImage;
    if (baseThumb == null) return;

    Future.microtask(() async {
      for (final filter in FilterCatalogue.allFilters) {
        if (!mounted) return;
        if (filter.id == 'original') continue;
        if (_thumbCache.containsKey(filter.id)) continue;

        await Future<void>.value();
        if (!mounted) return;

        final processed = ImagePipeline.processRawImage(
          baseThumb,
          filter.state,
        );
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

  void _onSelectPreset(String filterId) {
    if (_selectedPresetId == filterId) return;

    HapticFeedback.selectionClick();
    setState(() {
      _selectedPresetId = filterId;
      if (filterId == 'original') {
        _displayedPreviewBytes = _originalPreviewBytes;
      }
    });

    if (filterId != 'original') {
      _renderSelectedPreset();
    }
  }

  void _onIntensityChanged(double newIntensity) {
    setState(() => _presetIntensity = newIntensity);
    _renderDebounce?.cancel();
    _renderDebounce = Timer(const Duration(milliseconds: 30), () {
      _renderSelectedPreset();
    });
  }

  void _renderSelectedPreset() async {
    final base = _basePreviewImage;
    if (base == null) return;

    if (_selectedPresetId == 'original') {
      setState(() => _displayedPreviewBytes = _originalPreviewBytes);
      return;
    }

    final filter = FilterCatalogue.findById(_selectedPresetId);
    if (filter == null) return;

    final requestId = ++_renderRequestId;
    setState(() => _isRenderingPreset = true);

    try {
      final blendedState = filter.blendWithNeutral(_presetIntensity);
      final rendered = await ImagePipeline.processPreviewFast(
        base,
        blendedState,
        jpegQuality: 88,
      );

      if (!mounted || requestId != _renderRequestId) return;
      setState(() {
        _displayedPreviewBytes = rendered;
        _isRenderingPreset = false;
      });
    } catch (_) {
      if (!mounted || requestId != _renderRequestId) return;
      setState(() => _isRenderingPreset = false);
    }
  }

  Future<void> _handleTryOnMyPhoto() async {
    try {
      final pickedBytes = await widget.imageRepository.pickImageFromGallery();
      if (!mounted || pickedBytes == null) return;

      HapticFeedback.lightImpact();
      setState(() => _isLoadingImage = true);
      await _setupImageBundle(
        bytes: pickedBytes,
        title: 'My Photograph',
        isUserPhoto: true,
      );
    } catch (_) {}
  }

  void _handleContinueEditing() {
    final imageBytes = _sourceImageBytes;
    if (imageBytes == null) return;

    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          initialImageBytes: imageBytes,
          imageName: _imageTitle,
          initialPresetId: _selectedPresetId != 'original'
              ? _selectedPresetId
              : null,
          initialTool: _selectedPresetId != 'original' ? 'filters' : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = FilterCatalogue.allFilters;
    final isPresetActive = _selectedPresetId != 'original';

    return Scaffold(
      backgroundColor: AeviqueTheme.deepBlack,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Minimal Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(width: 4),
                        ],
                        const Flexible(
                          child: Text(
                            'PRESETS & STYLES',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x66181824),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isUserPhoto
                            ? AeviqueTheme.primaryBlue
                            : AeviqueTheme.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _isUserPhoto ? 'My Photo' : 'Studio Demo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _isUserPhoto
                            ? AeviqueTheme.primaryBlueLight
                            : AeviqueTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Large Photographic Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _buildMainPreview(),
              ),
            ),

            // 3. Preset Intensity Slider
            if (isPresetActive)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: AeviquePrecisionSlider(
                  label: 'Intensity',
                  value: _presetIntensity,
                  min: 0.0,
                  max: 100.0,
                  valueFormatter: (v) => '${v.round()}%',
                  onChanged: _onIntensityChanged,
                  onReset: () => _onIntensityChanged(100.0),
                ),
              ),

            // 4. Horizontal Preset Carousel
            SizedBox(
              height: 106,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                itemCount: filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _selectedPresetId == filter.id;
                  final isOriginal = filter.id == 'original';
                  final thumbBytes = isOriginal
                      ? (_thumbnailImage != null
                            ? Uint8List.fromList(
                                img.encodeJpg(_thumbnailImage!, quality: 75),
                              )
                            : null)
                      : _thumbCache[filter.id];

                  return GestureDetector(
                    onTap: () => _onSelectPreset(filter.id),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AeviqueTheme.primaryBlue
                                  : Colors.white.withValues(alpha: 0.12),
                              width: isSelected ? 1.8 : 0.8,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: AeviqueTheme.primaryBlueGlow,
                                  blurRadius: 12,
                                ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: thumbBytes != null
                              ? Image.memory(thumbBytes, fit: BoxFit.cover)
                              : Container(
                                  color: const Color(0xFF181822),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 20,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 68,
                          child: Text(
                            filter.name,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AeviqueTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 5. Bottom Actions Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: AeviqueButton.secondary(
                      icon: Icons.add_photo_alternate_outlined,
                      label: 'Try on My Photo',
                      onPressed: _handleTryOnMyPhoto,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AeviqueButton(
                      icon: Icons.tune_rounded,
                      label: 'Edit Photo',
                      onPressed: _handleContinueEditing,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPreview() {
    if (_isLoadingImage) {
      return const Center(
        child: CircularProgressIndicator(
          color: AeviqueTheme.primaryBlue,
          strokeWidth: 2.0,
        ),
      );
    }

    final bytesToDisplay = _isComparingOriginal
        ? _originalPreviewBytes
        : (_displayedPreviewBytes ?? _originalPreviewBytes);

    if (bytesToDisplay == null || bytesToDisplay.isEmpty) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.white24,
        ),
      );
    }

    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isComparingOriginal = true);
      },
      onLongPressEnd: (_) => setState(() => _isComparingOriginal = false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 28,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytesToDisplay, fit: BoxFit.contain),
            if (_isRenderingPreset)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AeviqueTheme.primaryBlueLight,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'RENDERING',
                        style: TextStyle(fontSize: 9, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isComparingOriginal)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: const Text(
                    'ORIGINAL',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
