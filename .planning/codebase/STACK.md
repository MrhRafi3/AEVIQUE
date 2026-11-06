---
last_mapped_commit: f67daecc77d163ac9a4956fe76ebdf307ac95752
last_mapped_at: 2026-11-06
---
# Technology Stack

**Analysis Date:** 2026-11-06

## Languages

**Primary:**
- Dart 3.12.2 - Application UI, state management, preview render loop, and pipeline orchestration (`lib/`, `test/`)
- C++17 - High-performance native image processing engine (`native/aevique_core/src/`, `native/aevique_core/include/`)

**Secondary:**
- CMake 3.22+ - Native C++ core build definitions (`native/aevique_core/CMakeLists.txt`)
- Kotlin - Android native runner (`android/`)
- Swift - macOS and iOS native application runners (`macos/Runner/`, `ios/Runner/`)

## Runtime

**Environment:**
- Flutter 3.44.5 (Channel stable, Dart 3.12.2)
- macOS 15.7.2 (darwin-arm64)
- Android API 34–37 (Android SDK 37, NDK 28.2.13676358)

**Package Manager:**
- Flutter Pub (`pubspec.yaml`, `pubspec.lock`)

## Frameworks

**Core:**
- Flutter Material 3 / Custom Darkroom & Lightroom Design System - Cross-platform UI toolkit
- C ABI / Dart FFI (`dart:ffi`) - Low-latency binary bridge between Flutter and C++ native engine

**Testing:**
- `flutter_test` - Widget, unit, and integration testing
- CTest / Native unit test binary (`native/aevique_core/build/test_aevique_engine`)

**Build & Dev:**
- Flutter CLI / Gradle 8.x / Xcode 26.3
- CMake & Clang/GCC for C++ shared library compilation (`libaevique_core.dylib` / `.so`)

## Key Dependencies

- `ffi` (^2.1.3): Native memory allocation, pointers, and C ABI binding invocation
- `image` (^4.12.0): Image decode/encode (JPEG/PNG/HEIF), pixel buffers, and pure-Dart fallback processing
- `google_fonts` (^8.2.1): Premium typography (`Playfair Display`, `Inter`, `JetBrains Mono`)
- `image_picker` (^1.2.4): Camera capture and system gallery asset selection
- `gal` (^2.3.3): High-performance native photo gallery saving with proper permissions
- `share_plus` (^13.3.1): Native platform share sheet integration
- `path_provider` (^2.1.6): Local application cache and documents directory resolution

---
*Codebase analysis: 2026-11-06*
