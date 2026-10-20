import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../services/export_service.dart';
import '../theme/luma_theme.dart';

class ExportScreen extends StatefulWidget {
  final Uint8List sourceBytes;
  final EditState state;
  final ExportService exportService;

  ExportScreen({
    super.key,
    required this.sourceBytes,
    required this.state,
    ExportService? exportService,
  }) : exportService = exportService ?? DefaultExportService();

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isRendering = false;
  bool _isSaving = false;
  Uint8List? _exportedBytes;
  String? _statusMessage;

  bool _outputPng = false;
  double _quality = 92.0;

  @override
  void initState() {
    super.initState();
    _renderFullResolution();
  }

  Future<void> _renderFullResolution() async {
    setState(() {
      _isRendering = true;
      _statusMessage = 'Rendering full-resolution photo...';
    });

    try {
      final result = await ImagePipeline.processImage(
        widget.sourceBytes,
        widget.state,
        jpegQuality: _quality.round(),
        outputPng: _outputPng,
      );

      if (!mounted) return;
      setState(() {
        _exportedBytes = result;
        _isRendering = false;
        _statusMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRendering = false;
        _statusMessage = 'Render failed: $e';
      });
    }
  }

  Future<void> _handleSave() async {
    if (_exportedBytes == null) return;
    setState(() => _isSaving = true);

    final success = await widget.exportService.saveToGallery(
      _exportedBytes!,
      name: 'lumaforge_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: LumaTheme.accentGreen),
              SizedBox(width: 8),
              Text('Photo saved to gallery successfully!'),
            ],
          ),
          backgroundColor: LumaTheme.surfaceElevated,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save photo. Check photo permissions.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleShare() async {
    if (_exportedBytes == null) return;
    final success = await widget.exportService.shareImage(
      _exportedBytes!,
      name: 'lumaforge_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open share sheet'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumaTheme.background,
      appBar: AppBar(
        title: const Text(
          'Export Photo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview thumbnail
            Expanded(
              child: Center(
                child: _isRendering
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: LumaTheme.accent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage ?? 'Processing...',
                            style: const TextStyle(
                              color: LumaTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : _exportedBytes != null
                    ? Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.memory(
                          _exportedBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Text(
                        _statusMessage ?? 'Render Error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
              ),
            ),

            // Export settings and actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: LumaTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: LumaTheme.border, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Format Selector (JPEG vs PNG)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Format',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: LumaTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('JPEG'),
                            selected: !_outputPng,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _outputPng = false);
                                _renderFullResolution();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('PNG'),
                            selected: _outputPng,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _outputPng = true);
                                _renderFullResolution();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // JPEG Quality Slider
                  if (!_outputPng) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'JPEG Quality',
                          style: TextStyle(
                            fontSize: 13,
                            color: LumaTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${_quality.round()}%',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: LumaTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _quality,
                      min: 50.0,
                      max: 100.0,
                      divisions: 50,
                      onChanged: (v) => setState(() => _quality = v),
                      onChangeEnd: (_) => _renderFullResolution(),
                    ),
                  ],

                  // File size readout
                  if (_exportedBytes != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.data_usage_rounded,
                          size: 14,
                          color: LumaTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rendered size: ${_formatFileSize(_exportedBytes!.length)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: LumaTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Buttons: Save to Photos & Share
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: LumaTheme.borderLight,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: LumaTheme.textPrimary,
                          ),
                          label: const Text(
                            'Share',
                            style: TextStyle(
                              color: LumaTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: _exportedBytes != null
                              ? _handleShare
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LumaTheme.accent,
                            foregroundColor: LumaTheme.background,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: LumaTheme.background,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save to Photos',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: (_exportedBytes != null && !_isSaving)
                              ? _handleSave
                              : null,
                        ),
                      ),
                    ],
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
