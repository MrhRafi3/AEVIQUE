import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../core/image_engine/image_pipeline.dart';
import '../core/presets/filter_catalogue.dart';
import '../services/image_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
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
  String? _errorMessage;

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
    setState(() {
      _isLoadingImage = true;
      _errorMessage = null;
    });

    try {
      final bytes = await widget.imageRepository.loadSampleAsset(
        _defaultDemoAsset,
      );
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Unable to load bundled sample asset.');
      }
      await _setupImageBundle(
        bytes: bytes,
        title: 'Studio Portrait',
        isUserPhoto: false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingImage = false;
        _errorMessage = 'Failed to load demo photograph: $e';
      });
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
        _errorMessage = null;
      });

      _generateFilterThumbnails();

      // If a non-original preset was already selected, render it on the new photo
      if (_selectedPresetId != 'original') {
        _renderSelectedPreset();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingImage = false;
        _errorMessage = 'Failed to prepare image canvas: $e';
      });
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

    setState(() {
      _selectedPresetId = filterId;
    });

    if (filterId == 'original') {
      setState(() {
        _displayedPreviewBytes = _originalPreviewBytes;
        _isRenderingPreset = false;
      });
      return;
    }

    _renderSelectedPreset();
  }

  void _onIntensityChanged(double newIntensity) {
    setState(() {
      _presetIntensity = newIntensity;
    });

    if (_selectedPresetId == 'original') return;

    _renderDebounce?.cancel();
    _renderDebounce = Timer(const Duration(milliseconds: 30), () {
      _renderSelectedPreset();
    });
  }

  Future<void> _renderSelectedPreset() async {
    final base = _basePreviewImage;
    if (base == null) return;

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
      if (!mounted) return;

      if (pickedBytes == null) {
        // User cancelled photo selection: preserve current session
        return;
      }

      setState(() => _isLoadingImage = true);
      await _setupImageBundle(
        bytes: pickedBytes,
        title: 'My Photo',
        isUserPhoto: true,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open selected image: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _handleContinueEditing() {
    final imageBytes = _sourceImageBytes;
    if (imageBytes == null) return;

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
            // 1. Header Bar: Title + Context Badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.onBackToHome != null) ...[
                        IconButton(
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(28, 28),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AeviqueTheme.ivory,
                          ),
                          onPressed: widget.onBackToHome,
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Text(
                        'PRESETS & STYLES',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: AeviqueTheme.champagneGold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isUserPhoto
                          ? AeviqueTheme.champagneGold.withValues(alpha: 0.16)
                          : AeviqueTheme.charcoalSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isUserPhoto
                            ? AeviqueTheme.champagneGold
                            : AeviqueTheme.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _isUserPhoto ? 'My Photo' : 'Demo Photo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _isUserPhoto
                            ? AeviqueTheme.champagneGold
                            : AeviqueTheme.slateGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Main Large Photographic Preview Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: _buildMainPreview(),
              ),
            ),

            // 3. Preset Intensity Slider (Only when a non-original preset is selected)
            if (isPresetActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                child: Row(
                  children: [
                    const Text(
                      'Intensity',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AeviqueTheme.slateGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AeviqueTheme.champagneGold,
                          inactiveTrackColor: AeviqueTheme.border,
                          thumbColor: AeviqueTheme.champagneGold,
                          trackHeight: 2.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _presetIntensity,
                          min: 0.0,
                          max: 100.0,
                          onChanged: _onIntensityChanged,
                        ),
                      ),
                    ),
                    Text(
                      '${_presetIntensity.round()}%',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AeviqueTheme.champagneGold,
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Horizontal Filmstrip of Filter Thumbnails
            Container(
              height: 118,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = _selectedPresetId == filter.id;
                  final isOriginal = filter.id == 'original';
                  final thumbBytes = isOriginal
                      ? _thumbnailImage != null
                            ? Uint8List.fromList(
                                img.encodeJpg(_thumbnailImage!, quality: 75),
                              )
                            : null
                      : _thumbCache[filter.id];

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => _onSelectPreset(filter.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 82,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AeviqueTheme.champagneGold.withValues(
                                  alpha: 0.16,
                                )
                              : AeviqueTheme.charcoalSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AeviqueTheme.champagneGold
                                : AeviqueTheme.border,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Expanded(
                              child: thumbBytes != null
                                  ? Image.memory(
                                      thumbBytes,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Container(
                                      color: AeviqueTheme.elevatedCharcoal,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: AeviqueTheme.champagneGold,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              child: Text(
                                filter.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AeviqueTheme.champagneGold
                                      : AeviqueTheme.ivory,
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
            ),

            // 5. Dual Action Bar: "Try on My Photo" & "Edit Photo"
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  // Action A: Try on My Photo
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AeviqueTheme.charcoalSurface,
                        side: BorderSide(
                          color: AeviqueTheme.champagneGold.withValues(
                            alpha: 0.4,
                          ),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 16,
                        color: AeviqueTheme.champagneGold,
                      ),
                      label: const Text(
                        'Try on My Photo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AeviqueTheme.ivory,
                        ),
                      ),
                      onPressed: _handleTryOnMyPhoto,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Action B: Edit Photo
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AeviqueTheme.champagneGold,
                        foregroundColor: AeviqueTheme.deepBlack,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: AeviqueTheme.deepBlack,
                      ),
                      label: const Text(
                        'Edit Photo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AeviqueTheme.deepBlack,
                        ),
                      ),
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
      return Container(
        decoration: BoxDecoration(
          color: AeviqueTheme.charcoalSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AeviqueTheme.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AeviqueTheme.champagneGold,
                strokeWidth: 2.5,
              ),
              SizedBox(height: 14),
              Text(
                'Loading Photograph...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AeviqueTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: AeviqueTheme.charcoalSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AeviqueTheme.border),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AeviqueTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AeviqueTheme.champagneGold,
                  foregroundColor: AeviqueTheme.deepBlack,
                ),
                onPressed: _loadInitialDemoPhoto,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Demo'),
              ),
            ],
          ),
        ),
      );
    }

    final bytesToDisplay = _isComparingOriginal
        ? _originalPreviewBytes
        : _displayedPreviewBytes;

    return Container(
      decoration: BoxDecoration(
        color: AeviqueTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AeviqueTheme.champagneGold.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytesToDisplay != null)
            Image.memory(
              bytesToDisplay,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: AeviqueTheme.slateGray,
                ),
              ),
            ),

          // Compare with Original Button (Hold to preview original)
          if (_selectedPresetId != 'original')
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isComparingOriginal = true),
                onTapUp: (_) => setState(() => _isComparingOriginal = false),
                onTapCancel: () => setState(() => _isComparingOriginal = false),
                child: AeviqueGlass(
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isComparingOriginal
                            ? Icons.visibility_rounded
                            : Icons.visibility_outlined,
                        size: 14,
                        color: _isComparingOriginal
                            ? AeviqueTheme.champagneGold
                            : AeviqueTheme.ivory,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isComparingOriginal ? 'Original' : 'Hold Compare',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _isComparingOriginal
                              ? AeviqueTheme.champagneGold
                              : AeviqueTheme.ivory,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Processing Indicator
          if (_isRenderingPreset)
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AeviqueTheme.champagneGold,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'PREVIEWING',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        letterSpacing: 1.0,
                        color: AeviqueTheme.champagneGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
