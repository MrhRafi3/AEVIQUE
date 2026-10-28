import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../core/models/history_manager.dart';
import '../core/native_engine/aevique_ffi.dart';
import '../core/presets/filter_catalogue.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/before_after_viewer.dart';
import '../widgets/crop_overlay_widget.dart';
import '../widgets/tool_panels/crop_panel.dart';
import '../widgets/tool_panels/curves_panel.dart';
import '../widgets/tool_panels/details_panel.dart';
import '../widgets/tool_panels/effects_panel.dart';
import '../widgets/tool_panels/filters_panel.dart';
import '../widgets/tool_panels/portrait_panel.dart';
import '../widgets/tool_panels/tune_panel.dart';
import 'export_screen.dart';

enum ToolCategory { light, color, portrait, crop, filters }

class EditorScreen extends StatefulWidget {
  final Uint8List initialImageBytes;
  final String imageName;
  final String? initialTool;
  final String? initialPresetId;

  const EditorScreen({
    super.key,
    required this.initialImageBytes,
    this.imageName = 'Photo',
    this.initialTool,
    this.initialPresetId,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late HistoryManager _history;
  late EditState _workingState;

  // Cached base images for zero-delay slider updates
  img.Image? _basePreviewImage;
  img.Image? _thumbnailImage;
  Uint8List? _originalPreviewBytes;
  Uint8List? _rawPreviewRgba8;

  ui.Image? _previewUiImage;
  Uint8List? _previewBytes;
  bool _isLoadingBase = true;
  bool _isProcessing = false;

  Timer? _debounceTimer;
  int _latestRequestId = 0;

  ToolCategory _activeCategory = ToolCategory.light;
  String?
  _activeTool; // 'light', 'color', 'portrait', 'tune', 'details', 'curves', 'crop', 'effects', 'filters'
  bool _isBlemishModeActive = false;
  double _blemishRadius = 0.025;

  @override
  void initState() {
    super.initState();
    // Neutral initial state: exposure 0, contrast 0, saturation 0, no filters applied
    _history = HistoryManager(initialState: EditState.identity());
    _workingState = _history.current;

    if (widget.initialPresetId != null) {
      final filter = FilterCatalogue.findById(widget.initialPresetId!);
      if (filter != null) {
        _workingState = filter.state.copyWith(filterId: filter.id);
        _history = HistoryManager(initialState: _workingState);
        _activeCategory = ToolCategory.filters;
        _activeTool = 'filters';
      }
    } else if (widget.initialTool != null) {
      _activeTool = widget.initialTool;
      if (widget.initialTool == 'crop') {
        _activeCategory = ToolCategory.crop;
      } else if (widget.initialTool == 'color') {
        _activeCategory = ToolCategory.color;
      } else if (widget.initialTool == 'portrait') {
        _activeCategory = ToolCategory.portrait;
      } else if (widget.initialTool == 'filters' ||
          widget.initialTool == 'effects') {
        _activeCategory = ToolCategory.filters;
      } else {
        _activeCategory = ToolCategory.light;
      }
    }

    _initializeImageBundle();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _previewUiImage?.dispose();
    _previewUiImage = null;
    super.dispose();
  }

  Future<void> _initializeImageBundle() async {
    try {
      final bundle = await ImagePipeline.prepareImageBundle(
        widget.initialImageBytes,
        maxPreviewDimension: 1200,
        thumbnailDimension: 80,
      );

      if (!mounted) return;
      setState(() {
        _basePreviewImage = bundle.previewImage;
        _thumbnailImage = bundle.thumbnailImage;
        _originalPreviewBytes = bundle.originalPreviewBytes;
        _rawPreviewRgba8 = bundle.rawPreviewRgba8;
        // At identity, the preview is 100% identical to the original image!
        _previewBytes = bundle.originalPreviewBytes;
        _isLoadingBase = false;
      });

      if (!_workingState.isIdentity && _basePreviewImage != null) {
        _requestRender(_workingState);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewBytes = widget.initialImageBytes;
        _originalPreviewBytes = widget.initialImageBytes;
        _isLoadingBase = false;
      });
    }
  }

  void _requestRender(EditState state) {
    _workingState = state;

    // If returning to neutral state, immediately set original bytes with zero latency
    if (state.isIdentity && _originalPreviewBytes != null) {
      _debounceTimer?.cancel();
      _latestRequestId++;
      final oldUiImage = _previewUiImage;
      _previewUiImage = null;
      oldUiImage?.dispose();
      setState(() {
        _previewBytes = _originalPreviewBytes;
        _isProcessing = false;
      });
      return;
    }

    // Adapt debounce: 16ms (60fps) for fast native RGBA path, 30ms for Dart isolate fallback
    final debounceDuration = (AeviqueNativeEngine.isAvailable &&
            ImagePipeline.isNativeCompatible(state))
        ? const Duration(milliseconds: 16)
        : const Duration(milliseconds: 30);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      _executeFastRender(state);
    });
  }

  Future<void> _executeFastRender(EditState state) async {
    if (!mounted || _basePreviewImage == null) return;

    final requestId = ++_latestRequestId;
    setState(() => _isProcessing = true);

    try {
      final frame = await ImagePipeline.renderPreviewFrame(
        previewBase: _basePreviewImage!,
        rawPreviewRgba8: _rawPreviewRgba8,
        state: state,
        jpegQuality: 90,
      );

      if (!mounted || requestId != _latestRequestId) {
        // Discard stale frame to prevent memory leak
        frame.dispose();
        return;
      }

      final oldUiImage = _previewUiImage;
      setState(() {
        if (frame.isNative) {
          _previewUiImage = frame.uiImage;
        } else {
          _previewUiImage = null;
          _previewBytes = frame.jpegBytes;
        }
        _isProcessing = false;
      });
      oldUiImage?.dispose();
    } catch (_) {
      if (!mounted || requestId != _latestRequestId) return;
      setState(() => _isProcessing = false);
    }
  }

  void _applyToolChanges() {
    _history.push(_workingState);
    setState(() {
      _activeTool = null;
      _isBlemishModeActive = false;
    });
    _requestRender(_history.current);
  }

  void _cancelToolChanges() {
    _workingState = _history.current;
    setState(() {
      _activeTool = null;
      _isBlemishModeActive = false;
    });
    _requestRender(_history.current);
  }

  void _undo() {
    final undone = _history.undo();
    if (undone != null) {
      _workingState = undone;
      setState(() {});
      _requestRender(undone);
    }
  }

  void _redo() {
    final redone = _history.redo();
    if (redone != null) {
      _workingState = redone;
      setState(() {});
      _requestRender(redone);
    }
  }

  void _openTool(String toolId) {
    setState(() {
      _activeTool = toolId;
      _workingState = _history.current;
    });
  }

  // ----------------------------------------------------
  // SAFE BACK NAVIGATION & UNSAVED EDITS PROTECTION
  // ----------------------------------------------------
  Future<void> _handleBackAction() async {
    // 1. If inside an active tool, resolve or close that tool first
    if (_activeTool != null) {
      if (_workingState != _history.current) {
        // Discard uncommitted edits in current tool
        _cancelToolChanges();
      } else {
        setState(() => _activeTool = null);
      }
      return;
    }

    // 2. Check if entire session has unsaved edits
    final hasUnsavedEdits = !_history.current.isIdentity || _history.canUndo;

    if (!hasUnsavedEdits) {
      Navigator.of(context).pop();
      return;
    }

    // 3. Show confirmation dialog with Keep Editing, Discard, and Save/Export
    final action = await showDialog<_BackDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AeviqueTheme.elevatedCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AeviqueTheme.border.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AeviqueTheme.champagneGold,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Unsaved Edits',
              style: TextStyle(
                fontFamily: 'Playfair',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AeviqueTheme.ivory,
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unexported photo adjustments in this editing session. Would you like to preserve or discard them?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AeviqueTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AeviqueTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(_BackDialogAction.discard),
                  child: const Text(
                    'Discard',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AeviqueTheme.deepBlack,
                    side: BorderSide(
                      color: AeviqueTheme.border.withValues(alpha: 0.8),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(_BackDialogAction.keepEditing),
                  child: const Text(
                    'Keep Editing',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AeviqueTheme.ivory,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AeviqueTheme.champagneGold,
                foregroundColor: AeviqueTheme.deepBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(
                Icons.ios_share_rounded,
                size: 16,
                color: AeviqueTheme.deepBlack,
              ),
              label: const Text(
                'Save / Export',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AeviqueTheme.deepBlack,
                ),
              ),
              onPressed: () =>
                  Navigator.of(context).pop(_BackDialogAction.saveAndExport),
            ),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _BackDialogAction.keepEditing:
        // Remain in editor
        break;
      case _BackDialogAction.discard:
        Navigator.of(context).pop();
        break;
      case _BackDialogAction.saveAndExport:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExportScreen(
              sourceBytes: widget.initialImageBytes,
              state: _history.current,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToolOpen = _activeTool != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: AeviqueTheme.deepBlack,
        body: SafeArea(
          child: Column(
            children: [
              // Top Navigation & Action Bar
              _buildTopBar(),

              // Central Image Viewport with Before/After
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_isLoadingBase &&
                        (_previewUiImage != null || _previewBytes != null))
                      InteractiveViewer(
                        maxScale: 4.0,
                        minScale: 0.8,
                        child: Center(
                          child: BeforeAfterViewer(
                            originalChild: Image.memory(
                              _originalPreviewBytes ?? widget.initialImageBytes,
                              fit: BoxFit.contain,
                            ),
                            editedChild: _previewUiImage != null
                                ? RawImage(
                                    image: _previewUiImage!,
                                    fit: BoxFit.contain,
                                  )
                                : Image.memory(
                                    _previewBytes!,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AeviqueTheme.champagneGold,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Optimizing Image Canvas...',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AeviqueTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Crop interactive overlay (active when crop tool is open)
                    if (_activeTool == 'crop')
                      Positioned.fill(
                        child: CropOverlayWidget(
                          cropLeft: _workingState.geometry.cropLeft,
                          cropTop: _workingState.geometry.cropTop,
                          cropRight: _workingState.geometry.cropRight,
                          cropBottom: _workingState.geometry.cropBottom,
                          onCropChanged: (l, t, r, b) {
                            _requestRender(
                              _workingState.copyWith(
                                geometry: _workingState.geometry.copyWith(
                                  cropLeft: l,
                                  cropTop: t,
                                  cropRight: r,
                                  cropBottom: b,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Blemish interactive overlay (active when blemish healing is active)
                    if (_isBlemishModeActive && _basePreviewImage != null)
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) {
                                _handleBlemishTap(
                                  details.localPosition,
                                  constraints.biggest,
                                );
                              },
                              child: CustomPaint(
                                painter: _BlemishOverlayPainter(
                                  blemishes: _workingState.portrait.blemishes,
                                  imageAspectRatio:
                                      _basePreviewImage!.width /
                                      _basePreviewImage!.height,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Processing indicator pill
                    if (_isProcessing)
                      Positioned(
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AeviqueTheme.champagneGold.withValues(
                                alpha: 0.5,
                              ),
                              width: 0.8,
                            ),
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
                                'PROCESSING',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: AeviqueTheme.champagneGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Area: Active Tool Drawer OR Floating Tool Dock
              if (isToolOpen)
                _buildActiveToolDrawer()
              else
                _buildFloatingBottomDock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final activeFilterName = _workingState.presetName;
    final activeIntensity = _workingState.filterIntensity.round();
    final isNeutral = _workingState.isIdentity;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showPill = constraints.maxWidth >= 420;

        return AeviqueGlass(
          borderRadius: BorderRadius.zero,
          opacity: 0.85,
          blur: 16,
          showGoldAccent: false,
          borderWidth: 0.5,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            children: [
              // Left: Back button & brand
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
                tooltip: 'Back to Gallery',
                onPressed: _handleBackAction,
              ),
              const SizedBox(width: 2),
              Text(
                'AEVIQUE',
                style: AeviqueTheme.wordmarkStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: AeviqueTheme.ivory,
                ),
              ),

              const SizedBox(width: 4),

              // Central State Pill (Shows on wide screens, or flexible spacer)
              if (showPill)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isNeutral
                          ? AeviqueTheme.charcoalSurface
                          : AeviqueTheme.champagneGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNeutral
                            ? AeviqueTheme.border
                            : AeviqueTheme.champagneGold.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isNeutral
                                ? AeviqueTheme.slateGray
                                : AeviqueTheme.champagneGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            activeFilterName != null
                                ? '$activeFilterName • $activeIntensity%'
                                : (isNeutral
                                      ? 'Original • No Filter'
                                      : 'Custom Edits'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: isNeutral
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              color: isNeutral
                                  ? AeviqueTheme.textSecondary
                                  : AeviqueTheme.champagneGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),

              // Undo / Redo / Export Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                    ),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    tooltip: 'Undo',
                    color: _history.canUndo
                        ? AeviqueTheme.ivory
                        : AeviqueTheme.textMuted,
                    onPressed: _history.canUndo ? _undo : null,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(28, 28),
                    ),
                    icon: const Icon(Icons.redo_rounded, size: 18),
                    tooltip: 'Redo',
                    color: _history.canRedo
                        ? AeviqueTheme.ivory
                        : AeviqueTheme.textMuted,
                    onPressed: _history.canRedo ? _redo : null,
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AeviqueTheme.champagneGold,
                      foregroundColor: AeviqueTheme.deepBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: const Size(24, 26),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ExportScreen(
                            sourceBytes: widget.initialImageBytes,
                            state: _history.current,
                          ),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.ios_share_rounded,
                          size: 13,
                          color: AeviqueTheme.deepBlack,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Export',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AeviqueTheme.deepBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveToolDrawer() {
    String toolTitle = '';
    Widget panelContent = const SizedBox();

    switch (_activeTool) {
      case 'light':
        toolTitle = 'Light Adjustments';
        panelContent = TunePanel(
          tune: _workingState.tune,
          mode: TuneMode.light,
          onChanged: (t) => _requestRender(_workingState.copyWith(tune: t)),
        );
        break;
      case 'color':
        toolTitle = 'Color Adjustments';
        panelContent = TunePanel(
          tune: _workingState.tune,
          mode: TuneMode.color,
          onChanged: (t) => _requestRender(_workingState.copyWith(tune: t)),
        );
        break;
      case 'tune':
        toolTitle = 'Tune Image';
        panelContent = TunePanel(
          tune: _workingState.tune,
          mode: TuneMode.all,
          onChanged: (t) => _requestRender(_workingState.copyWith(tune: t)),
        );
        break;
      case 'detail':
      case 'details':
        toolTitle = 'Details';
        panelContent = DetailsPanel(
          details: _workingState.details,
          onChanged: (d) => _requestRender(_workingState.copyWith(details: d)),
        );
        break;
      case 'curves':
        toolTitle = 'Curves';
        panelContent = CurvesPanel(
          curves: _workingState.curves,
          onChanged: (c) => _requestRender(_workingState.copyWith(curves: c)),
        );
        break;
      case 'crop':
        toolTitle = 'Crop & Rotate';
        panelContent = CropPanel(
          geometry: _workingState.geometry,
          onChanged: (g) => _requestRender(_workingState.copyWith(geometry: g)),
        );
        break;
      case 'effects':
        toolTitle = 'Effects & Vignette';
        panelContent = EffectsPanel(
          effects: _workingState.effects,
          vignette: _workingState.vignette,
          onEffectsChanged: (e) =>
              _requestRender(_workingState.copyWith(effects: e)),
          onVignetteChanged: (v) =>
              _requestRender(_workingState.copyWith(vignette: v)),
        );
        break;
      case 'presets':
      case 'filters':
        toolTitle = 'Filters & Presets';
        panelContent = FiltersPanel(
          activeFilterId: _workingState.filterId,
          filterIntensity: _workingState.filterIntensity,
          thumbnailBase: _thumbnailImage,
          onFilterSelected: (filter, intensity) {
            final blended = filter.blendWithNeutral(intensity);
            _requestRender(
              _workingState.copyWith(
                filterId: filter.id,
                filterIntensity: intensity,
                presetName: filter.name,
                tune: blended.tune,
                details: blended.details,
                effects: blended.effects,
                vignette: blended.vignette,
              ),
            );
          },
          onIntensityChanged: (newIntensity) {
            if (_workingState.filterId == null) return;
            final filter = FilterCatalogue.findById(_workingState.filterId!);
            if (filter != null) {
              final blended = filter.blendWithNeutral(newIntensity);
              _requestRender(
                _workingState.copyWith(
                  filterIntensity: newIntensity,
                  tune: blended.tune,
                  details: blended.details,
                  effects: blended.effects,
                  vignette: blended.vignette,
                ),
              );
            }
          },
          onClearFilter: () {
            _requestRender(
              _workingState.copyWith(
                clearFilter: true,
                clearPreset: true,
                filterIntensity: 100.0,
                tune: const TuneAdjustments(),
                details: const DetailsAdjustments(),
                effects: const EffectsAdjustments(),
                vignette: const VignetteAdjustments(),
              ),
            );
          },
        );
        break;
      case 'portrait':
        toolTitle = 'Portrait Retouching';
        panelContent = PortraitPanel(
          portrait: _workingState.portrait,
          onChanged: (newPortrait) {
            _requestRender(_workingState.copyWith(portrait: newPortrait));
          },
          isBlemishModeActive: _isBlemishModeActive,
          onBlemishModeChanged: (active) {
            setState(() => _isBlemishModeActive = active);
          },
          blemishRadius: _blemishRadius,
          onBlemishRadiusChanged: (radius) {
            setState(() => _blemishRadius = radius);
          },
          onUndoLastBlemish: () {
            if (_workingState.portrait.blemishes.isNotEmpty) {
              final updated = List<BlemishSpot>.from(
                _workingState.portrait.blemishes,
              )..removeLast();
              _requestRender(
                _workingState.copyWith(
                  portrait: _workingState.portrait.copyWith(blemishes: updated),
                ),
              );
            }
          },
          onClearBlemishes: () {
            _requestRender(
              _workingState.copyWith(
                portrait: _workingState.portrait.copyWith(blemishes: const []),
              ),
            );
          },
        );
        break;
    }

    return AeviqueGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      opacity: 0.92,
      borderColor: AeviqueTheme.champagneGold.withValues(alpha: 0.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drawer Header with Cancel / Tool Name / Apply
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AeviqueTheme.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AeviqueTheme.slateGray,
                    size: 20,
                  ),
                  tooltip: 'Cancel',
                  onPressed: _cancelToolChanges,
                ),
                Expanded(
                  child: Text(
                    toolTitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Playfair',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AeviqueTheme.ivory,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check_rounded,
                    color: AeviqueTheme.champagneGold,
                    size: 22,
                  ),
                  tooltip: 'Apply',
                  onPressed: _applyToolChanges,
                ),
              ],
            ),
          ),
          panelContent,
        ],
      ),
    );
  }

  Widget _buildFloatingBottomDock() {
    List<_ContextualToolItem> contextualTools = [];
    switch (_activeCategory) {
      case ToolCategory.light:
        contextualTools = const [
          _ContextualToolItem(
            toolId: 'light',
            label: 'Light Adjustments',
            icon: Icons.tune_rounded,
          ),
          _ContextualToolItem(
            toolId: 'curves',
            label: 'Curves',
            icon: Icons.show_chart_rounded,
          ),
          _ContextualToolItem(
            toolId: 'details',
            label: 'Details',
            icon: Icons.auto_fix_normal_rounded,
          ),
        ];
        break;
      case ToolCategory.color:
        contextualTools = const [
          _ContextualToolItem(
            toolId: 'color',
            label: 'Color Balance',
            icon: Icons.palette_outlined,
          ),
        ];
        break;
      case ToolCategory.portrait:
        contextualTools = const [
          _ContextualToolItem(
            toolId: 'portrait',
            label: 'Portrait Retouch',
            icon: Icons.face_retouching_natural_rounded,
          ),
        ];
        break;
      case ToolCategory.crop:
        contextualTools = const [
          _ContextualToolItem(
            toolId: 'crop',
            label: 'Crop & Rotate',
            icon: Icons.crop_rotate_rounded,
          ),
        ];
        break;
      case ToolCategory.filters:
        contextualTools = const [
          _ContextualToolItem(
            toolId: 'filters',
            label: 'Filters',
            icon: Icons.filter_vintage_rounded,
          ),
          _ContextualToolItem(
            toolId: 'effects',
            label: 'Effects',
            icon: Icons.blur_on_rounded,
          ),
        ];
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Contextual Sub-tool Pills
        SizedBox(
          height: 38,
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: contextualTools.map((tool) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => _openTool(tool.toolId),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AeviqueTheme.elevatedCharcoal.withValues(
                            alpha: 0.85,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AeviqueTheme.champagneGold.withValues(
                              alpha: 0.35,
                            ),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tool.icon,
                              size: 14,
                              color: AeviqueTheme.champagneGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tool.label,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: AeviqueTheme.ivory,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Floating Bottom Tool Dock
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: AeviqueGlass(
            borderRadius: BorderRadius.circular(22),
            opacity: 0.88,
            borderColor: AeviqueTheme.border.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                _buildDockCategoryItem(
                  category: ToolCategory.light,
                  label: 'Light',
                  icon: Icons.lightbulb_outline_rounded,
                  defaultTool: 'light',
                ),
                _buildDockCategoryItem(
                  category: ToolCategory.color,
                  label: 'Color',
                  icon: Icons.palette_outlined,
                  defaultTool: 'color',
                ),
                _buildDockCategoryItem(
                  category: ToolCategory.portrait,
                  label: 'Portrait',
                  icon: Icons.face_retouching_natural_rounded,
                  defaultTool: 'portrait',
                ),
                _buildDockCategoryItem(
                  category: ToolCategory.crop,
                  label: 'Crop',
                  icon: Icons.crop_rotate_rounded,
                  defaultTool: 'crop',
                ),
                _buildDockCategoryItem(
                  category: ToolCategory.filters,
                  label: 'Filters',
                  icon: Icons.filter_vintage_rounded,
                  defaultTool: 'filters',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDockCategoryItem({
    required ToolCategory category,
    required String label,
    required IconData icon,
    required String defaultTool,
  }) {
    final isSelected = _activeCategory == category;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_activeCategory == category) {
            _openTool(defaultTool);
          } else {
            setState(() => _activeCategory = category);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AeviqueTheme.champagneGold.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AeviqueTheme.champagneGold.withValues(alpha: 0.35)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected
                    ? AeviqueTheme.champagneGold
                    : AeviqueTheme.slateGray,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                  color: isSelected
                      ? AeviqueTheme.champagneGold
                      : AeviqueTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBlemishTap(Offset localPos, Size containerSize) {
    if (_basePreviewImage == null) return;

    final imageAspect = _basePreviewImage!.width / _basePreviewImage!.height;
    final containerAspect = containerSize.width / containerSize.height;
    double imgW, imgH, offsetX, offsetY;

    if (imageAspect > containerAspect) {
      imgW = containerSize.width;
      imgH = imgW / imageAspect;
      offsetX = 0;
      offsetY = (containerSize.height - imgH) / 2;
    } else {
      imgH = containerSize.height;
      imgW = imgH * imageAspect;
      offsetX = (containerSize.width - imgW) / 2;
      offsetY = 0;
    }

    if (localPos.dx < offsetX ||
        localPos.dx > offsetX + imgW ||
        localPos.dy < offsetY ||
        localPos.dy > offsetY + imgH) {
      return;
    }

    final normX = ((localPos.dx - offsetX) / imgW).clamp(0.0, 1.0);
    final normY = ((localPos.dy - offsetY) / imgH).clamp(0.0, 1.0);

    final newSpot = BlemishSpot(x: normX, y: normY, radius: _blemishRadius);

    final updatedBlemishes = List<BlemishSpot>.from(
      _workingState.portrait.blemishes,
    )..add(newSpot);

    final updatedState = _workingState.copyWith(
      portrait: _workingState.portrait.copyWith(blemishes: updatedBlemishes),
    );

    _requestRender(updatedState);
  }
}

class _BlemishOverlayPainter extends CustomPainter {
  final List<BlemishSpot> blemishes;
  final double imageAspectRatio;

  _BlemishOverlayPainter({
    required this.blemishes,
    required this.imageAspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (blemishes.isEmpty) return;

    final containerAspect = size.width / size.height;
    double imgW, imgH, offsetX, offsetY;

    if (imageAspectRatio > containerAspect) {
      imgW = size.width;
      imgH = imgW / imageAspectRatio;
      offsetX = 0;
      offsetY = (size.height - imgH) / 2;
    } else {
      imgH = size.height;
      imgW = imgH * imageAspectRatio;
      offsetX = (size.width - imgW) / 2;
      offsetY = 0;
    }

    final paintStroke = Paint()
      ..color = const Color(0xFFD4AF7C).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final paintFill = Paint()
      ..color = const Color(0xFFD4AF7C).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    for (final spot in blemishes) {
      final center = Offset(offsetX + spot.x * imgW, offsetY + spot.y * imgH);
      final radius = spot.radius * imgW;
      canvas.drawCircle(center, radius, paintFill);
      canvas.drawCircle(center, radius, paintStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _BlemishOverlayPainter oldDelegate) {
    return oldDelegate.blemishes != blemishes ||
        oldDelegate.imageAspectRatio != imageAspectRatio;
  }
}

enum _BackDialogAction { keepEditing, discard, saveAndExport }

class _ContextualToolItem {
  final String toolId;
  final String label;
  final IconData icon;

  const _ContextualToolItem({
    required this.toolId,
    required this.label,
    required this.icon,
  });
}
