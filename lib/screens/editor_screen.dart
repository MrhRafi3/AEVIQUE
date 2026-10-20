import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../core/models/history_manager.dart';
import '../core/presets/filter_catalogue.dart';
import '../theme/aevique_theme.dart';
import '../theme/luma_theme.dart';
import '../widgets/before_after_viewer.dart';
import '../widgets/crop_overlay_widget.dart';
import '../widgets/tool_panels/crop_panel.dart';
import '../widgets/tool_panels/curves_panel.dart';
import '../widgets/tool_panels/details_panel.dart';
import '../widgets/tool_panels/effects_panel.dart';
import '../widgets/tool_panels/filters_panel.dart';
import '../widgets/tool_panels/tune_panel.dart';
import 'export_screen.dart';

enum ToolCategory { light, color, effects, detail, crop }

class EditorScreen extends StatefulWidget {
  final Uint8List initialImageBytes;
  final String imageName;
  final String? initialTool;

  const EditorScreen({
    super.key,
    required this.initialImageBytes,
    this.imageName = 'Photo',
    this.initialTool,
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

  Uint8List? _previewBytes;
  bool _isLoadingBase = true;
  bool _isProcessing = false;

  Timer? _debounceTimer;
  int _latestRequestId = 0;

  ToolCategory _activeCategory = ToolCategory.light;
  String?
  _activeTool; // 'light', 'color', 'tune', 'details', 'curves', 'crop', 'effects', 'filters'

  @override
  void initState() {
    super.initState();
    // Neutral initial state: exposure 0, contrast 0, saturation 0, no filters applied
    _history = HistoryManager(initialState: EditState.identity());
    _workingState = _history.current;

    if (widget.initialTool != null) {
      _activeTool = widget.initialTool;
      if (widget.initialTool == 'crop') {
        _activeCategory = ToolCategory.crop;
      } else if (widget.initialTool == 'color') {
        _activeCategory = ToolCategory.color;
      } else if (widget.initialTool == 'effects' ||
          widget.initialTool == 'filters') {
        _activeCategory = ToolCategory.effects;
      } else if (widget.initialTool == 'details' ||
          widget.initialTool == 'detail') {
        _activeCategory = ToolCategory.detail;
      } else {
        _activeCategory = ToolCategory.light;
      }
    }

    _initializeImageBundle();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
        // At identity, the preview is 100% identical to the original image!
        _previewBytes = bundle.originalPreviewBytes;
        _isLoadingBase = false;
      });
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
      setState(() {
        _previewBytes = _originalPreviewBytes;
        _isProcessing = false;
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 30), () {
      _executeFastRender(state);
    });
  }

  Future<void> _executeFastRender(EditState state) async {
    if (!mounted || _basePreviewImage == null) return;

    final requestId = ++_latestRequestId;
    setState(() => _isProcessing = true);

    try {
      final processed = await ImagePipeline.processPreviewFast(
        _basePreviewImage!,
        state,
        jpegQuality: 90,
      );

      if (!mounted || requestId != _latestRequestId) return;
      setState(() {
        _previewBytes = processed;
        _isProcessing = false;
      });
    } catch (_) {
      if (!mounted || requestId != _latestRequestId) return;
      setState(() => _isProcessing = false);
    }
  }

  void _applyToolChanges() {
    _history.push(_workingState);
    setState(() {
      _activeTool = null;
    });
    _requestRender(_history.current);
  }

