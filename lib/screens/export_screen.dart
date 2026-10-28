import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../services/export_service.dart';
import '../theme/aevique_theme.dart';

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
  int _activeRenderId = 0;

  bool _outputPng = false;
  double _quality = 92.0;

  @override
  void initState() {
    super.initState();
    _renderFullResolution();
  }

  Future<void> _renderFullResolution() async {
    final renderId = ++_activeRenderId;
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

      if (!mounted || renderId != _activeRenderId) return;
      setState(() {
        _exportedBytes = result;
        _isRendering = false;
        _statusMessage = null;
      });
    } catch (e) {
      if (!mounted || renderId != _activeRenderId) return;
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
      name: 'aevique_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFF34D399)),
              SizedBox(width: 8),
              Text('Photo saved to gallery successfully!'),
            ],
          ),
          backgroundColor: AeviqueTheme.elevatedCharcoal,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save photo. Check photo permissions.'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
    }
  }

  Future<void> _handleShare() async {
    if (_exportedBytes == null) return;
    final success = await widget.exportService.shareImage(
      _exportedBytes!,
      name: 'aevique_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open share sheet'),
          backgroundColor: Color(0xFFEF5350),
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
      backgroundColor: AeviqueTheme.deepBlack,
      appBar: AppBar(
        backgroundColor: AeviqueTheme.deepBlack,
        elevation: 0,
        title: Text(
          'EXPORT PHOTO',
          style: AeviqueTheme.wordmarkStyle(
            fontSize: 16,
            letterSpacing: 2.5,
            color: AeviqueTheme.ivory,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AeviqueTheme.ivory),
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
                            color: AeviqueTheme.champagneGold,
                            strokeWidth: 2.5,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage ?? 'Processing...',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AeviqueTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : _exportedBytes != null
                    ? Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AeviqueTheme.champagneGold.withValues(
                              alpha: 0.3,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 20,
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
                        style: const TextStyle(color: Color(0xFFEF5350)),
                      ),
              ),
            ),

            // Export settings and actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AeviqueTheme.charcoalSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AeviqueTheme.border, width: 1),
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
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AeviqueTheme.ivory,
                        ),
                      ),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('JPEG'),
                            selected: !_outputPng,
                            selectedColor: AeviqueTheme.champagneGold,
                            backgroundColor: AeviqueTheme.elevatedCharcoal,
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: !_outputPng
                                  ? AeviqueTheme.deepBlack
                                  : AeviqueTheme.ivory,
                            ),
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
                            selectedColor: AeviqueTheme.champagneGold,
                            backgroundColor: AeviqueTheme.elevatedCharcoal,
                            labelStyle: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: _outputPng
                                  ? AeviqueTheme.deepBlack
                                  : AeviqueTheme.ivory,
                            ),
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'JPEG Quality',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AeviqueTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${_quality.round()}%',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AeviqueTheme.champagneGold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _quality,
                      min: 50.0,
                      max: 100.0,
                      divisions: 50,
                      activeColor: AeviqueTheme.champagneGold,
                      inactiveColor: AeviqueTheme.elevatedCharcoal,
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
                          color: AeviqueTheme.slateGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rendered size: ${_formatFileSize(_exportedBytes!.length)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AeviqueTheme.slateGray,
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
                              color: AeviqueTheme.borderLight,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: AeviqueTheme.ivory,
                          ),
                          label: const Text(
                            'Share',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: AeviqueTheme.ivory,
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
                            backgroundColor: AeviqueTheme.champagneGold,
                            foregroundColor: AeviqueTheme.deepBlack,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AeviqueTheme.deepBlack,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Save to Photos',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
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
