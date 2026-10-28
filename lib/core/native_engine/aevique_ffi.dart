import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import '../models/edit_state.dart';

/// Engine execution mode for AEVIQUE image engine.
enum EngineMode {
  /// Automatically uses native C++ when available and compatible, falling back to Dart.
  auto,

  /// Forces native C++ execution only; fails if unavailable.
  nativeOnly,

  /// Forces pure Dart execution; native engine is bypassed.
  dartOnly,
}

/// Status codes matching AeviqueStatus in aevique_engine.h
class AeviqueStatusCode {
  static const int success = 0;
  static const int errorNullPointer = -1;
  static const int errorInvalidDimensions = -2;
  static const int errorInvalidStride = -3;
  static const int errorUnsupportedFormat = -4;
  static const int errorInvalidParameter = -5;
  static const int errorBufferTooSmall = -6;
  static const int errorUnknown = -99;
}

/// Pixel format enum matching AeviquePixelFormat
class AeviquePixelFormat {
  static const int rgba8888 = 0;
  static const int bgra8888 = 1;
  static const int rgb888 = 2;
}

/// Image buffer struct matching AeviqueImageBuffer in aevique_engine.h
final class AeviqueImageBuffer extends ffi.Struct {
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

/// Tone adjustment parameters struct matching AeviqueToneParameters
final class AeviqueToneParameters extends ffi.Struct {
  @ffi.Float()
  external double exposure;

  @ffi.Float()
  external double contrast;

  @ffi.Float()
  external double saturation;
}

/// Single control point on a 2D spline curve
final class AeviqueCurvePoint extends ffi.Struct {
  @ffi.Float()
  external double x;

  @ffi.Float()
  external double y;
}

/// Control point channel containing an array of points and point count
final class AeviqueCurveChannel extends ffi.Struct {
  external ffi.Pointer<AeviqueCurvePoint> points;

  @ffi.Int32()
  external int pointCount;
}

/// Quad-channel tone curves struct matching AeviqueToneCurves
final class AeviqueToneCurves extends ffi.Struct {
  external AeviqueCurveChannel rgb;
  external AeviqueCurveChannel red;
  external AeviqueCurveChannel green;
  external AeviqueCurveChannel blue;
}

/// Advanced tone parameters struct matching AeviqueAdvancedToneParameters
final class AeviqueAdvancedToneParameters extends ffi.Struct {
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

// C function signatures
typedef _GetVersionC = ffi.Uint32 Function();
typedef _GetVersionDart = int Function();

typedef _StatusToStringC = ffi.Pointer<Utf8> Function(ffi.Int32 status);
typedef _StatusToStringDart = ffi.Pointer<Utf8> Function(int status);

typedef _ProcessToneC =
    ffi.Int32 Function(
      ffi.Pointer<AeviqueImageBuffer> src,
      ffi.Pointer<AeviqueImageBuffer> dst,
      ffi.Pointer<AeviqueToneParameters> params,
    );
typedef _ProcessToneDart =
    int Function(
      ffi.Pointer<AeviqueImageBuffer> src,
      ffi.Pointer<AeviqueImageBuffer> dst,
      ffi.Pointer<AeviqueToneParameters> params,
    );

typedef _ProcessAdvancedToneC =
    ffi.Int32 Function(
      ffi.Pointer<AeviqueImageBuffer> src,
      ffi.Pointer<AeviqueImageBuffer> dst,
      ffi.Pointer<AeviqueAdvancedToneParameters> params,
      ffi.Pointer<AeviqueToneCurves> curves,
    );
typedef _ProcessAdvancedToneDart =
    int Function(
      ffi.Pointer<AeviqueImageBuffer> src,
      ffi.Pointer<AeviqueImageBuffer> dst,
      ffi.Pointer<AeviqueAdvancedToneParameters> params,
      ffi.Pointer<AeviqueToneCurves> curves,
    );

/// Safe, high-level Dart FFI wrapper for AEVIQUE native C++ engine.
class AeviqueNativeEngine {
  /// Global engine execution mode.
  static EngineMode engineMode = EngineMode.auto;

  /// Cached active library path used across isolate boundaries.
  static String? activeLibraryPath;

  /// Cached singleton instance of the native engine.
  static AeviqueNativeEngine? _instance;

  /// Gets the currently loaded native engine instance, if available.
  static AeviqueNativeEngine? get instance => _instance;

  /// Returns true if the native engine is loaded and engineMode permits native execution.
  static bool get isAvailable =>
      _instance != null && engineMode != EngineMode.dartOnly;

  /// Tries to load the native engine dynamic library safely.
  /// Returns `true` if successful, `false` otherwise without throwing.
  static bool tryLoad({String? customLibraryPath}) {
    try {
      _instance = AeviqueNativeEngine.load(
        customLibraryPath: customLibraryPath,
      );
      if (kDebugMode) {
        final ver = _instance!.getVersion();
        final major = (ver >> 16) & 0xFF;
        final minor = (ver >> 8) & 0xFF;
        final patch = ver & 0xFF;
        debugPrint(
          '[AEVIQUE-NATIVE] Dynamic library loaded: "$activeLibraryPath" (core v$major.$minor.$patch, mode: $engineMode)',
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AEVIQUE-NATIVE] Dynamic library load failed: $e (path: "$customLibraryPath")',
        );
      }
      // In production or test environments where native dylib is absent, fall back gracefully
      _instance = null;
      return false;
    }
  }

