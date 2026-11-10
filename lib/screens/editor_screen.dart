import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../core/image_engine/image_pipeline.dart';
import '../core/image_engine/subject_segmentation_service.dart';
import '../core/image_engine/coordinate_transformer.dart';
import '../core/image_engine/mask_engine.dart';
import '../core/models/edit_state.dart';
import '../core/models/history_manager.dart';
import '../core/native_engine/lumafix_ffi.dart';
import '../core/presets/filter_catalogue.dart';
import '../theme/luma_theme.dart';
import '../widgets/luma_glass.dart';
import '../widgets/luma_ui_components.dart';
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
  double? _selectedCropAspectRatio;
  bool _isBlemishModeActive = false;
  double _blemishRadius = 0.025;
  Offset? _lastStrokePoint;
  final List<Uint8List> _maskUndoStack = [];
  double _brushSize = 35.0;
  double _brushHardness = 0.7;
  double _brushOpacity = 1.0;
  bool _isMaskEraseMode = false;
  bool _isSegmentingSubject = false;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _history = HistoryManager(initialState: EditState.identity());
    _workingState = _history.current;
    // Immediately present the initial image bytes with zero blocking lag
    _previewBytes = widget.initialImageBytes;
    _originalPreviewBytes = widget.initialImageBytes;
    _isLoadingBase = false;

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
    _transformationController.dispose();
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
        if (_previewUiImage == null && _workingState.isIdentity) {
          _previewBytes = bundle.originalPreviewBytes;
        }
        _isLoadingBase = false;
      });

      if (!_workingState.isIdentity && _basePreviewImage != null) {
        _requestRender(_workingState);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewBytes ??= widget.initialImageBytes;
        _originalPreviewBytes ??= widget.initialImageBytes;
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
        (LumaFixNativeEngine.isAvailable &&
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
    if (toolId == 'crop' || toolId == 'mask' || toolId == 'masks') {
      _transformationController.value = Matrix4.identity();
    }
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
          side: const BorderSide(color: LumaTheme.borderLight, width: 0.8),
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
                labelStyle: TextStyle(color: LumaTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: LumaTheme.borderSubtle),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: LumaTheme.primaryBlueLight),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: LumaTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: LumaTheme.borderSubtle),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: LumaTheme.primaryBlueLight),
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
              backgroundColor: LumaTheme.primaryBlue,
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
            backgroundColor: LumaTheme.charcoalSurface,
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
          side: const BorderSide(color: LumaTheme.borderLight, width: 0.8),
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
            color: LumaTheme.textSecondary,
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
              backgroundColor: LumaTheme.primaryBlue,
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

  Offset? _transformToImageCoords(Offset localPos, Size boxSize) {
    if (_basePreviewImage == null) return null;
    final scenePos = _transformationController.toScene(localPos);
    final isRotatedQuarter = _workingState.geometry.rotationQuarterTurns % 2 == 1;
    final aspect = isRotatedQuarter
        ? (_basePreviewImage!.height / _basePreviewImage!.width)
        : (_basePreviewImage!.width / _basePreviewImage!.height);
    final rect = ImageCoordinateTransformer.getDisplayRect(
      viewportSize: boxSize,
      imageAspectRatio: aspect,
    );
    if (rect.width <= 0 || rect.height <= 0) return null;
    final normX = ((scenePos.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final normY = ((scenePos.dy - rect.top) / rect.height).clamp(0.0, 1.0);
    return Offset(
      normX * _basePreviewImage!.width,
      normY * _basePreviewImage!.height,
    );
  }

  void _handleBrushPanStart(Offset localPos, Size boxSize) {
    if (_workingState.masks.isEmpty || _basePreviewImage == null) return;
    final idx = (_activeMaskIndex ?? 0).clamp(0, _workingState.masks.length - 1);
    final mask = _workingState.masks[idx];

    final maskW = _basePreviewImage!.width;
    final maskH = _basePreviewImage!.height;
    Uint8List buffer;
    if (mask.maskBytes != null && mask.maskWidth == maskW && mask.maskHeight == maskH) {
      buffer = Uint8List.fromList(mask.maskBytes!);
    } else {
      buffer = Uint8List(maskW * maskH);
    }

    _maskUndoStack.add(Uint8List.fromList(buffer));
    if (_maskUndoStack.length > 25) {
      _maskUndoStack.removeAt(0);
    }

    final pt = _transformToImageCoords(localPos, boxSize);
    if (pt == null) return;
    _lastStrokePoint = pt;

    _paintSegmentIntoMask(idx, buffer, pt, pt, maskW, maskH);
  }

  void _handleBrushPanUpdate(Offset localPos, Size boxSize) {
    if (_workingState.masks.isEmpty || _basePreviewImage == null) return;
    final idx = (_activeMaskIndex ?? 0).clamp(0, _workingState.masks.length - 1);
    final mask = _workingState.masks[idx];
    if (mask.maskBytes == null) return;

    final pt = _transformToImageCoords(localPos, boxSize);
    if (pt == null) return;
    final prev = _lastStrokePoint ?? pt;
    _lastStrokePoint = pt;

    final maskW = mask.maskWidth ?? _basePreviewImage!.width;
    final maskH = mask.maskHeight ?? _basePreviewImage!.height;
    final buffer = Uint8List.fromList(mask.maskBytes!);

    _paintSegmentIntoMask(idx, buffer, prev, pt, maskW, maskH);
  }

  void _handleBrushPanEnd() {
    _lastStrokePoint = null;
  }

  void _paintSegmentIntoMask(
    int maskIdx,
    Uint8List buffer,
    Offset p0,
    Offset p1,
    int width,
    int height,
  ) {
    MaskEngine.paintStrokeIntoBuffer(
      buffer: buffer,
      width: width,
      height: height,
      x0: p0.dx,
      y0: p0.dy,
      x1: p1.dx,
      y1: p1.dy,
      radius: _brushSize,
      hardness: _brushHardness,
      opacity: _brushOpacity,
      isErase: _isMaskEraseMode,
    );

    final updatedMask = _workingState.masks[maskIdx].copyWith(
      maskBytes: buffer,
      maskWidth: width,
      maskHeight: height,
    );

    final updatedList = List<SelectiveMask>.from(_workingState.masks);
    updatedList[maskIdx] = updatedMask;

    _requestRender(
      _workingState.copyWith(masks: updatedList, showMaskOverlay: true),
    );
  }

  void _handleUndoMaskStroke() {
    if (_maskUndoStack.isEmpty || _workingState.masks.isEmpty) return;
    final previousBuffer = _maskUndoStack.removeLast();
    final idx = (_activeMaskIndex ?? 0).clamp(0, _workingState.masks.length - 1);
    final mask = _workingState.masks[idx];
    final updatedMask = mask.copyWith(maskBytes: previousBuffer);
    final updatedList = List<SelectiveMask>.from(_workingState.masks);
    updatedList[idx] = updatedMask;
    _requestRender(_workingState.copyWith(masks: updatedList));
  }

  Future<void> _handleSelectSubject() async {
    if (_basePreviewImage == null) return;
    setState(() => _isSegmentingSubject = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await SubjectSegmentationService.segmentSubject(_basePreviewImage!);
      if (!mounted) return;

      final count = _workingState.masks.length + 1;
      final newMask = SelectiveMask(
        id: 'subject_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Subject $count',
        type: MaskType.subject,
        opacity: 1.0,
        density: 1.0,
        isVisible: true,
        maskBytes: result.maskBytes,
        maskWidth: result.width,
        maskHeight: result.height,
        adjustments: const MaskToneAdjustments(exposure: 15.0),
      );

      final updated = List<SelectiveMask>.from(_workingState.masks)..add(newMask);
      setState(() {
        _activeMaskIndex = updated.length - 1;
        _isSegmentingSubject = false;
      });

      _requestRender(
        _workingState.copyWith(masks: updated, showMaskOverlay: true),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSegmentingSubject = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subject selection failed: $e')),
      );
    }
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
        backgroundColor: LumaTheme.deepCanvas,
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

    return SafeArea(
      top: true,
      bottom: true,
      child: Column(
        children: [
          // 1. Sleek Liquid Glass Top Bar (Back, Undo, Redo, Compare, Export)
          _buildTopBar(),

          // 2. Responsive Center Canvas (Dominates Screen, Never Covered by Controls)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Center(
                child: _buildCanvasStack(),
              ),
            ),
          ),

          // 3. Bottom Controls: Docked Cleanly Below Canvas
          if (isToolOpen)
            _buildActiveToolSheet()
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildNeutralModeDock(),
            ),
        ],
      ),
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
              left: BorderSide(color: LumaTheme.border, width: 0.8),
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
            transformationController: _transformationController,
            panEnabled: _activeTool != 'crop' &&
                _activeTool != 'mask' &&
                _activeTool != 'masks' &&
                !_isBlemishModeActive,
            scaleEnabled: _activeTool != 'crop' &&
                _activeTool != 'mask' &&
                _activeTool != 'masks' &&
                !_isBlemishModeActive,
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
              color: LumaTheme.primaryBlue,
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
              imageAspectRatio: _basePreviewImage != null
                  ? ((_workingState.geometry.rotationQuarterTurns % 2 == 1)
                      ? (_basePreviewImage!.height / _basePreviewImage!.width)
                      : (_basePreviewImage!.width / _basePreviewImage!.height))
                  : 1.0,
              lockedAspectRatio: _selectedCropAspectRatio,
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
                  onPanDown: (d) => _handleBrushPanStart(d.localPosition, constraints.biggest),
                  onPanUpdate: (d) => _handleBrushPanUpdate(d.localPosition, constraints.biggest),
                  onPanEnd: (_) => _handleBrushPanEnd(),
                  onPanCancel: () => _handleBrushPanEnd(),
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
                  color: LumaTheme.primaryBlue.withValues(alpha: 0.5),
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
                      color: LumaTheme.primaryBlueLight,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PROCESSING',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: LumaTheme.primaryBlueLight,
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
                'LUMAFIX',
                style: LumaTheme.wordmarkStyle(
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
        child: LumaFloatingDock(
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

  // Active Tool Panel / Sheet (Compact Bottom Inspector with Zero Photo Occlusion)
  Widget _buildActiveToolSheet() {
    final panelContent = _getPanelWidget(_activeTool!);
    final maxPanelHeight = MediaQuery.sizeOf(context).height * 0.42;

    return LumaGlass(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      hasGrabHandle: _activeTool == 'filter',
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                  color: LumaTheme.coralRedLight,
                ),
                tooltip: 'Cancel',
                onPressed: _cancelToolChanges,
              ),
              Text(
                _getToolTitle(_activeTool!),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.check_rounded,
                  size: 22,
                  color: LumaTheme.primaryBlueLight,
                ),
                tooltip: 'Apply',
                onPressed: _applyToolChanges,
              ),
            ],
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxPanelHeight),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: panelContent,
            ),
          ),
        ],
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

        const Divider(color: LumaTheme.borderSubtle),

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
                              color: LumaTheme.primaryBlueLight,
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
                  child: LumaButton.secondary(
                    label: 'Reset Tool',
                    onPressed: _cancelToolChanges,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LumaButton(
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
    return LumaPillChip(
      label: label,
      isSelected: isSelected,
      onTap: () {
        if (id == 'crop' || id == 'mask' || id == 'masks') {
          _transformationController.value = Matrix4.identity();
        }
        setState(() => _activeTool = id);
      },
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
          imageAspectRatio: _basePreviewImage != null
              ? ((_workingState.geometry.rotationQuarterTurns % 2 == 1)
                  ? (_basePreviewImage!.height / _basePreviewImage!.width)
                  : (_basePreviewImage!.width / _basePreviewImage!.height))
              : 1.0,
          onAspectRatioChanged: (ratio) {
            setState(() => _selectedCropAspectRatio = ratio);
          },
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
          activeMaskIndex: _activeMaskIndex,
          onMasksChanged: (m) => _requestRender(_workingState.copyWith(masks: m)),
          onOverlayToggled: (ov) => _requestRender(_workingState.copyWith(showMaskOverlay: ov)),
          onActiveMaskChanged: (idx) => setState(() => _activeMaskIndex = idx),
          brushSize: _brushSize,
          brushHardness: _brushHardness,
          brushOpacity: _brushOpacity,
          isEraseMode: _isMaskEraseMode,
          onBrushSizeChanged: (v) => setState(() => _brushSize = v),
          onBrushHardnessChanged: (v) => setState(() => _brushHardness = v),
          onBrushOpacityChanged: (v) => setState(() => _brushOpacity = v),
          onEraseModeChanged: (v) => setState(() => _isMaskEraseMode = v),
          onUndoStroke: _handleUndoMaskStroke,
          canUndoStroke: _maskUndoStack.isNotEmpty,
          onSelectSubject: _handleSelectSubject,
          isSegmentingSubject: _isSegmentingSubject,
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
      ..color = LumaTheme.primaryBlueLight.withValues(alpha: 0.85)
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
