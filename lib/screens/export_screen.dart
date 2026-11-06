import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/image_engine/image_pipeline.dart';
import '../core/models/edit_state.dart';
import '../services/export_service.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/aevique_ui_components.dart';

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
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    final success = await widget.exportService.saveToGallery(
      _exportedBytes!,
      name: 'aevique_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Photo saved to gallery successfully!' : 'Failed to save photograph.'),
        backgroundColor: success ? AeviqueTheme.charcoalSurface : AeviqueTheme.error,
      ),
    );
  }

  Future<void> _handleShare() async {
    if (_exportedBytes == null) return;
    HapticFeedback.lightImpact();
    await widget.exportService.shareImage(
      _exportedBytes!,
      name: 'aevique_${DateTime.now().millisecondsSinceEpoch}',
    );
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
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'EXPORT PHOTO',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32), // Balance close button
                ],
              ),
            ),

            // Large Image Preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Center(
                  child: _isRendering
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AeviqueTheme.accentAmber,
                              strokeWidth: 2.0,
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
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 32,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.memory(_exportedBytes!, fit: BoxFit.contain),
                            )
                          : const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white24),
                ),
              ),
            ),

            // Translucent Control Sheet
            AeviqueGlass(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Format Selector (JPEG vs PNG)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AeviquePillChip(
                        label: 'JPEG',
                        isSelected: !_outputPng,
                        onTap: () {
                          if (_outputPng) {
                            setState(() => _outputPng = false);
                            _renderFullResolution();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      AeviquePillChip(
                        label: 'PNG',
                        isSelected: _outputPng,
                        onTap: () {
                          if (!_outputPng) {
                            setState(() => _outputPng = true);
                            _renderFullResolution();
                          }
                        },
                      ),
                    ],
                  ),

                  // Quality Slider (if JPEG)
                  if (!_outputPng) ...[
                    const SizedBox(height: 12),
                    AeviquePrecisionSlider(
                      label: 'JPEG Quality',
                      value: _quality,
                      min: 50.0,
                      max: 100.0,
                      valueFormatter: (v) => '${v.round()}%',
                      onChanged: (val) {
                        setState(() => _quality = val);
                      },
                      onReset: () {
                        setState(() => _quality = 92.0);
                        _renderFullResolution();
                      },
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Metrics Row
                  if (_exportedBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: Text(
                              'Size: ${_formatFileSize(_exportedBytes!.lengthInBytes)}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AeviqueTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Format: ${_outputPng ? "PNG" : "JPEG ${_quality.round()}%"}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AeviqueTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Action Buttons: Save & Share
                  Row(
                    children: [
                      Expanded(
                        child: AeviqueButton.secondary(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onPressed: _exportedBytes != null && !_isRendering ? _handleShare : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AeviqueButton(
                          icon: Icons.download_rounded,
                          label: 'Save to Photos',
                          isLoading: _isSaving,
                          onPressed: _exportedBytes != null && !_isRendering ? _handleSave : null,
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
