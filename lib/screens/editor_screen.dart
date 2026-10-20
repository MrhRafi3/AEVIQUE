import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../core/models/history_manager.dart';
import '../theme/luma_theme.dart';
import '../widgets/before_after_viewer.dart';
import '../widgets/crop_overlay_widget.dart';
import '../widgets/tool_panels/crop_panel.dart';
import '../widgets/tool_panels/curves_panel.dart';
import '../widgets/tool_panels/details_panel.dart';
import '../widgets/tool_panels/effects_panel.dart';
import '../widgets/tool_panels/presets_panel.dart';
import '../widgets/tool_panels/tune_panel.dart';
import 'export_screen.dart';

enum ToolCategory { refine, fix, style, presets }

class EditorScreen extends StatefulWidget {
  final Uint8List initialImageBytes;
  final String imageName;

  const EditorScreen({
    super.key,
    required this.initialImageBytes,
    this.imageName = 'Photo',
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late HistoryManager _history;
  late EditState _workingState;

  Uint8List? _previewBytes;
  bool _isProcessing = false;
  Timer? _debounceTimer;

  ToolCategory _activeCategory = ToolCategory.refine;
  String?
  _activeTool; // 'tune', 'details', 'curves', 'crop', 'effects', 'presets'

  @override
  void initState() {
    super.initState();
    _history = HistoryManager(initialState: EditState.identity());
    _workingState = _history.current;
    _renderPreview(_workingState);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _requestRender(EditState state) {
    _workingState = state;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 60), () {
      _renderPreview(state);
    });
  }

  Future<void> _renderPreview(EditState state) async {
    if (!mounted) return;
    setState(() => _isProcessing = true);

    try {
      final processed = await ImagePipeline.processImage(
        widget.initialImageBytes,
        state,
        maxDimension: 1200, // Downscale for fast 60fps-level preview updates
        jpegQuality: 85,
      );

      if (!mounted) return;
      setState(() {
        _previewBytes = processed;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }
  }

  void _applyToolChanges() {
    _history.push(_workingState);
    setState(() {
      _activeTool = null;
    });
    _renderPreview(_history.current);
  }

  void _cancelToolChanges() {
    _workingState = _history.current;
    setState(() {
      _activeTool = null;
    });
    _renderPreview(_history.current);
  }

  void _undo() {
    final undone = _history.undo();
    if (undone != null) {
      _workingState = undone;
      setState(() {});
      _renderPreview(undone);
    }
  }

  void _redo() {
    final redone = _history.redo();
    if (redone != null) {
      _workingState = redone;
      setState(() {});
      _renderPreview(redone);
    }
  }

  void _openTool(String toolId) {
    setState(() {
      _activeTool = toolId;
      _workingState = _history.current;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isToolOpen = _activeTool != null;

    return Scaffold(
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
                  if (_previewBytes != null)
                    InteractiveViewer(
                      maxScale: 4.0,
                      minScale: 0.8,
                      child: Center(
                        child: BeforeAfterViewer(
                          originalChild: Image.memory(
                            widget.initialImageBytes,
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
                      child: CircularProgressIndicator(color: LumaTheme.accent),
                    ),

                  // Crop interactive overlay (only active when crop tool is open)
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
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
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
                              'RENDERING',
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
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: LumaTheme.background,
        border: Border(bottom: BorderSide(color: LumaTheme.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            tooltip: 'Back to Gallery',
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Undo / Redo controls
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
            ],
          ),

          // Export button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: LumaTheme.surfaceElevated,
              foregroundColor: LumaTheme.accent,
              side: const BorderSide(color: LumaTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 16),
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
    );
  }

  Widget _buildActiveToolDrawer() {
    String toolTitle = '';
    Widget panelContent = const SizedBox();

    switch (_activeTool) {
      case 'tune':
        toolTitle = 'Tune Image';
        panelContent = TunePanel(
          tune: _workingState.tune,
          onChanged: (t) => _requestRender(_workingState.copyWith(tune: t)),
        );
        break;
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
        toolTitle = 'Presets';
        panelContent = PresetsPanel(
          activePresetName: _workingState.presetName,
          onPresetSelected: (preset) {
            _requestRender(
              _workingState.copyWith(
                presetName: preset.name,
                tune: preset.state.tune,
                details: preset.state.details,
                effects: preset.state.effects,
                vignette: preset.state.vignette,
              ),
            );
          },
          onClearPreset: () {
            _requestRender(
              _workingState.copyWith(
                clearPreset: true,
                tune: const TuneAdjustments(),
                effects: const EffectsAdjustments(),
                details: const DetailsAdjustments(),
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
      case ToolCategory.refine:
        toolButtons = [
          _buildToolItem(
            Icons.tune_rounded,
            'Tune Image',
            () => _openTool('tune'),
          ),
          _buildToolItem(
            Icons.auto_fix_normal_rounded,
            'Details',
            () => _openTool('details'),
          ),
          _buildToolItem(
            Icons.show_chart_rounded,
            'Curves',
            () => _openTool('curves'),
          ),
        ];
        break;
      case ToolCategory.fix:
        toolButtons = [
          _buildToolItem(
            Icons.crop_rotate_rounded,
            'Crop & Rotate',
            () => _openTool('crop'),
          ),
        ];
        break;
      case ToolCategory.style:
        toolButtons = [
          _buildToolItem(
            Icons.blur_on_rounded,
            'Effects',
            () => _openTool('effects'),
          ),
        ];
        break;
      case ToolCategory.presets:
        toolButtons = [
          _buildToolItem(
            Icons.filter_vintage_rounded,
            'Presets',
            () => _openTool('presets'),
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
        // Category Tabs: Refine | Fix | Style | Presets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryTab(
                ToolCategory.refine,
                'Refine',
                Icons.tune_rounded,
              ),
              _buildCategoryTab(ToolCategory.fix, 'Fix', Icons.crop_rounded),
              _buildCategoryTab(
                ToolCategory.style,
                'Style',
                Icons.auto_awesome_outlined,
              ),
              _buildCategoryTab(
                ToolCategory.presets,
                'Presets',
                Icons.filter_vintage_outlined,
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
