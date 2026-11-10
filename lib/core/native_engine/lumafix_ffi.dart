import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import '../models/edit_state.dart';

/// Engine execution mode for LumaFix image engine.
enum EngineMode {
  /// Automatically uses native C++ when available and compatible, falling back to Dart.
  auto,

  /// Forces native C++ execution only; fails if unavailable.
  nativeOnly,

  /// Forces pure Dart execution; native engine is bypassed.
  dartOnly,
}

/// Status codes matching LumaFixStatus in lumafix_engine.h
class LumaFixStatusCode {
  static const int success = 0;
  static const int errorNullPointer = -1;
  static const int errorInvalidDimensions = -2;
  static const int errorInvalidStride = -3;
  static const int errorUnsupportedFormat = -4;
  static const int errorInvalidParameter = -5;
  static const int errorBufferTooSmall = -6;
  static const int errorUnknown = -99;
}

/// Pixel format enum matching LumaFixPixelFormat
class LumaFixPixelFormat {
  static const int rgba8888 = 0;
  static const int bgra8888 = 1;
  static const int rgb888 = 2;
}

/// Image buffer struct matching LumaFixImageBuffer in lumafix_engine.h
final class LumaFixImageBuffer extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> data;

  @ffi.Int32()
  external int width;

  @ffi.Int32()
  external int height;

  @ffi.Int32()
  external int strideBytes;

  @ffi.Int32()
  external int format;
}

/// Tone adjustment parameters struct matching LumaFixToneParameters
final class LumaFixToneParameters extends ffi.Struct {
  @ffi.Float()
  external double exposure;

  @ffi.Float()
  external double contrast;

  @ffi.Float()
  external double saturation;
}

/// Single control point on a 2D spline curve
final class LumaFixCurvePoint extends ffi.Struct {
  @ffi.Float()
  external double x;

  @ffi.Float()
  external double y;
}

/// Control point channel containing an array of points and point count
final class LumaFixCurveChannel extends ffi.Struct {
  external ffi.Pointer<LumaFixCurvePoint> points;

  @ffi.Int32()
  external int pointCount;
}

/// Quad-channel tone curves struct matching LumaFixToneCurves
final class LumaFixToneCurves extends ffi.Struct {
  external LumaFixCurveChannel rgb;
  external LumaFixCurveChannel red;
  external LumaFixCurveChannel green;
  external LumaFixCurveChannel blue;
}

/// Advanced tone parameters struct matching LumaFixAdvancedToneParameters
final class LumaFixAdvancedToneParameters extends ffi.Struct {
  @ffi.Float()
  external double exposure;

  @ffi.Float()
  external double contrast;

  @ffi.Float()
  external double saturation;

  @ffi.Float()
  external double brightness;

  @ffi.Float()
  external double warmth;

  @ffi.Float()
  external double tint;

  @ffi.Float()
  external double highlights;

  @ffi.Float()
  external double shadows;

  @ffi.Float()
  external double whites;

  @ffi.Float()
  external double blacks;

  @ffi.Float()
  external double ambiance;
}

/// Vignette parameters struct matching LumaFixVignetteParameters
final class LumaFixVignetteParameters extends ffi.Struct {
  @ffi.Float()
  external double amount;

  @ffi.Float()
  external double radius;

  @ffi.Float()
  external double feather;

  @ffi.Float()
  external double centerX;

  @ffi.Float()
  external double centerY;
}

/// Single color band HSL adjustments matching LumaFixHslBand
final class LumaFixHslBand extends ffi.Struct {
  @ffi.Float()
  external double hue;

  @ffi.Float()
  external double saturation;

  @ffi.Float()
  external double luminance;
}

/// 8-channel HSL Color Mixer matching LumaFixHslParameters
final class LumaFixHslParameters extends ffi.Struct {
  external LumaFixHslBand red;
  external LumaFixHslBand orange;
  external LumaFixHslBand yellow;
  external LumaFixHslBand green;
  external LumaFixHslBand aqua;
  external LumaFixHslBand blue;
  external LumaFixHslBand purple;
  external LumaFixHslBand magenta;
}

/// Effects parameters struct matching LumaFixEffectsParameters
final class LumaFixEffectsParameters extends ffi.Struct {
  @ffi.Int32()
  external int bwMode;

