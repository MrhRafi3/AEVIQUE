---
last_mapped_commit: f67daecc77d163ac9a4956fe76ebdf307ac95752
last_mapped_at: 2026-11-06
---
# Integrations

**Analysis Date:** 2026-11-06

## Native C++ Engine Integration

- **Mechanism:** Direct Dart FFI (`dart:ffi`) over C ABI
- **Library Path:**
  - macOS: `native/lumafix_core/build/liblumafix_core.dylib`
  - Android: `liblumafix_core.so` bundled in native JNI libs
  - Fallback: Pure-Dart isolate pipeline in `lib/core/image_engine/image_pipeline.dart` when dynamic library is absent
- **Functions Bound:**
  - `lumafix_get_version`
  - `lumafix_process_image` (RGBA8888 strided buffer processing)
  - `lumafix_process_pipeline_rgba8888` (full multi-stage adjustment pipeline)
  - `lumafix_process_pipeline_rgb888` (compact 3-channel buffer processing)
  - `lumafix_apply_curves` (RGB and composite spline tone curves)
  - `lumafix_apply_vignette` (radial intensity falloff)

## Platform Hardware & Operating System APIs

- **Gallery Storage (`gal`):**
  - Android: Scoped Storage / MediaStore API
  - macOS/iOS: PhotoKit / `PHPhotoLibrary`
- **Camera & Gallery Picker (`image_picker`):**
  - Android: `ActivityResultContracts.GetContent` / Camera Intent
  - macOS: File open panel via `file_selector_macos`
- **System Share Sheet (`share_plus`):**
  - Native share sheets on Android (`Intent.ACTION_SEND`) and macOS (`NSSharingServicePicker`)

## Cloud & Remote Services

- **Zero Cloud Dependencies:** LumaFix is strictly on-device and privacy-first.
- No network telemetry, analytics, cloud storage, or external authentication providers.
- Typography: Local and cached Google Fonts with runtime asset fallbacks.

---
*Codebase analysis: 2026-11-06*
