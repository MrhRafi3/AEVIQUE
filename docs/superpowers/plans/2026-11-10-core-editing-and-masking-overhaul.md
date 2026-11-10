# Core Editing Tools & Masking Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix Crop & Straighten with continuous rotation and multi-handle aspect-ratio cropping; upgrade Tone Curves to a professional overflow-free editor with Monotone Cubic Spline interpolation; implement a professional masking system with freehand brush, on-device Select Subject human segmentation, inversion, and full local adjustments (Light, Color, 8-channel HSL, Effects).

**Architecture:** Layered Flutter + Native C++ architecture:
- Flutter provides high-fidelity Liquid Glass UI, smooth gesture tracking, responsive layout, and interactive preview canvas.
- Native C++ (`lumafix_core`) provides high-performance pixel processing for fine rotation/geometry, Fritsch-Carlson monotone cubic spline curve generation, on-device Apple Vision person segmentation bridge (with portable on-device portrait segmentation fallback for cross-platform/Android), and SIMD/cache-friendly mask blending with complete local adjustments (Light, Color, HSL, Structure/Sharpening).
- Coordinate transformation system (`ImageCoordinateTransformer`) unifies viewport letterboxing, zoom/pan transforms, crop, rotation, and mask coordinates.

**Tech Stack:** Flutter 3.44, Dart 3.12, C++17, CMake, Apple Vision framework (on-device Neural Engine segmentation), Rec.709 HSL color models, Fritsch-Carlson monotone cubic spline interpolation.

**Spec:** User prompt: `LUMAFIX — PHASE 04: CORE EDITING TOOLS & MASKING OVERHAUL`.

## Global Constraints
- Preserve existing LumaFix design language, Liquid Glass visual direction, colors, typography and navigation.
- Flutter + Native C++ dual-tier architecture: Native C++ for performance-critical processing, pure Dart fallback.
- Preview and exported images must produce consistent results.
- 100% on-device image processing: zero external cloud APIs, no network transmission of private user photos.
- Maintain documentation integrity and never weaken or delete existing tests.

## Review Focus
- **Input class 1 (Extreme curve adjustments):** User creates an S-curve or invert-curve with points very close together in X. Monotone cubic spline must not oscillate wildly, NaN, or overflow.
- **Input class 2 (High-resolution image crop & fine rotation):** Straightening an image by -3.5° and cropping to 16:9 must produce exact preview-to-export parity without black border leakage or distortion.
- **Input class 3 (Mask brush on zoomed/panned canvas):** Painting on an image zoomed to 3.5x and panned must land on the exact pixel under the pointer and stay locked when panning/zooming.
- **Input class 4 (Select Subject on portrait photo):** Running "Select Subject" on `assets/images/sample_portrait.jpg` must generate an accurate 8-bit alpha mask of the person, preserve hair and clothing edges, and support brush refinement (add/erase).
- **Input class 5 (Local adjustments isolation):** Applying +40 Exposure and -50 Saturation to a masked subject must alter only the masked pixels; background pixels must remain strictly bit-for-bit unchanged.

---

### Task 1: Geometry Model & Crop / Straighten Functional Engine

**Files:**
- Modify: `lib/core/models/edit_state.dart:379-450`
- Modify: `lib/core/image_engine/image_pipeline.dart:375-410`
- Modify: `native/lumafix_core/include/lumafix_engine.h`
- Modify: `native/lumafix_core/src/lumafix_engine.cpp`
- Create: `lib/core/image_engine/coordinate_transformer.dart`
- Create: `test/core/geometry_crop_straighten_test.dart`

**Interfaces:**
- `GeometryAdjustments`: Add `double rotationAngle` (degrees, -45.0 .. +45.0).
- `ImageCoordinateTransformer`: Helper methods `getDisplayRect`, `viewportToNormalized`, `normalizedToViewport`.
- `ImagePipeline`: Handles `rotationAngle` combined with `rotationQuarterTurns`, flip, and crop coordinates correctly.

- [ ] **Step 1: Write the failing test for continuous rotation and crop geometry**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Update `GeometryAdjustments` model and `ImagePipeline` geometry processing**
- [ ] **Step 4: Implement `ImageCoordinateTransformer`**
- [ ] **Step 5: Run tests to verify they pass**