  @ffi.Float()
  external double grain;

  @ffi.Float()
  external double vintage;

  @ffi.Float()
  external double drama;

  @ffi.Float()
  external double bloom;

  @ffi.Float()
  external double glow;

  @ffi.Float()
  external double chromaticAberration;

  @ffi.Float()
  external double lensBlur;
}

/// Unified pipeline parameters struct matching LumaFixPipelineParameters
final class LumaFixPipelineParameters extends ffi.Struct {
  external LumaFixAdvancedToneParameters tone;

  @ffi.Float()
  external double vibrance;

  @ffi.Float()
  external double clarity;

  external LumaFixHslParameters hsl;

  external LumaFixEffectsParameters effects;

  external LumaFixVignetteParameters vignette;

  @ffi.Float()
  external double structure;

  @ffi.Float()
  external double sharpening;
}

// C function signatures
typedef _GetVersionC = ffi.Uint32 Function();
typedef _GetVersionDart = int Function();

typedef _StatusToStringC = ffi.Pointer<Utf8> Function(ffi.Int32 status);
typedef _StatusToStringDart = ffi.Pointer<Utf8> Function(int status);

typedef _ProcessToneC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixToneParameters> params,
    );
typedef _ProcessToneDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixToneParameters> params,
    );

typedef _ProcessAdvancedToneC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixAdvancedToneParameters> params,
      ffi.Pointer<LumaFixToneCurves> curves,
    );
typedef _ProcessAdvancedToneDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixAdvancedToneParameters> params,
      ffi.Pointer<LumaFixToneCurves> curves,
    );

typedef _ProcessPipelineC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixPipelineParameters> params,
      ffi.Pointer<LumaFixToneCurves> curves,
    );
typedef _ProcessPipelineDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixPipelineParameters> params,
      ffi.Pointer<LumaFixToneCurves> curves,
    );

typedef _ProcessVibranceC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Float vibrance,
    );
typedef _ProcessVibranceDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      double vibrance,
    );

typedef _ProcessClarityC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Float clarity,
    );
typedef _ProcessClarityDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      double clarity,
    );

typedef _ProcessMonochromeC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Float saturation,
      ffi.Int32 bwMode,
    );
typedef _ProcessMonochromeDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      double saturation,
      int bwMode,
    );

typedef _ProcessVignetteC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixVignetteParameters> params,
    );
typedef _ProcessVignetteDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixVignetteParameters> params,
    );

typedef _ProcessHslC =
    ffi.Int32 Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixHslParameters> params,
    );
typedef _ProcessHslDart =
    int Function(
      ffi.Pointer<LumaFixImageBuffer> src,
      ffi.Pointer<LumaFixImageBuffer> dst,
      ffi.Pointer<LumaFixHslParameters> params,
    );

/// Safe, high-level Dart FFI wrapper for LumaFix native C++ engine.
class LumaFixNativeEngine {
  /// Global engine execution mode.
  static EngineMode engineMode = EngineMode.auto;

  /// Cached active library path used across isolate boundaries.
  static String? activeLibraryPath;

  /// Cached singleton instance of the native engine.
  static LumaFixNativeEngine? _instance;

  /// Gets the currently loaded native engine instance, if available.
  static LumaFixNativeEngine? get instance => _instance;

  /// Returns true if the native engine is loaded and engineMode permits native execution.
  static bool get isAvailable =>
      _instance != null && engineMode != EngineMode.dartOnly;

  /// Tries to load the native engine dynamic library safely.
  /// Returns `true` if successful, `false` otherwise without throwing.
  static bool tryLoad({String? customLibraryPath}) {
    try {
      _instance = LumaFixNativeEngine.load(
        customLibraryPath: customLibraryPath,
      );
      if (kDebugMode) {
        final ver = _instance!.getVersion();
        final major = (ver >> 16) & 0xFF;
        final minor = (ver >> 8) & 0xFF;
        final patch = ver & 0xFF;
        debugPrint(
          '[LUMAFIX-NATIVE] Dynamic library loaded: "$activeLibraryPath" (core v$major.$minor.$patch, mode: $engineMode)',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[LUMAFIX-NATIVE] Dynamic library load failed: $e (path: "$customLibraryPath")',
        );
      }
      // In production or test environments where native dylib is absent, fall back gracefully
      _instance = null;
      return false;
    }
  }

