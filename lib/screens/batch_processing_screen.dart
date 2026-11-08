import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../core/presets/preset_catalogue.dart';
import '../services/export_service.dart';
import '../services/preset_repository.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/aevique_ui_components.dart';

enum BatchItemStatus {
  pending,
  processing,
  success,
  failed,
  cancelled,
}

class BatchImageItem {
  final String path;
  final String name;
  BatchItemStatus status;
  String? error;

  BatchImageItem({
    required this.path,
    required this.name,
    this.status = BatchItemStatus.pending,
    this.error,
  });
}

/// Professional Batch Processing screen for applying presets and exporting
/// multiple images with bounded sequential queue, live progress, and cancellation.
class BatchProcessingScreen extends StatefulWidget {
  final List<XFile>? initialFiles;
  final ExportService exportService;

  BatchProcessingScreen({
    super.key,
    this.initialFiles,
    ExportService? exportService,
  }) : exportService = exportService ?? DefaultExportService();

  @override
  State<BatchProcessingScreen> createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen> {
  final List<BatchImageItem> _items = [];
  final ImagePicker _picker = ImagePicker();

  PresetItem? _selectedBuiltInPreset;
  CustomPreset? _selectedCustomPreset;
  List<CustomPreset> _customPresets = [];

  bool _isProcessing = false;
  bool _isCancelled = false;
  int _completedCount = 0;
  int _failedCount = 0;
  String _currentProcessingName = '';

  final int _jpegQuality = 90;
  final bool _outputPng = false;
  int? _maxDimension; // null = original, 2048, 1080

  @override
  void initState() {
    super.initState();
    _selectedBuiltInPreset = PresetCatalogue.presets.first;
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      for (final f in widget.initialFiles!) {
        _items.add(BatchImageItem(path: f.path, name: f.name));
      }
    }
    _loadCustomPresets();
  }

  Future<void> _loadCustomPresets() async {
    final list = await PresetRepository.getCustomPresets();
    if (mounted) {
      setState(() => _customPresets = list);
    }
  }