  /// Sets the active native engine instance directly (used for testing or custom lifecycles).
  static void setInstance(AeviqueNativeEngine? engine) {
    _instance = engine;
  }

  final ffi.DynamicLibrary _dylib;
  late final _GetVersionDart _getVersion;
  late final _StatusToStringDart _statusToString;
  late final _ProcessToneDart _processTone;
  late final _ProcessAdvancedToneDart _processAdvancedTone;

  AeviqueNativeEngine._(this._dylib) {
    _getVersion = _dylib.lookupFunction<_GetVersionC, _GetVersionDart>(
      'aevique_get_version',
    );
    _statusToString = _dylib
        .lookupFunction<_StatusToStringC, _StatusToStringDart>(
          'aevique_status_to_string',
        );
    _processTone = _dylib.lookupFunction<_ProcessToneC, _ProcessToneDart>(
      'aevique_process_tone_rgba8',
    );
    _processAdvancedTone = _dylib
        .lookupFunction<_ProcessAdvancedToneC, _ProcessAdvancedToneDart>(
          'aevique_process_advanced_tone_rgba8',
        );
  }

  /// Loads the AEVIQUE native engine dynamic library.
  /// If [customLibraryPath] is omitted, standard build locations are checked.
  factory AeviqueNativeEngine.load({String? customLibraryPath}) {
    ffi.DynamicLibrary dylib;
    if (customLibraryPath != null && customLibraryPath.isNotEmpty) {
      dylib = ffi.DynamicLibrary.open(customLibraryPath);
      activeLibraryPath = customLibraryPath;
    } else if (Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final defaultPaths = [
        'native/aevique_core/build/libaevique_core.dylib',
        '../native/aevique_core/build/libaevique_core.dylib',
        '$exeDir/../Frameworks/libaevique_core.dylib',
        'libaevique_core.dylib',
      ];
      String? foundPath;
      for (final p in defaultPaths) {
        if (File(p).existsSync()) {
          foundPath = p;
          break;
        }
      }
      final resolved = foundPath ?? 'libaevique_core.dylib';
      dylib = ffi.DynamicLibrary.open(resolved);
      activeLibraryPath = resolved;
    } else if (Platform.isLinux || Platform.isAndroid) {
      const libName = 'libaevique_core.so';
      dylib = ffi.DynamicLibrary.open(libName);
      activeLibraryPath = libName;
    } else if (Platform.isWindows) {
      const libName = 'aevique_core.dll';
      dylib = ffi.DynamicLibrary.open(libName);
      activeLibraryPath = libName;
    } else {
      throw UnsupportedError(
        'Unsupported operating system for AeviqueNativeEngine: ${Platform.operatingSystem}',
      );
    }

    return AeviqueNativeEngine._(dylib);
  }

  /// Returns the version integer encoded as (major << 16) | (minor << 8) | patch.
  int getVersion() => _getVersion();

  /// Returns human-readable status string for an error code.
  String getStatusString(int status) {
    final ptr = _statusToString(status);
    return ptr.toDartString();
  }

  /// Calls the low-level C ABI function `aevique_process_tone_rgba8`.
  int processToneRaw({
    required ffi.Pointer<AeviqueImageBuffer> src,
    required ffi.Pointer<AeviqueImageBuffer> dst,
    required ffi.Pointer<AeviqueToneParameters> params,
  }) {
    return _processTone(src, dst, params);
  }

  /// Calls the low-level C ABI function `aevique_process_advanced_tone_rgba8`.
  int processAdvancedToneRaw({
    required ffi.Pointer<AeviqueImageBuffer> src,
    required ffi.Pointer<AeviqueImageBuffer> dst,
    required ffi.Pointer<AeviqueAdvancedToneParameters> params,
    ffi.Pointer<AeviqueToneCurves>? curves,
  }) {
    return _processAdvancedTone(
      src,
      dst,
      params,
      curves ?? ffi.Pointer.fromAddress(0),
    );
  }

  static ffi.Pointer<AeviqueCurvePoint> _allocateCurvePoints(
    List<CurvePoint> points,
  ) {
    if (points.isEmpty) return ffi.Pointer.fromAddress(0);
    final ptr = calloc<AeviqueCurvePoint>(points.length);
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

    final srcBuf = calloc<AeviqueImageBuffer>();
    final dstBuf = inPlace ? srcBuf : calloc<AeviqueImageBuffer>();
    final advParams = calloc<AeviqueAdvancedToneParameters>();

    ffi.Pointer<AeviqueToneCurves> curvesPtr = ffi.Pointer.fromAddress(0);
    ffi.Pointer<AeviqueCurvePoint> rgbPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<AeviqueCurvePoint> redPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<AeviqueCurvePoint> greenPts = ffi.Pointer.fromAddress(0);
    ffi.Pointer<AeviqueCurvePoint> bluePts = ffi.Pointer.fromAddress(0);

    final format = (numChannels == 3)
        ? AeviquePixelFormat.rgb888
        : AeviquePixelFormat.rgba8888;
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
        curvesPtr = calloc<AeviqueToneCurves>();
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
      if (status != AeviqueStatusCode.success) {
        throw StateError(
          'aevique_process_advanced_tone_rgba8 failed with code $status: ${getStatusString(status)}',
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
}