  /// Sets the active native engine instance directly (used for testing or custom lifecycles).
  static void setInstance(LumaFixNativeEngine? engine) {
    _instance = engine;
  }

  final ffi.DynamicLibrary _dylib;
  late final _GetVersionDart _getVersion;
  late final _StatusToStringDart _statusToString;
  late final _ProcessToneDart _processTone;
  late final _ProcessAdvancedToneDart _processAdvancedTone;
  late final _ProcessPipelineDart _processPipeline;
  late final _ProcessVibranceDart _processVibrance;
  late final _ProcessClarityDart _processClarity;
  late final _ProcessMonochromeDart _processMonochrome;
  late final _ProcessVignetteDart _processVignette;
  late final _ProcessHslDart _processHsl;

  LumaFixNativeEngine._(this._dylib) {
    _getVersion = _dylib.lookupFunction<_GetVersionC, _GetVersionDart>(
      'lumafix_get_version',
    );
    _statusToString = _dylib
        .lookupFunction<_StatusToStringC, _StatusToStringDart>(
          'lumafix_status_to_string',
        );
    _processTone = _dylib.lookupFunction<_ProcessToneC, _ProcessToneDart>(
      'lumafix_process_tone_rgba8',
    );
    _processAdvancedTone = _dylib
        .lookupFunction<_ProcessAdvancedToneC, _ProcessAdvancedToneDart>(
          'lumafix_process_advanced_tone_rgba8',
        );
    _processPipeline = _dylib
        .lookupFunction<_ProcessPipelineC, _ProcessPipelineDart>(
          'lumafix_process_pipeline_rgba8',
        );
    _processVibrance = _dylib
        .lookupFunction<_ProcessVibranceC, _ProcessVibranceDart>(
          'lumafix_process_vibrance_rgba8',
        );
    _processClarity = _dylib
        .lookupFunction<_ProcessClarityC, _ProcessClarityDart>(
          'lumafix_process_clarity_rgba8',
        );
    _processMonochrome = _dylib
        .lookupFunction<_ProcessMonochromeC, _ProcessMonochromeDart>(
          'lumafix_process_monochrome_rgba8',
        );
    _processVignette = _dylib
        .lookupFunction<_ProcessVignetteC, _ProcessVignetteDart>(
          'lumafix_process_vignette_rgba8',
        );
    _processHsl = _dylib.lookupFunction<_ProcessHslC, _ProcessHslDart>(
      'lumafix_process_hsl_rgba8',
    );
  }

  /// Loads the LumaFix native engine dynamic library.
  /// If [customLibraryPath] is omitted, standard build locations are checked.
  factory LumaFixNativeEngine.load({String? customLibraryPath}) {
    ffi.DynamicLibrary dylib;
    if (customLibraryPath != null && customLibraryPath.isNotEmpty) {
      dylib = ffi.DynamicLibrary.open(customLibraryPath);
      activeLibraryPath = customLibraryPath;
    } else if (Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final defaultPaths = [
        'native/lumafix_core/build/liblumafix_core.dylib',
        '../native/lumafix_core/build/liblumafix_core.dylib',
        '$exeDir/../Frameworks/liblumafix_core.dylib',
        'liblumafix_core.dylib',
      ];
      String? foundPath;
      for (final p in defaultPaths) {
        if (File(p).existsSync()) {
          foundPath = p;
          break;
        }
      }
      final resolved = foundPath ?? 'liblumafix_core.dylib';
      dylib = ffi.DynamicLibrary.open(resolved);
      activeLibraryPath = resolved;
    } else if (Platform.isLinux || Platform.isAndroid) {
      const libName = 'liblumafix_core.so';
      dylib = ffi.DynamicLibrary.open(libName);
      activeLibraryPath = libName;
    } else if (Platform.isWindows) {
      const libName = 'lumafix_core.dll';
      dylib = ffi.DynamicLibrary.open(libName);
      activeLibraryPath = libName;
    } else {
      throw UnsupportedError(
        'Unsupported operating system for LumaFixNativeEngine: ${Platform.operatingSystem}',
      );
    }

    return LumaFixNativeEngine._(dylib);
  }