  Future<void> _pickImages() async {
    HapticFeedback.lightImpact();
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          for (final f in picked) {
            _items.add(BatchImageItem(path: f.path, name: f.name));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  EditState get _effectiveState {
    if (_selectedCustomPreset != null) {
      return _selectedCustomPreset!.state;
    }
    if (_selectedBuiltInPreset != null) {
      return _selectedBuiltInPreset!.state;
    }
    return EditState.identity();
  }

  String get _presetDisplayName {
    if (_selectedCustomPreset != null) return _selectedCustomPreset!.name;
    if (_selectedBuiltInPreset != null) return _selectedBuiltInPreset!.name;
    return 'None';
  }

  Future<void> _startBatchProcessing() async {
    if (_items.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
      _isCancelled = false;
      _completedCount = 0;
      _failedCount = 0;
      for (final it in _items) {
        it.status = BatchItemStatus.pending;
        it.error = null;
      }
    });

    final stateToApply = _effectiveState;

    // Bounded sequential execution: process 1 photo at a time to prevent memory blowups!
    for (int i = 0; i < _items.length; i++) {
      if (_isCancelled) {
        for (int c = i; c < _items.length; c++) {
          _items[c].status = BatchItemStatus.cancelled;
        }
        break;
      }

      final item = _items[i];
      setState(() {
        item.status = BatchItemStatus.processing;
        _currentProcessingName = item.name;
      });

      try {
        final file = File(item.path);
        if (!await file.exists()) {
          throw Exception('Source file not found');
        }

        final bytes = await file.readAsBytes();

        // Process through non-destructive pipeline
        final processed = await ImagePipeline.processImage(
          bytes,
          stateToApply,
          maxDimension: _maxDimension,
          jpegQuality: _jpegQuality,
          outputPng: _outputPng,
        );

        // Save to gallery
        final saved = await widget.exportService.saveToGallery(
          processed,
          name: 'batch_${DateTime.now().millisecondsSinceEpoch}_$i',
        );

        if (!saved) {
          throw Exception('Gallery write permission or save failed');
        }

        item.status = BatchItemStatus.success;
        _completedCount++;
      } catch (e) {
        item.status = BatchItemStatus.failed;
        item.error = e.toString();
        _failedCount++;
      }

      if (mounted) setState(() {});
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _currentProcessingName = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCancelled
                ? 'Batch processing stopped. $_completedCount exported.'
                : 'Batch complete! $_completedCount exported successfully'
                    '${_failedCount > 0 ? ', $_failedCount failed' : ''}.',
          ),
          backgroundColor: _failedCount > 0 ? AeviqueTheme.creativeOrange : AeviqueTheme.charcoalSurface,
        ),
      );
    }
  }

  void _cancelBatch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isCancelled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.length;
    final progress = total > 0 ? (_completedCount + _failedCount) / total : 0.0;

    return Scaffold(
      backgroundColor: AeviqueTheme.deepCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'BATCH PROCESSING',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isProcessing)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: AeviqueTheme.primaryBlueLight),
              tooltip: 'Add Photos',
              onPressed: _pickImages,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preset Selection Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AeviqueGlass(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Applied Preset:',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AeviqueTheme.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AeviqueTheme.primaryBlue.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AeviqueTheme.primaryBlueLight, width: 0.8),
                          ),
                          child: Text(
                            _presetDisplayName,
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
                    const SizedBox(height: 10),

                    // Horizontal Preset Chips Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...PresetCatalogue.presets.map((p) {
                            final isSel = _selectedBuiltInPreset == p && _selectedCustomPreset == null;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AeviquePillChip(
                                label: p.name,
                                isSelected: isSel,
                                onTap: _isProcessing
                                    ? () {}
                                    : () {
                                        setState(() {
                                          _selectedBuiltInPreset = p;
                                          _selectedCustomPreset = null;
                                        });
                                      },
                              ),
                            );
                          }),
                          ..._customPresets.map((cp) {
                            final isSel = _selectedCustomPreset == cp;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AeviquePillChip(
                                label: cp.name,
                                isSelected: isSel,
                                onTap: _isProcessing
                                    ? () {}
                                    : () {
                                        setState(() {
                                          _selectedCustomPreset = cp;
                                          _selectedBuiltInPreset = null;
                                        });
                                      },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Live Progress Indicator (active during processing)
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: AeviqueGlass(
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Processing ${_completedCount + _failedCount + 1} of $total...',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AeviqueTheme.primaryBlueLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(AeviqueTheme.primaryBlue),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentProcessingName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AeviqueTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Photos Queue List
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_outlined, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text(
                            'No photos selected for batch processing',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AeviqueButton(
                            label: 'Select Photos',
                            icon: Icons.add_photo_alternate_rounded,
                            onPressed: _pickImages,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        Widget statusIcon;
                        switch (item.status) {
                          case BatchItemStatus.pending:
                            statusIcon = const Icon(Icons.schedule_rounded, size: 18, color: Colors.white38);
                            break;
                          case BatchItemStatus.processing:
                            statusIcon = const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AeviqueTheme.primaryBlueLight,
                              ),
                            );
                            break;
                          case BatchItemStatus.success:
                            statusIcon = const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF10B981));
                            break;
                          case BatchItemStatus.failed:
                            statusIcon = const Icon(Icons.error_outline_rounded, size: 18, color: AeviqueTheme.coralRedLight);
                            break;
                          case BatchItemStatus.cancelled:
                            statusIcon = const Icon(Icons.cancel_outlined, size: 18, color: Colors.white38);
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x3314141C),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AeviqueTheme.borderSubtle, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(item.path),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.white12,
                                    child: const Icon(Icons.image, size: 20, color: Colors.white38),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (item.error != null)
                                      Text(
                                        item.error!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 10,
                                          color: AeviqueTheme.coralRedLight,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              statusIcon,
                              if (!_isProcessing) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _items.removeAt(index));
                                  },
                                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Actions Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _isProcessing
                  ? AeviqueButton.secondary(
                      label: 'Cancel Batch Processing',
                      icon: Icons.stop_rounded,
                      onPressed: _cancelBatch,
                    )
                  : Row(
                      children: [
                        if (_items.isNotEmpty)
                          Expanded(
                            child: AeviqueButton.secondary(
                              label: 'Clear List',
                              onPressed: () => setState(() => _items.clear()),
                            ),
                          ),
                        if (_items.isNotEmpty) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AeviqueButton(
                            label: 'Export ${_items.length} Photos',
                            icon: Icons.bolt_rounded,
                            onPressed: _items.isEmpty ? null : _startBatchProcessing,
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
}
