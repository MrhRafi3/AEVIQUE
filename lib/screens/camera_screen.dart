import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/aevique_theme.dart';
import '../widgets/aevique_glass.dart';
import '../widgets/liquid_glass_components.dart';
import 'editor_screen.dart';

/// Real Camera Screen for AEVIQUE.
///
/// Features:
/// - Real camera viewfinder preview via [CameraController].
/// - Front / rear camera lens switching where hardware allows.
/// - Flash mode controls (Off, Auto, On).
/// - Instant capture directly to [EditorScreen].
/// - Graceful handling for permission denial and desktop/unavailable camera hardware.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.auto;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No camera hardware detected on this device.';
        });
        return;
      }

      // Default to rear camera if present
      int defaultIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (defaultIndex == -1) defaultIndex = 0;
      _selectedCameraIndex = defaultIndex;

      await _initCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Camera initialization failed or access was denied: $e';
      });
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    final prevController = _controller;
    _controller = null;
    await prevController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_currentFlashMode);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Unable to access camera: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;
    HapticFeedback.mediumImpact();
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    setState(() => _isInitializing = true);
    await _initCameraController(_cameras[nextIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    HapticFeedback.selectionClick();

    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
      default:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await controller.setFlashMode(nextMode);
      setState(() => _currentFlashMode = nextMode);
    } catch (_) {}
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isCapturing = true);

    try {
      final xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EditorScreen(
            initialImageBytes: bytes,
            imageName: 'Capture_${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture photo: $e'),
          backgroundColor: AeviqueTheme.coralRed,
        ),
      );
    }
  }

  Future<void> _fallbackPickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 4096,
      maxHeight: 4096,
    );
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              EditorScreen(initialImageBytes: bytes, imageName: 'Camera Photo'),
        ),
      );
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.off:
      default:
        return Icons.flash_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview or Fallback View
          if (_controller != null && _controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(
                color: AeviqueTheme.primaryBlue,
                strokeWidth: 2.5,
              ),
            )
          else
            _buildUnavailableCameraView(),

          // 2. Top Controls Bar (Liquid Glass)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LiquidGlassPanel(
                      variant: LiquidGlassVariant.ultraClear,
                      borderRadius: BorderRadius.circular(
                        AeviqueTheme.radiusFull,
                      ),
                      blur: 20.0,
                      onTap: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(10.0),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    Row(
                      children: [
                        if (_controller != null) ...[
                          LiquidGlassPanel(
                            variant: LiquidGlassVariant.ultraClear,
                            borderRadius: BorderRadius.circular(
                              AeviqueTheme.radiusFull,
                            ),
                            blur: 20.0,
                            onTap: _toggleFlash,
                            padding: const EdgeInsets.all(10.0),
                            child: Icon(
                              _getFlashIcon(),
                              color: _currentFlashMode != FlashMode.off
                                  ? AeviqueTheme.creativeOrange
                                  : Colors.white70,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_cameras.length > 1)
                            LiquidGlassPanel(
                              variant: LiquidGlassVariant.ultraClear,
                              borderRadius: BorderRadius.circular(
                                AeviqueTheme.radiusFull,
                              ),
                              blur: 20.0,
                              onTap: _switchCamera,
                              padding: const EdgeInsets.all(10.0),
                              child: const Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Shutter Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 24.0,
                  left: 32.0,
                  right: 32.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode Tag Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(
                          AeviqueTheme.radiusFull,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'PHOTO',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: AeviqueTheme.creativeOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Shutter Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 48), // spacer
                        GestureDetector(
                          onTap: _controller != null
                              ? _capturePhoto
                              : _fallbackPickImage,
                          child: Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                                width: 4.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AeviqueTheme.primaryBlueGlow,
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(5),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF5E98FC),
                                    Color(0xFF3478F6),
                                    Color(0xFF1E5AD6),
                                  ],
                                ),
                              ),
                              child: _isCapturing
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // spacer
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableCameraView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: LiquidGlassPanel(
          variant: LiquidGlassVariant.modal,
          borderRadius: BorderRadius.circular(AeviqueTheme.radiusXl),
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x333478F6),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AeviqueTheme.primaryBlueLight,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Camera Hardware Offline',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ??
                    'Live camera viewfinder is unavailable on this platform environment. You can take a photo through system interface or select a high-resolution image.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AeviqueTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              LiquidGlassButton(
                label: 'System Camera / Capture',
                icon: Icons.photo_camera_rounded,
                variant: LiquidGlassButtonVariant.primaryBlue,
                onPressed: _fallbackPickImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
