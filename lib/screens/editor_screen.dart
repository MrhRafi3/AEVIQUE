import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../core/models/history_manager.dart';
import '../core/native_engine/aevique_ffi.dart';
import '../core/presets/filter_catalogue.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/aevique_ui_components.dart';
import '../widgets/before_after_viewer.dart';
import '../services/preset_repository.dart';
import '../widgets/crop_overlay_widget.dart';
import '../widgets/history_timeline_sheet.dart';
import '../widgets/photo_adaptive_background.dart';
import '../widgets/tool_panels/crop_panel.dart';
import '../widgets/tool_panels/curves_panel.dart';
import '../widgets/tool_panels/effects_panel.dart';
import '../widgets/tool_panels/filters_panel.dart';
import '../widgets/tool_panels/hsl_panel.dart';
import '../widgets/tool_panels/mask_panel.dart';
import '../widgets/tool_panels/portrait_panel.dart';
import '../widgets/tool_panels/presets_panel.dart';
import '../widgets/tool_panels/tune_panel.dart';
import 'export_screen.dart';

enum _BackDialogAction { keepEditing, discard, saveAndExport }

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

  String?
  _activeTool; // 'crop', 'adjust', 'filter', 'curves', 'effects', 'presets', 'portrait', 'hsl', 'mask'
  int? _activeMaskIndex;
  bool _isBlemishModeActive = false;
  double _blemishRadius = 0.025;

  @override
  void initState() {
    super.initState();
    _history = HistoryManager(initialState: EditState.identity());
    _workingState = _history.current;

    if (widget.initialPresetId != null) {
      final filter = FilterCatalogue.findById(widget.initialPresetId!);
      if (filter != null) {
        _workingState = filter.state.copyWith(filterId: filter.id);
        _history = HistoryManager(initialState: _workingState);
        _activeTool = 'filter';
      }
    } else if (widget.initialTool != null) {
      final t = widget.initialTool!.toLowerCase();
      if (t == 'tune' || t == 'light' || t == 'color') {
        _activeTool = 'adjust';
      } else if (t == 'filters') {
        _activeTool = 'filter';
      } else {
        _activeTool = t;
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

    final debounceDuration =
        (AeviqueNativeEngine.isAvailable &&
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
    HapticFeedback.lightImpact();
    _history.push(_workingState);
    setState(() {
      _activeTool = null;
      _isBlemishModeActive = false;
    });
    _requestRender(_history.current);
  }

  void _cancelToolChanges() {
    HapticFeedback.lightImpact();
    _workingState = _history.current;
    setState(() {
      _activeTool = null;
      _isBlemishModeActive = false;
    });
    _requestRender(_history.current);
  }

  void _undo() {
    HapticFeedback.lightImpact();
    final undone = _history.undo();
    if (undone != null) {
      _workingState = undone;
      setState(() {});
      _requestRender(undone);
    }
  }

  void _redo() {
    HapticFeedback.lightImpact();
    final redone = _history.redo();
    if (redone != null) {
      _workingState = redone;
      setState(() {});
      _requestRender(redone);
    }
  }

  void _openTool(String toolId) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeTool = toolId;
      _workingState = _history.current;
    });
  }

  Future<void> _showSavePresetDialog() async {
    final nameController = TextEditingController(text: 'My Preset');
    final descController = TextEditingController(text: 'Custom photographic style');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14141C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AeviqueTheme.borderLight, width: 0.8),
        ),
        title: const Text(
          'Save as Preset',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Preset Name',
                labelStyle: TextStyle(color: AeviqueTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AeviqueTheme.borderSubtle),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AeviqueTheme.primaryBlueLight),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: AeviqueTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AeviqueTheme.borderSubtle),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AeviqueTheme.primaryBlueLight),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AeviqueTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save Preset'),
          ),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      final preset = CustomPreset(
        id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        description: descController.text.trim().isEmpty
            ? 'User Custom Preset'
            : descController.text.trim(),
        state: _workingState,
        createdAt: DateTime.now(),
      );
      await PresetRepository.savePreset(preset);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preset "${preset.name}" saved successfully!'),
            backgroundColor: AeviqueTheme.charcoalSurface,
          ),
        );
      }
    }
  }

  Future<void> _handleBackAction() async {
    if (_activeTool != null) {
      if (_workingState != _history.current) {
        _cancelToolChanges();
      } else {
        setState(() => _activeTool = null);
      }
      return;
    }

    final hasUnsavedEdits = !_history.current.isIdentity || _history.canUndo;
    if (!hasUnsavedEdits) {
      Navigator.of(context).pop();
      return;
    }

    final action = await showDialog<_BackDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14141C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AeviqueTheme.borderLight, width: 0.8),
        ),
        title: const Text(
          'Unsaved Edits',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
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
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_BackDialogAction.discard),
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_BackDialogAction.keepEditing),
            child: const Text(
              'Keep Editing',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AeviqueTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.of(context).pop(_BackDialogAction.saveAndExport),
            child: const Text('Save / Export'),
          ),
        ],
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _BackDialogAction.keepEditing:
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

  void _handleBlemishTap(Offset localPos, Size boxSize) {
    if (_basePreviewImage == null) return;
    final aspect = _basePreviewImage!.width / _basePreviewImage!.height;
    double renderW, renderH, offsetX = 0, offsetY = 0;
    final boxAspect = boxSize.width / boxSize.height;

    if (boxAspect > aspect) {
      renderH = boxSize.height;
      renderW = renderH * aspect;
      offsetX = (boxSize.width - renderW) / 2;
    } else {
      renderW = boxSize.width;
      renderH = renderW / aspect;
      offsetY = (boxSize.height - renderH) / 2;
    }

    final imgX = (localPos.dx - offsetX) / renderW;
    final imgY = (localPos.dy - offsetY) / renderH;

    if (imgX < 0 || imgX > 1 || imgY < 0 || imgY > 1) return;

    HapticFeedback.lightImpact();
    final newSpot = BlemishSpot(x: imgX, y: imgY, radius: _blemishRadius);
    final updated = List<BlemishSpot>.from(_workingState.portrait.blemishes)
      ..add(newSpot);
    _requestRender(
      _workingState.copyWith(
        portrait: _workingState.portrait.copyWith(blemishes: updated),
      ),
    );
  }

  void _handleBrushStroke(Offset localPos, Size boxSize) {
    if (_workingState.masks.isEmpty || _basePreviewImage == null) return;
    final idx =
        (_activeMaskIndex ?? 0).clamp(0, _workingState.masks.length - 1);
    final mask = _workingState.masks[idx];
    if (mask.type != MaskType.brush) return;

    final aspect = _basePreviewImage!.width / _basePreviewImage!.height;
    double renderW, renderH, offsetX = 0, offsetY = 0;
    final boxAspect = boxSize.width / boxSize.height;

    if (boxAspect > aspect) {
      renderH = boxSize.height;
      renderW = renderH * aspect;
      offsetX = (boxSize.width - renderW) / 2;
    } else {
      renderW = boxSize.width;
      renderH = renderW / aspect;
      offsetY = (boxSize.height - renderH) / 2;
    }

    final imgX = (localPos.dx - offsetX) / renderW;
    final imgY = (localPos.dy - offsetY) / renderH;

    if (imgX < 0 || imgX > 1 || imgY < 0 || imgY > 1) return;

    final points = List<MaskPoint>.from(mask.brushPoints)
      ..add(MaskPoint(x: imgX, y: imgY, radius: 0.04, feather: 0.5));

    final updatedMasks = List<SelectiveMask>.from(_workingState.masks);
    updatedMasks[idx] = mask.copyWith(brushPoints: points);

    _requestRender(
      _workingState.copyWith(masks: updatedMasks, showMaskOverlay: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: AeviqueTheme.deepCanvas,
        body: PhotoAdaptiveBackground(
          imageBytes: widget.initialImageBytes,
          child: SafeArea(
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final isMetaOrCtrl =
                      HardwareKeyboard.instance.isMetaPressed ||
                      HardwareKeyboard.instance.isControlPressed;
                  if (isMetaOrCtrl &&
                      event.logicalKey == LogicalKeyboardKey.keyZ) {
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      if (_history.canRedo) _redo();
                    } else {
                      if (_history.canUndo) _undo();
                    }
                    return KeyEventResult.handled;
                  }
                  if (isMetaOrCtrl &&
                      event.logicalKey == LogicalKeyboardKey.keyE) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExportScreen(
                          sourceBytes: widget.initialImageBytes,
                          state: _history.current,
                        ),
                      ),
                    );
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _handleBackAction();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 768;
                  if (isDesktop) {
                    return _buildDesktopLayout();
                  } else {
                    return _buildMobileLayout();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final isToolOpen = _activeTool != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Center Image Canvas (Dominates Screen)
        Positioned.fill(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildCanvasStack()),
              // Reserve bottom space for floating dock or tool sheet
              SizedBox(
                height: isToolOpen ? (_activeTool == 'crop' ? 220 : 260) : 100,
              ),
            ],
          ),
        ),

        // 2. Floating Bottom Controls: Either Mode Dock or Active Tool Sheet
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: isToolOpen ? _buildActiveToolSheet() : _buildNeutralModeDock(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left: Large Canvas with Minimal Top Bar
        Expanded(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildCanvasStack()),
            ],
          ),
        ),
        // Right: Desktop Glass Inspector Sidebar
        Container(
          width: 380,
          decoration: const BoxDecoration(
            color: Color(0x8C14141C),
            border: Border(
              left: BorderSide(color: AeviqueTheme.border, width: 0.8),
            ),
          ),
          child: _buildDesktopSidebar(_activeTool),
        ),
      ],
    );
  }

  Widget _buildCanvasStack() {
    return Stack(
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
                    ? RawImage(image: _previewUiImage!, fit: BoxFit.contain)
                    : Image.memory(_previewBytes!, fit: BoxFit.contain),
              ),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(
              color: AeviqueTheme.primaryBlue,
              strokeWidth: 2.0,
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

        // Mask interactive brush stroke overlay
        if ((_activeTool == 'mask' || _activeTool == 'masks') &&
            _workingState.masks.isNotEmpty)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanDown: (d) => _handleBrushStroke(d.localPosition, constraints.biggest),
                  onPanUpdate: (d) => _handleBrushStroke(d.localPosition, constraints.biggest),
                );
              },
            ),
          ),

        // Blemish interactive overlay
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
                          _basePreviewImage!.width / _basePreviewImage!.height,
                    ),
                  ),
                );
              },
            ),
          ),

        // Processing indicator
        if (_isProcessing)
          Positioned(
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AeviqueTheme.primaryBlue.withValues(alpha: 0.5),
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
                      color: AeviqueTheme.primaryBlueLight,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PROCESSING',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AeviqueTheme.primaryBlueLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Reference Minimal Top Navigation (Phone 3, 4, 5)
  Widget _buildTopBar() {
    final isNeutral = _workingState.isIdentity;
    final stateText = _activeTool != null
        ? _getToolTitle(_activeTool!)
        : (isNeutral ? 'Original • No Filter' : 'Custom Edits');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close "✕" on Left (Phone 3, 5) + Brand
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Back to Gallery',
                child: GestureDetector(
                  onTap: _handleBackAction,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'AEVIQUE',
                style: AeviqueTheme.wordmarkStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Title / Mode / State in Center
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                stateText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ),
          ),

          // Right Controls: Undo, Redo, Export
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Undo',
                child: GestureDetector(
                  onTap: _history.canUndo ? _undo : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.undo_rounded,
                      size: 18,
                      color: _history.canUndo ? Colors.white : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: 'Redo',
                child: GestureDetector(
                  onTap: _history.canRedo ? _redo : null,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.redo_rounded,
                      size: 18,
                      color: _history.canRedo ? Colors.white : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Tooltip(
                message: 'History Timeline',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => HistoryTimelineSheet(
                        history: _history,
                        onJumpToStep: (step) {
                          final st = _history.jumpToIndex(step);
                          if (st != null) {
                            _workingState = st;
                            setState(() {});
                            _requestRender(st);
                          }
                        },
                        onClearHistory: () {
                          _history.reset(toState: _workingState);
                          setState(() {});
                        },
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // "Export" Action Button (Phone 3)
              Tooltip(
                message: 'Export',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExportScreen(
                          sourceBytes: widget.initialImageBytes,
                          state: _history.current,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12, width: 0.8),
                    ),
                    child: const Text(
                      'Export',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Floating Contextual Mode Dock (Neutral State)
  Widget _buildNeutralModeDock() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AeviqueFloatingDock(
          children: [
            _buildDockModeItem('tune', 'Adjust', Icons.tune_rounded),
            _buildDockModeItem('crop', 'Crop', Icons.crop_rounded),
            _buildDockModeItem('hsl', 'HSL Mixer', Icons.colorize_rounded),
            _buildDockModeItem('curves', 'Curves', Icons.show_chart_rounded),
            _buildDockModeItem('mask', 'Masks', Icons.masks_rounded),
            _buildDockModeItem('effects', 'Effects', Icons.blur_on_rounded),
            _buildDockModeItem('filter', 'Filters', Icons.filter_vintage_rounded),
            _buildDockModeItem('presets', 'Presets', Icons.bookmarks_rounded),
            _buildDockModeItem('portrait', 'Portrait', Icons.face_retouching_natural_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDockModeItem(String toolId, String label, IconData icon) {
    return GestureDetector(
      onTap: () => _openTool(toolId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white70),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active Tool Panel / Sheet (Phone 3, 4, 5)
  Widget _buildActiveToolSheet() {
    final panelContent = _getPanelWidget(_activeTool!);

    return AeviqueGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      hasGrabHandle: _activeTool == 'filter',
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sheet Cancel & Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AeviqueTheme.coralRedLight,
                ),
                tooltip: 'Cancel',
                onPressed: _cancelToolChanges,
              ),
              Text(
                _getToolTitle(_activeTool!),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: AeviqueTheme.primaryBlueLight,
                ),
                tooltip: 'Apply',
                onPressed: _applyToolChanges,
              ),
            ],
          ),
          panelContent,
          const SizedBox(height: 12),

          // Contextual Mode Dock & Prominent Circular Checkmark FAB
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Contextual pill switcher: Crop | Adjust | Filter
              LiquidGlassPanel(
                variant: LiquidGlassVariant.ultraClear,
                borderRadius: BorderRadius.circular(AeviqueTheme.radiusFull),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContextModeChip('crop', 'Crop', Icons.crop_rounded),
                    _buildContextModeChip(
                      'adjust',
                      'Adjust',
                      Icons.tune_rounded,
                    ),
                    _buildContextModeChip(
                      'filter',
                      'Filter',
                      Icons.filter_vintage_rounded,
                    ),
                  ],
                ),
              ),

              // Prominent Circular Checkmark FAB with Liquid Blue Glow
              AeviqueAmberFab(
                icon: Icons.check_rounded,
                size: 52,
                iconSize: 28,
                tooltip: 'Apply',
                onPressed: _applyToolChanges,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextModeChip(String id, String label, IconData icon) {
    final isSelected = _activeTool == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: AeviqueTheme.primaryBlue.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AeviqueTheme.primaryBlueLight,
                  width: 1.0,
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AeviqueTheme.primaryBlueLight
                  : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(String? activeTool) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector Pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDesktopTab('tune', 'Light Adjustments'),
                const SizedBox(width: 6),
                _buildDesktopTab('crop', 'Crop'),
                const SizedBox(width: 6),
                _buildDesktopTab('tune', 'Light'),
                const SizedBox(width: 6),
                _buildDesktopTab('tune', 'Color'),
                const SizedBox(width: 6),
                _buildDesktopTab('hsl', 'HSL Mixer'),
                const SizedBox(width: 6),
                _buildDesktopTab('filter', 'Filters'),
                const SizedBox(width: 6),
                _buildDesktopTab('curves', 'Curves'),
                const SizedBox(width: 6),
                _buildDesktopTab('mask', 'Masks'),
                const SizedBox(width: 6),
                _buildDesktopTab('effects', 'Effects'),
                const SizedBox(width: 6),
                _buildDesktopTab('presets', 'Presets'),
                const SizedBox(width: 6),
                _buildDesktopTab('portrait', 'Portrait'),
              ],
            ),
          ),
        ),

        const Divider(color: AeviqueTheme.borderSubtle),

        // Inspector Content
        Expanded(
          child: activeTool == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 36, color: Colors.white24),
                      SizedBox(height: 12),
                      Text(
                        'Select an editing tool above',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.white54,
                            ),
                            tooltip: 'Cancel',
                            onPressed: _cancelToolChanges,
                          ),
                          Text(
                            _getToolTitle(activeTool),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AeviqueTheme.primaryBlueLight,
                            ),
                            tooltip: 'Apply',
                            onPressed: _applyToolChanges,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _getPanelWidget(activeTool),
                      ),
                    ),
                  ],
                ),
        ),

        // Apply / Cancel Bottom Bar (when tool is active)
        if (activeTool != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AeviqueButton.secondary(
                    label: 'Reset Tool',
                    onPressed: _cancelToolChanges,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AeviqueButton(
                    label: 'Apply Edits',
                    onPressed: _applyToolChanges,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTab(String id, String label) {
    final isSelected = _activeTool == id;
    return AeviquePillChip(
      label: label,
      isSelected: isSelected,
      onTap: () => setState(() => _activeTool = id),
    );
  }

  String _getToolTitle(String toolId) {
    switch (toolId) {
      case 'crop':
        return 'Crop & Rotate';
      case 'adjust':
      case 'light':
      case 'color':
      case 'tune':
        return 'Adjust';
      case 'filter':
      case 'filters':
        return 'Filter';
      case 'hsl':
        return 'HSL Color Mixer';
      case 'curves':
        return 'Curves';
      case 'mask':
      case 'masks':
        return 'Selective Masks';
      case 'effects':
        return 'Effects';
      case 'presets':
        return 'Presets';
      case 'portrait':
        return 'Portrait';
      default:
        return 'Edit';
    }
  }

  Widget _getPanelWidget(String toolId) {
    switch (toolId) {
      case 'crop':
        return CropPanel(
          geometry: _workingState.geometry,
          onChanged: (g) => _requestRender(_workingState.copyWith(geometry: g)),
        );
      case 'adjust':
      case 'light':
      case 'color':
      case 'tune':
        return TunePanel(
          tune: _workingState.tune,
          curves: _workingState.curves,
          onCurvesChanged: (c) =>
              _requestRender(_workingState.copyWith(curves: c)),
          onChanged: (t) => _requestRender(_workingState.copyWith(tune: t)),
        );
      case 'filter':
      case 'filters':
        return FiltersPanel(
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
      case 'hsl':
        return HslPanel(
          adjustments: _workingState.hsl,
          onChanged: (hsl) => _requestRender(_workingState.copyWith(hsl: hsl)),
        );
      case 'curves':
        return CurvesPanel(
          curves: _workingState.curves,
          onChanged: (c) => _requestRender(_workingState.copyWith(curves: c)),
        );
      case 'mask':
      case 'masks':
        return MaskPanel(
          masks: _workingState.masks,
          showMaskOverlay: _workingState.showMaskOverlay,
          onMasksChanged: (m) => _requestRender(_workingState.copyWith(masks: m)),
          onOverlayToggled: (ov) => _requestRender(_workingState.copyWith(showMaskOverlay: ov)),
          onActiveMaskChanged: (idx) => setState(() => _activeMaskIndex = idx),
        );
      case 'effects':
        return EffectsPanel(
          effects: _workingState.effects,
          vignette: _workingState.vignette,
          onEffectsChanged: (e) =>
              _requestRender(_workingState.copyWith(effects: e)),
          onVignetteChanged: (v) =>
              _requestRender(_workingState.copyWith(vignette: v)),
        );
      case 'presets':
        return PresetsPanel(
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
          onCustomPresetSelected: (custom) {
            _requestRender(
              _workingState.copyWith(
                presetName: custom.name,
                tune: custom.state.tune,
                details: custom.state.details,
                effects: custom.state.effects,
                vignette: custom.state.vignette,
                hsl: custom.state.hsl,
                curves: custom.state.curves,
              ),
            );
          },
          onClearPreset: () {
            _requestRender(
              _workingState.copyWith(
                clearPreset: true,
                tune: const TuneAdjustments(),
                details: const DetailsAdjustments(),
                effects: const EffectsAdjustments(),
                vignette: const VignetteAdjustments(),
                hsl: const HslAdjustments(),
                curves: const ToneCurves(),
              ),
            );
          },
          onSaveCurrentAsPreset: _showSavePresetDialog,
        );
      case 'portrait':
        return PortraitPanel(
          portrait: _workingState.portrait,
          onChanged: (p) => _requestRender(_workingState.copyWith(portrait: p)),
          isBlemishModeActive: _isBlemishModeActive,
          onBlemishModeChanged: (active) =>
              setState(() => _isBlemishModeActive = active),
          blemishRadius: _blemishRadius,
          onBlemishRadiusChanged: (r) => setState(() => _blemishRadius = r),
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
      default:
        return const SizedBox();
    }
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
    double renderW, renderH, offsetX = 0, offsetY = 0;
    final boxAspect = size.width / size.height;

    if (boxAspect > imageAspectRatio) {
      renderH = size.height;
      renderW = renderH * imageAspectRatio;
      offsetX = (size.width - renderW) / 2;
    } else {
      renderW = size.width;
      renderH = renderW / imageAspectRatio;
      offsetY = (size.height - renderH) / 2;
    }

    final circlePaint = Paint()
      ..color = AeviqueTheme.primaryBlueLight.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final spot in blemishes) {
      final px = offsetX + spot.x * renderW;
      final py = offsetY + spot.y * renderH;
      final radius = spot.radius * renderW;
      canvas.drawCircle(Offset(px, py), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlemishOverlayPainter oldDelegate) =>
      oldDelegate.blemishes != blemishes ||
      oldDelegate.imageAspectRatio != imageAspectRatio;
}
