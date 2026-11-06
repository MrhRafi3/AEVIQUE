# AEVIQUE — Professional Mobile Photo Editor

**AEVIQUE** is a high-performance, minimal, photography-first mobile photo editing application built with Flutter, Dart, and an ultra-fast native C++ image processing engine (`aevique_core`). It delivers professional non-destructive image adjustments, high-fidelity real pixel processing, tactile controls, and high-resolution export.

---

## 1. Key Features & Architecture

### Photography-First Design System
- **Dark Studio Canvas:** `#0C0E12` backdrop with neutral tones (`#14181F` surfaces) and refined amber (`#E5A93C`) and cyan accents, keeping photos as the focal point.
- **Tactile Sliders:** Precision `LumaSlider` with center-zero detents, double-tap reset, and monospace numeric readouts (`-100` to `+100`).
- **Instant Before/After:** Seamless `BeforeAfterViewer` allowing press-and-hold to compare current edits with the unedited original.

### Non-Destructive Editing & History Stack
- All edits are stored as immutable `EditState` configurations.
- The `HistoryManager` maintains an undo/redo stack of discrete committed operations without duplicating full-resolution image buffers in memory.
- Every tool supports **Cancel** (reverting to current history state) and **Apply** (committing changes to history).

---

## 2. Native C++ Image Processing Engine (`aevique_core` v1.2.0)

AEVIQUE features a dedicated native C++ engine (`libaevique_core.so` on Android, `libaevique_core.dylib` on macOS) integrated via Dart FFI.

### C ABI Architecture (v1.2.0)
- **Version Query:** `aevique_get_version_major()`, `aevique_get_version_minor()`, `aevique_get_version_patch()`.
- **Pixel Formats:** `RGBA8888` (4 bytes per pixel) and `RGB888` (3 bytes per pixel).
- **Buffer Interface:** `AeviqueImageBuffer` with explicit row stride, width, height, and format validation.

### Unified Native Processing Pipeline (`aevique_process_pipeline_rgba8`)
Rather than performing multiple successive FFI calls and intermediate buffer allocations, the Phase 6 Unified Pipeline executes all compatible operations in a single cache-efficient pixel pass:
1. **Tone & Curves:** 3-channel 256-entry lookup tables for Exposure, Contrast, Highlights, Shadows, Whites, Blacks, Warmth, Tint, and Spline Tone Curves.
2. **Adaptive Vibrance:** Selective saturation boost that protects skin tones and already-saturated colors.
3. **Local Clarity:** Midtone-weighted local contrast enhancement.
4. **Black & White / Monochrome:** Rec. 709 luminance weights ($Y = 0.2126R + 0.7152G + 0.0722B$) with blend factor.
5. **Atmospheric Effects:** Vintage lift/compression curves, Drama shadow crushing, and deterministic analog film grain.
6. **Radial Vignette:** Smooth cosine-squared edge falloff with customizable center, radius, and feathering.
7. **Spatial Structure:** 4-neighbor Laplacian micro-contrast enhancement.

### Zero-JPEG Real-Time Preview
- Preview frames are rendered directly into raw RGBA memory buffers and uploaded via `ui.decodeImageFromPixels`.
- Eliminates repeated JPEG compression and decompression cycles during slider dragging.
- **Stale-Render Protection:** Discards obsolete asynchronous render frames when rapid slider bursts occur.

### Full-Resolution Export Engine
- Background isolate architecture performs full-resolution image decoding, native C++ pixel processing, and encoding without blocking the Flutter UI thread.
- Processes 12-Megapixel (4000x3000) images in ~47 ms (native kernel) with over 250 Megapixels/sec throughput.

### Intentional Dart Fallback Boundaries
Operations with multi-scale down/upscale or geometry requirements are preserved in the Dart fallback pipeline:
- **Sharpening:** Unsharp mask convolution with multi-pass Gaussian blur.
- **Highlight Bloom:** Downsampled threshold extraction with screen blending.
- **Chromatic Aberration:** Multi-channel spatial displacement.
- **Geometry:** Crop, 90° rotations, horizontal/vertical flips.
- **Portrait Retouching:** Face-aware skin smoothing and blemish removal.

---

## 3. Performance Benchmarks (Apple Silicon M-Series Baseline)

### Preview Pipeline (1200x670 RGBA8)
| Pipeline Scenario | Pure Dart Fallback | Native C++ Engine | Speedup | Latency Saved |
|---|---|---|---|---|
| Tone Adjustments | 50.95 ms | 3.59 ms | **14.21x** | 47.36 ms / frame |
| Advanced Tone + Curves | 50.98 ms | 3.55 ms | **14.36x** | 47.43 ms / frame |
| Complex Unified Pipeline (Tone + Curves + Vibrance + Clarity + Vignette + Grain + Structure) | 187.45 ms | 30.72 ms | **6.10x** | 156.73 ms / frame |

### Full-Resolution Export Pipeline (12-Megapixel / 4000x3000)
| Export Stage | Dart Engine | Native C++ Engine | Speedup / Throughput |
|---|---|---|---|
| Pure Processing Kernel | 424.03 ms | 47.16 ms | **8.99x** (254.47 MP/sec) |
| End-to-End Export (Decode + Process + JPEG) | 908.09 ms | 623.97 ms | **284.12 ms** saved per export |

---

## 4. Project Structure

```
lib/
├── core/
│   ├── image_engine/
│   │   ├── filter_kernels.dart   # Sharpening, structure, vignette, grain, bloom, etc.
│   │   ├── image_pipeline.dart   # Preview rendering, isolate export, and native router
│   │   └── lut_generator.dart    # Fast 256-element LUT precomputations & spline interpolation
│   ├── models/
│   │   ├── edit_state.dart       # Immutable, serializable edit state domain models
│   │   └── history_manager.dart  # Discrete undo/redo state stack
│   ├── native_engine/
│   │   └── aevique_ffi.dart      # Dart FFI bindings and C ABI v1.2.0 integration
│   └── presets/
│       └── preset_catalogue.dart # Curated aesthetic presets
native/
└── aevique_core/
    ├── CMakeLists.txt            # CMake build configuration for native core
    ├── include/
    │   └── aevique_engine.h      # C ABI header (v1.2.0)
    ├── src/
    │   └── aevique_engine.cpp    # Vectorized C++ image processing kernels
    ├── tests/
    │   └── test_aevique_engine.cpp # 23 native C++ unit tests
    └── benchmarks/
        └── bench_aevique_engine.cpp # Native C++ microbenchmarks
```

---

## 5. Verification & Testing

### Running Tests
Execute the full Flutter automated test suite:
```bash
flutter test
```

Execute the native C++ unit tests:
```bash
cmake -B native/aevique_core/build -S native/aevique_core
cmake --build native/aevique_core/build
./native/aevique_core/build/test_aevique_core
```

### Static Analysis & Formatting
Ensure zero analysis issues and proper code formatting:
```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
```

### Running Performance Benchmarks
```bash
flutter test test/benchmark/preview_pipeline_benchmark.dart
flutter test test/benchmark/native_export_benchmark.dart
```

### Building for Android
Build a debug APK packaging `libaevique_core.so` for `arm64-v8a`, `armeabi-v7a`, and `x86_64`:
```bash
./android/gradlew -p android assembleDebug
```
Output APK location:
`build/app/outputs/apk/debug/app-debug.apk`