---

### Task 2: Crop & Straighten UI: Interactive Overlay & Angle Ruler

**Files:**
- Modify: `lib/widgets/crop_overlay_widget.dart`
- Modify: `lib/widgets/tool_panels/crop_panel.dart`
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/widgets/crop_tool_test.dart`

**Interfaces:**
- `CropOverlayWidget`: 8 handles (4 corners + 4 edges), inside pan, aspect ratio lock (`1:1`, `4:3`, `3:2`, `16:9`, `Free`, `Original`).
- `CropPanel`: `LumaRulerSlider` wired to `geometry.rotationAngle`, numeric degree display badge, fine nudge buttons, reset button, rotate 90°, flip H/V.

- [ ] **Step 1: Write widget tests for CropOverlayWidget (handles, aspect ratios) and CropPanel**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement 8-handle CropOverlayWidget with aspect ratio constraint logic**
- [ ] **Step 4: Connect continuous rotation angle, aspect ratio selector, and reset in CropPanel**
- [ ] **Step 5: Run test to verify it passes**

---

### Task 3: Curves Engine & Mathematics: Fritsch-Carlson Monotone Cubic Spline

**Files:**
- Modify: `native/lumafix_core/src/lumafix_engine.cpp:36-100`
- Modify: `lib/core/image_engine/lut_generator.dart:117-180`
- Modify: `lib/widgets/curve_editor_widget.dart:350-465`
- Test: `native/lumafix_core/tests/test_lumafix_engine.cpp`
- Test: `test/core/tone_curves_test.dart`

**Interfaces:**
- C++ `interpolate_curve_channel`: Fritsch-Carlson monotone cubic spline interpolation.
- Dart `LutGenerator._interpolateCurve`: Matching Fritsch-Carlson monotone cubic spline.
- Dart `_CurvePainter._evaluateSpline`: Matching Fritsch-Carlson evaluation for UI curve drawing.

- [ ] **Step 1: Write tests for curve interpolation stability, monotonicity, and parity**
- [ ] **Step 2: Run tests to verify failure/discrepancies**
- [ ] **Step 3: Implement Fritsch-Carlson monotone cubic spline in C++, Dart LutGenerator, and CurvePainter**
- [ ] **Step 4: Run native C++ and Dart tests to verify 100% parity**

---

### Task 4: Curves UI Overhaul & Overflow Elimination

**Files:**
- Modify: `lib/widgets/curve_editor_widget.dart`
- Modify: `lib/widgets/tool_panels/curves_panel.dart`
- Test: `test/screens/curves_overflow_test.dart`

**Interfaces:**
- `CurveEditorWidget`: Flexible touch targets, responsive channel pills (wrap or scrollable without overflow), active point selection, add point by tapping curve, delete point button and gesture, reset channel and reset all channels, bounded aspect ratio.
- Parent layout: Scroll gesture isolation during curve dragging to prevent gesture conflict and RenderFlex overflows on narrow screens (320px - 400px).

- [ ] **Step 1: Write responsive layout and point drag tests on narrow screen sizes**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Refactor CurveEditorWidget layout, hit testing, point manipulation, and overflow guards**
- [ ] **Step 4: Run tests to verify all pass with zero RenderFlex overflow**

---

### Task 5: Professional Masking Models & Engine with Complete Local Adjustments

**Files:**
- Modify: `lib/core/models/mask_model.dart`
- Modify: `lib/core/image_engine/mask_engine.dart`
- Modify: `native/lumafix_core/include/lumafix_engine.h`
- Modify: `native/lumafix_core/src/lumafix_engine.cpp`
- Modify: `lib/core/native_engine/lumafix_ffi.dart`
- Test: `test/core/mask_engine_test.dart`
- Test: `native/lumafix_core/tests/test_lumafix_engine.cpp`

**Interfaces:**
- `MaskToneAdjustments`: Exposure, Brightness, Contrast, Highlights, Shadows, Whites, Blacks, Warmth, Tint, Saturation, Vibrance, HSL (8 channels), Clarity, Structure, Dehaze, Sharpness.
- `SelectiveMask`: Raster mask alpha buffer (`maskBytes`, `maskWidth`, `maskHeight`), `feather`, `density`, `inverted`.
- `MaskEngine` & C++ `lumafix_apply_mask_rgba8`: Applies local adjustments strictly within the mask with sub-pixel bilinear sampling.

- [ ] **Step 1: Write failing tests for mask raster representation and local adjustments (Light, Color, HSL, Effects)**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Update `MaskToneAdjustments` and `SelectiveMask` data models**
- [ ] **Step 4: Implement native C++ and Dart MaskEngine local adjustment pipeline**
- [ ] **Step 5: Run tests to verify they pass**

---

### Task 6: On-Device Subject Auto-Selection (Apple Vision + Portable Fallback)

**Files:**
- Modify: `native/lumafix_core/include/lumafix_engine.h`
- Create: `native/lumafix_core/src/lumafix_segmentation.mm` (or platform segmentation in lumafix_engine.cpp)
- Modify: `native/lumafix_core/CMakeLists.txt`
- Modify: `lib/core/native_engine/lumafix_ffi.dart`
- Create: `lib/core/image_engine/subject_segmentation_service.dart`
- Test: `test/core/subject_segmentation_test.dart`

**Interfaces:**
- C ABI `lumafix_segment_person_rgba8(const LumaFixImageBuffer* src, uint8_t* out_mask, int32_t mask_w, int32_t mask_h)`:
  - On macOS/iOS: Hardware-accelerated Apple Vision `VNGeneratePersonSegmentationRequest` (accurate quality, on-device).
  - Cross-platform / fallback: Saliency and chrominance-guided portrait segmentation producing smooth 8-bit alpha mask.
- `SubjectSegmentationService.segmentSubject(img.Image image)`: Returns normalized mask alpha buffer.

- [ ] **Step 1: Write unit test validating person segmentation on `sample_portrait.jpg`**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement native segmentation bridge and Dart service**
- [ ] **Step 4: Run test to verify real person segmentation succeeds with high accuracy**

---

### Task 7: Masking Workspace UI & Interactive Brush Painting

**Files:**
- Modify: `lib/widgets/tool_panels/mask_panel.dart`
- Modify: `lib/screens/editor_screen.dart`
- Test: `test/widgets/mask_panel_test.dart`

**Interfaces:**
- Interactive canvas painting: Continuous drag to paint, brush size, hardness, opacity/flow, erase/subtract mode, undo/redo stroke stack, clear.
- Mask panel organized into collapsible/tabbed sections:
  1. Selection & Brush (Select Subject, Brush, Erase, Invert, Size, Hardness, Opacity)
  2. Refinement (Feather, Density, Show/Hide Overlay)
  3. Light (Exposure, Contrast, Highlights, Shadows, Whites, Blacks, Brightness)
  4. Color (Temperature, Tint, Saturation, Vibrance)
  5. HSL (8 colors with Hue, Saturation, Luminance)
  6. Effects (Clarity, Structure, Dehaze, Sharpness)

- [ ] **Step 1: Write widget tests for brush stroke painting, invert, and local adjustment sliders**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement interactive brush overlay on canvas with zoom/pan coordinate alignment**
- [ ] **Step 4: Implement organized MaskPanel with all required adjustment sections**
- [ ] **Step 5: Run tests to verify all pass**

---

### Task 8: End-to-End Integration, Parity Verification & Build Quality

**Files:**
- Modify: `lib/services/export_service.dart`
- Modify: `lib/core/image_engine/image_pipeline.dart`
- Test: `test/core/preview_integration_test.dart`
- Test: `test/core/native_export_test.dart`

**Interfaces:**
- Verify Crop, Curves, and Masking end-to-end between preview and export.
- Run complete test suites (`flutter test`, native C++ tests, `flutter analyze`).
- Run platform builds (macOS debug build, Android build verification).

- [ ] **Step 1: Run full native C++ test suite and benchmark**
- [ ] **Step 2: Run full Flutter test suite**
- [ ] **Step 3: Run `flutter analyze` with 0 warnings**
- [ ] **Step 4: Build macOS and Android to verify platform compatibility**
- [ ] **Step 5: Verify git diff and commit**