  void _cancelToolChanges() {
    _workingState = _history.current;
    setState(() {
      _activeTool = null;
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
        backgroundColor: LumaTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LumaTheme.border, width: 1),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: LumaTheme.accent,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Unsaved Edits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: LumaTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'You have unexported photo adjustments in this editing session. Would you like to preserve or discard them?',
          style: TextStyle(
            fontSize: 13,
            color: LumaTheme.textSecondary,
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
                    side: const BorderSide(color: LumaTheme.border),
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
                    backgroundColor: LumaTheme.surfaceElevated,
                    side: const BorderSide(color: LumaTheme.borderLight),
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
                      color: LumaTheme.textPrimary,
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
                backgroundColor: LumaTheme.accent,
                foregroundColor: LumaTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 16),
              label: const Text(
                'Save / Export',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
        backgroundColor: LumaTheme.background,
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
                    if (!_isLoadingBase && _previewBytes != null)
                      InteractiveViewer(
                        maxScale: 4.0,
                        minScale: 0.8,
                        child: Center(
                          child: BeforeAfterViewer(
                            originalChild: Image.memory(
                              _originalPreviewBytes ?? widget.initialImageBytes,
                              fit: BoxFit.contain,
                            ),
                            editedChild: Image.memory(
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
                            CircularProgressIndicator(color: LumaTheme.accent),
                            SizedBox(height: 12),
                            Text(
                              'Optimizing Image Canvas...',
                              style: TextStyle(
                                fontSize: 12,
                                color: LumaTheme.textSecondary,
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
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: LumaTheme.border,
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
                                  color: LumaTheme.accent,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'PROCESSING',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: LumaTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Area: Active Tool Panel OR Tool Category Selector
              Container(
                decoration: const BoxDecoration(
                  color: LumaTheme.surface,
                  border: Border(
                    top: BorderSide(color: LumaTheme.border, width: 1),
                  ),
                ),
                child: isToolOpen
                    ? _buildActiveToolDrawer()
                    : _buildCategoryAndToolsSelector(),
              ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: LumaTheme.background,
        border: Border(bottom: BorderSide(color: LumaTheme.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Back button & AEVIQUE wordmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: 'Back to Gallery',
                onPressed: _handleBackAction,
              ),
              const SizedBox(width: 2),
              Text(
                'AEVIQUE',
                style: AeviqueTheme.wordmarkStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                  color: AeviqueTheme.ivory,
                ),
              ),
            ],
          ),

          // Central State Pill (Shows "Original • No Filter" or Filter Name & Intensity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isNeutral
                  ? LumaTheme.surfaceElevated
                  : LumaTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNeutral
                    ? LumaTheme.border
                    : LumaTheme.accent.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isNeutral ? LumaTheme.textMuted : LumaTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  activeFilterName != null
                      ? '$activeFilterName • $activeIntensity%'
                      : (isNeutral ? 'Original • No Filter' : 'Custom Edits'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isNeutral ? FontWeight.normal : FontWeight.w600,
                    color: isNeutral
                        ? LumaTheme.textSecondary
                        : LumaTheme.accent,
                  ),
                ),
              ],
            ),
          ),

          // Undo / Redo / Export Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.undo_rounded, size: 20),
                tooltip: 'Undo',
                color: _history.canUndo
                    ? LumaTheme.textPrimary
                    : LumaTheme.textMuted,
                onPressed: _history.canUndo ? _undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo_rounded, size: 20),
                tooltip: 'Redo',
                color: _history.canRedo
                    ? LumaTheme.textPrimary
                    : LumaTheme.textMuted,
                onPressed: _history.canRedo ? _redo : null,
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LumaTheme.surfaceElevated,
                  foregroundColor: LumaTheme.accent,
                  side: const BorderSide(color: LumaTheme.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 14),
                label: const Text(
                  'Export',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
              ),
            ],
          ),
        ],
      ),
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
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drawer Header with Cancel / Tool Name / Apply
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: LumaTheme.surfaceElevated,
            border: Border(
              bottom: BorderSide(color: LumaTheme.border, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: LumaTheme.textSecondary,
                ),
                tooltip: 'Cancel',
                onPressed: _cancelToolChanges,
              ),
              Text(
                toolTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: LumaTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_rounded, color: LumaTheme.accent),
                tooltip: 'Apply',
                onPressed: _applyToolChanges,
              ),
            ],
          ),
        ),
        panelContent,
      ],
    );
  }

  Widget _buildCategoryAndToolsSelector() {
    List<Widget> toolButtons = [];

    switch (_activeCategory) {
      case ToolCategory.light:
        toolButtons = [
          _buildToolItem(
            Icons.tune_rounded,
            'Light Adjustments',
            () => _openTool('light'),
          ),
          _buildToolItem(
            Icons.show_chart_rounded,
            'Curves',
            () => _openTool('curves'),
          ),
        ];
        break;
      case ToolCategory.color:
        toolButtons = [
          _buildToolItem(
            Icons.palette_outlined,
            'Color Balance',
            () => _openTool('color'),
          ),
        ];
        break;
      case ToolCategory.effects:
        toolButtons = [
          _buildToolItem(
            Icons.filter_vintage_rounded,
            'Filters',
            () => _openTool('filters'),
          ),
          _buildToolItem(
            Icons.blur_on_rounded,
            'Effects',
            () => _openTool('effects'),
          ),
        ];
        break;
      case ToolCategory.detail:
        toolButtons = [
          _buildToolItem(
            Icons.auto_fix_normal_rounded,
            'Details',
            () => _openTool('details'),
          ),
        ];
        break;
      case ToolCategory.crop:
        toolButtons = [
          _buildToolItem(
            Icons.crop_rotate_rounded,
            'Crop & Rotate',
            () => _openTool('crop'),
          ),
        ];
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tool Buttons for current category
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: toolButtons,
          ),
        ),
        const Divider(color: LumaTheme.border),
        // Category Tabs: Light | Color | Effects | Detail | Crop
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryTab(
                ToolCategory.light,
                'Light',
                Icons.lightbulb_outline_rounded,
              ),
              _buildCategoryTab(
                ToolCategory.color,
                'Color',
                Icons.palette_outlined,
              ),
              _buildCategoryTab(
                ToolCategory.effects,
                'Effects',
                Icons.auto_awesome_outlined,
              ),
              _buildCategoryTab(
                ToolCategory.detail,
                'Detail',
                Icons.shutter_speed_outlined,
              ),
              _buildCategoryTab(
                ToolCategory.crop,
                'Crop',
                Icons.crop_rotate_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LumaTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LumaTheme.border, width: 1),
              ),
              child: Icon(icon, color: LumaTheme.accent, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: LumaTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(ToolCategory category, String label, IconData icon) {
    final isSelected = _activeCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? LumaTheme.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? LumaTheme.accent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? LumaTheme.accent : LumaTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? LumaTheme.accent : LumaTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BackDialogAction { keepEditing, discard, saveAndExport }