  /// Returns the version integer encoded as (major << 16) | (minor << 8) | patch.
  int getVersion() => _getVersion();

  /// Returns human-readable status string for an error code.
  String getStatusString(int status) {
    final ptr = _statusToString(status);
    return ptr.toDartString();
  }

  /// Calls the low-level C ABI function `lumafix_process_tone_rgba8`.
  int processToneRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required ffi.Pointer<LumaFixToneParameters> params,
  }) {
    return _processTone(src, dst, params);
  }

  /// Calls the low-level C ABI function `lumafix_process_advanced_tone_rgba8`.
  int processAdvancedToneRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required ffi.Pointer<LumaFixAdvancedToneParameters> params,
    ffi.Pointer<LumaFixToneCurves>? curves,
  }) {
    return _processAdvancedTone(
      src,
      dst,
      params,
      curves ?? ffi.Pointer.fromAddress(0),
    );
  }

  /// Calls the low-level C ABI function `lumafix_process_pipeline_rgba8`.
  int processPipelineRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required ffi.Pointer<LumaFixPipelineParameters> params,
    ffi.Pointer<LumaFixToneCurves>? curves,
  }) {
    return _processPipeline(
      src,
      dst,
      params,
      curves ?? ffi.Pointer.fromAddress(0),
    );
  }

  /// Calls the low-level C ABI function `lumafix_process_vibrance_rgba8`.
  int processVibranceRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required double vibrance,
  }) {
    return _processVibrance(src, dst, vibrance);
  }

  /// Calls the low-level C ABI function `lumafix_process_clarity_rgba8`.
  int processClarityRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required double clarity,
  }) {
    return _processClarity(src, dst, clarity);
  }

  /// Calls the low-level C ABI function `lumafix_process_monochrome_rgba8`.
  int processMonochromeRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required double saturation,
    required int bwMode,
  }) {
    return _processMonochrome(src, dst, saturation, bwMode);
  }

  /// Calls the low-level C ABI function `lumafix_process_vignette_rgba8`.
  int processVignetteRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required ffi.Pointer<LumaFixVignetteParameters> params,
  }) {
    return _processVignette(src, dst, params);
  }

  /// Calls the low-level C ABI function `lumafix_process_hsl_rgba8`.
  int processHslRaw({
    required ffi.Pointer<LumaFixImageBuffer> src,
    required ffi.Pointer<LumaFixImageBuffer> dst,
    required ffi.Pointer<LumaFixHslParameters> params,
  }) {
    return _processHsl(src, dst, params);
  }

  static void _copyHslBand(LumaFixHslBand dst, HslChannelAdjustment src) {
    dst.hue = src.hue;
    dst.saturation = src.saturation;
    dst.luminance = src.luminance;
  }

  static ffi.Pointer<LumaFixCurvePoint> _allocateCurvePoints(
    List<CurvePoint> points,
  ) {
    if (points.isEmpty) return ffi.Pointer.fromAddress(0);
    final ptr = calloc<LumaFixCurvePoint>(points.length);
    for (int i = 0; i < points.length; i++) {
      ptr[i].x = points[i].x;
      ptr[i].y = points[i].y;
    }
    return ptr;
  }

  /// High-level utility: processes raw RGBA8 image bytes through the native engine.
  /// Caller provides [rgbaBytes], [width], and [height].
  /// Supports Exposure, Contrast, Saturation, Brightness, Warmth, Tint, Highlights,
  /// Shadows, Whites, Blacks, Ambiance, and Tone Curves.
  /// If [inPlace] is true, [rgbaBytes] is modified in-place and returned.
  Uint8List processRgba8({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    double exposure = 0.0,
    double contrast = 0.0,
    double saturation = 0.0,
    double brightness = 0.0,
    double warmth = 0.0,
    double tint = 0.0,
    double highlights = 0.0,
    double shadows = 0.0,
    double whites = 0.0,
    double blacks = 0.0,
    double ambiance = 0.0,
    ToneCurves? curves,
    bool inPlace = false,
    int numChannels = 4,
  }) {
    if (width <= 0 || height <= 0 || width > 65536 || height > 65536) {
      throw ArgumentError(
        'Invalid image dimensions for native processing: ${width}x$height',
      );
    }
    if (numChannels != 3 && numChannels != 4) {
      throw ArgumentError(
        'Only 3-channel (RGB) or 4-channel (RGBA) buffers are supported: $numChannels',
      );
    }

    final totalBytes = width * height * numChannels;
    if (rgbaBytes.lengthInBytes < totalBytes) {
      throw ArgumentError(
        'Input byte array length (${rgbaBytes.lengthInBytes}) is smaller than required ($totalBytes) for ${width}x$height x $numChannels channels',
      );
    }

    // Allocate native buffers using calloc
    final srcDataPtr = calloc<ffi.Uint8>(totalBytes);
    final dstDataPtr = inPlace ? srcDataPtr : calloc<ffi.Uint8>(totalBytes);
    if (srcDataPtr.address == 0 || dstDataPtr.address == 0) {
      if (srcDataPtr.address != 0) calloc.free(srcDataPtr);
      if (!inPlace && dstDataPtr.address != 0) calloc.free(dstDataPtr);
      throw OutOfMemoryError();
    }

    // Copy input bytes into native memory via high-speed memory block copy
    final nativeView = srcDataPtr.asTypedList(totalBytes);
    nativeView.setRange(0, totalBytes, rgbaBytes);

    final srcBuf = calloc<LumaFixImageBuffer>();
    final dstBuf = inPlace ? srcBuf : calloc<LumaFixImageBuffer>();
    final advParams = calloc<LumaFixAdvancedToneParameters>();

    ffi.Pointer<LumaFixToneCurves> curvesPtr = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> rgbPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> redPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> greenPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> bluePts = ffi.Pointer.fromAddress(0);

    final format = (numChannels == 3)
        ? LumaFixPixelFormat.rgb888
        : LumaFixPixelFormat.rgba8888;
    final stride = width * numChannels;

    try {
      srcBuf.ref.data = srcDataPtr;
      srcBuf.ref.width = width;
      srcBuf.ref.height = height;
      srcBuf.ref.strideBytes = stride;
      srcBuf.ref.format = format;

      if (!inPlace) {
        dstBuf.ref.data = dstDataPtr;
        dstBuf.ref.width = width;
        dstBuf.ref.height = height;
        dstBuf.ref.strideBytes = stride;
        dstBuf.ref.format = format;
      }

      advParams.ref.exposure = exposure;
      advParams.ref.contrast = contrast;
      advParams.ref.saturation = saturation;
      advParams.ref.brightness = brightness;
      advParams.ref.warmth = warmth;
      advParams.ref.tint = tint;
      advParams.ref.highlights = highlights;
      advParams.ref.shadows = shadows;
      advParams.ref.whites = whites;
      advParams.ref.blacks = blacks;
      advParams.ref.ambiance = ambiance;

      if (curves != null && !curves.isIdentity) {
        curvesPtr = calloc<LumaFixToneCurves>();
        rgbPts = _allocateCurvePoints(curves.rgb);
        redPts = _allocateCurvePoints(curves.red);
        greenPts = _allocateCurvePoints(curves.green);
        bluePts = _allocateCurvePoints(curves.blue);

        curvesPtr.ref.rgb.points = rgbPts;
        curvesPtr.ref.rgb.pointCount = curves.rgb.length;
        curvesPtr.ref.red.points = redPts;
        curvesPtr.ref.red.pointCount = curves.red.length;
        curvesPtr.ref.green.points = greenPts;
        curvesPtr.ref.green.pointCount = curves.green.length;
        curvesPtr.ref.blue.points = bluePts;
        curvesPtr.ref.blue.pointCount = curves.blue.length;
      }

      final status = _processAdvancedTone(srcBuf, dstBuf, advParams, curvesPtr);
      if (status != LumaFixStatusCode.success) {
        throw StateError(
          'lumafix_process_advanced_tone_rgba8 failed with code $status: ${getStatusString(status)}',
        );
      }

      // Copy processed bytes back to Dart via fast block copy
      final resultView = dstDataPtr.asTypedList(totalBytes);
      if (inPlace) {
        rgbaBytes.setRange(0, totalBytes, resultView);
        return rgbaBytes;
      } else {
        final outList = Uint8List(totalBytes);
        outList.setRange(0, totalBytes, resultView);
        return outList;
      }
    } finally {
      if (rgbPts.address != 0) calloc.free(rgbPts);
      if (redPts.address != 0) calloc.free(redPts);
      if (greenPts.address != 0) calloc.free(greenPts);
      if (bluePts.address != 0) calloc.free(bluePts);
      if (curvesPtr.address != 0) calloc.free(curvesPtr);

      calloc.free(advParams);
      if (!inPlace) {
        calloc.free(dstBuf);
        calloc.free(dstDataPtr);
      }
      calloc.free(srcBuf);
      calloc.free(srcDataPtr);
    }
  }

  /// High-level utility: executes the unified native image processing pipeline on raw image bytes.
  /// Seamlessly passes Tone, Curves, Vibrance, Clarity, B&W, Vintage, Drama, Grain, Vignette,
  /// and Structure directly to the C++ core in a single call.
  /// Supports in-place processing for zero extra heap memory allocations.
  Uint8List processPipelineRgba8({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required EditState state,
    bool inPlace = false,
    int numChannels = 4,
  }) {
    if (width <= 0 || height <= 0 || width > 65536 || height > 65536) {
      throw ArgumentError(
        'Invalid image dimensions for native pipeline: ${width}x$height',
      );
    }
    if (numChannels != 3 && numChannels != 4) {
      throw ArgumentError(
        'Only 3-channel (RGB) or 4-channel (RGBA) buffers are supported: $numChannels',
      );
    }

    final totalBytes = width * height * numChannels;
    if (rgbaBytes.lengthInBytes < totalBytes) {
      throw ArgumentError(
        'Input byte array length (${rgbaBytes.lengthInBytes}) is smaller than required ($totalBytes) for ${width}x$height x $numChannels channels',
      );
    }

    final srcDataPtr = calloc<ffi.Uint8>(totalBytes);
    final dstDataPtr = inPlace ? srcDataPtr : calloc<ffi.Uint8>(totalBytes);
    if (srcDataPtr.address == 0 || dstDataPtr.address == 0) {
      if (srcDataPtr.address != 0) calloc.free(srcDataPtr);
      if (!inPlace && dstDataPtr.address != 0) calloc.free(dstDataPtr);
      throw OutOfMemoryError();
    }

    final nativeView = srcDataPtr.asTypedList(totalBytes);
    nativeView.setRange(0, totalBytes, rgbaBytes);

    final srcBuf = calloc<LumaFixImageBuffer>();
    final dstBuf = inPlace ? srcBuf : calloc<LumaFixImageBuffer>();
    final pipelineParams = calloc<LumaFixPipelineParameters>();

    ffi.Pointer<LumaFixToneCurves> curvesPtr = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> rgbPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> redPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> greenPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<LumaFixCurvePoint> bluePts = ffi.Pointer.fromAddress(0);

    final format = (numChannels == 3)
        ? LumaFixPixelFormat.rgb888
        : LumaFixPixelFormat.rgba8888;
    final stride = width * numChannels;

    try {
      srcBuf.ref.data = srcDataPtr;
      srcBuf.ref.width = width;
      srcBuf.ref.height = height;
      srcBuf.ref.strideBytes = stride;
      srcBuf.ref.format = format;

      if (!inPlace) {
        dstBuf.ref.data = dstDataPtr;
        dstBuf.ref.width = width;
        dstBuf.ref.height = height;
        dstBuf.ref.strideBytes = stride;
        dstBuf.ref.format = format;
      }

      // Populate Tone
      final t = state.tune;
      pipelineParams.ref.tone.exposure = t.exposure;
      pipelineParams.ref.tone.contrast = t.contrast;
      pipelineParams.ref.tone.saturation = t.saturation;
      pipelineParams.ref.tone.brightness = t.brightness;
      pipelineParams.ref.tone.warmth = t.warmth;
      pipelineParams.ref.tone.tint = t.tint;
      pipelineParams.ref.tone.highlights = t.highlights;
      pipelineParams.ref.tone.shadows = t.shadows;
      pipelineParams.ref.tone.whites = t.whites;
      pipelineParams.ref.tone.blacks = t.blacks;
      pipelineParams.ref.tone.ambiance = t.ambiance;

      // Populate Vibrance & Clarity
      pipelineParams.ref.vibrance = t.vibrance;
      pipelineParams.ref.clarity = t.clarity;

      // Populate HSL Color Mixer
      final hsl = state.hsl;
      _copyHslBand(pipelineParams.ref.hsl.red, hsl.red);
      _copyHslBand(pipelineParams.ref.hsl.orange, hsl.orange);
      _copyHslBand(pipelineParams.ref.hsl.yellow, hsl.yellow);
      _copyHslBand(pipelineParams.ref.hsl.green, hsl.green);
      _copyHslBand(pipelineParams.ref.hsl.aqua, hsl.aqua);
      _copyHslBand(pipelineParams.ref.hsl.blue, hsl.blue);
      _copyHslBand(pipelineParams.ref.hsl.purple, hsl.purple);
      _copyHslBand(pipelineParams.ref.hsl.magenta, hsl.magenta);

      // Populate Effects
      final e = state.effects;
      pipelineParams.ref.effects.bwMode = e.bwMode ? 1 : 0;
      pipelineParams.ref.effects.grain = e.grain;
      pipelineParams.ref.effects.vintage = e.vintage;
      pipelineParams.ref.effects.drama = e.drama;
      pipelineParams.ref.effects.bloom = e.bloom;
      pipelineParams.ref.effects.glow = e.glow;
      pipelineParams.ref.effects.chromaticAberration = e.chromaticAberration;
      pipelineParams.ref.effects.lensBlur = e.lensBlur;

      // Populate Vignette
      final v = state.vignette;
      pipelineParams.ref.vignette.amount = v.amount;
      pipelineParams.ref.vignette.radius = v.radius;
      pipelineParams.ref.vignette.feather = v.feather;
      pipelineParams.ref.vignette.centerX = v.centerX;
      pipelineParams.ref.vignette.centerY = v.centerY;

      // Populate Details
      pipelineParams.ref.structure = state.details.structure;
      pipelineParams.ref.sharpening = state.details.sharpening;

      final curves = state.curves;
      if (!curves.isIdentity) {
        curvesPtr = calloc<LumaFixToneCurves>();
        rgbPts = _allocateCurvePoints(curves.rgb);
        redPts = _allocateCurvePoints(curves.red);
        greenPts = _allocateCurvePoints(curves.green);
        bluePts = _allocateCurvePoints(curves.blue);

        curvesPtr.ref.rgb.points = rgbPts;
        curvesPtr.ref.rgb.pointCount = curves.rgb.length;
        curvesPtr.ref.red.points = redPts;
        curvesPtr.ref.red.pointCount = curves.red.length;
        curvesPtr.ref.green.points = greenPts;
        curvesPtr.ref.green.pointCount = curves.green.length;
        curvesPtr.ref.blue.points = bluePts;
        curvesPtr.ref.blue.pointCount = curves.blue.length;
      }

      final status = _processPipeline(
        srcBuf,
        dstBuf,
        pipelineParams,
        curvesPtr,
      );
      if (status != LumaFixStatusCode.success) {
        throw StateError(
          'lumafix_process_pipeline_rgba8 failed with code $status: ${getStatusString(status)}',
        );
      }

      final resultView = dstDataPtr.asTypedList(totalBytes);
      if (inPlace) {
        rgbaBytes.setRange(0, totalBytes, resultView);
        return rgbaBytes;
      } else {
        final outList = Uint8List(totalBytes);
        outList.setRange(0, totalBytes, resultView);
        return outList;
      }
    } finally {
      if (rgbPts.address != 0) calloc.free(rgbPts);
      if (redPts.address != 0) calloc.free(redPts);
      if (greenPts.address != 0) calloc.free(greenPts);
      if (bluePts.address != 0) calloc.free(bluePts);
      if (curvesPtr.address != 0) calloc.free(curvesPtr);

      calloc.free(pipelineParams);
      if (!inPlace) {
        calloc.free(dstBuf);
        calloc.free(dstDataPtr);
      }
      calloc.free(srcBuf);
      calloc.free(srcDataPtr);
    }
  }
}
