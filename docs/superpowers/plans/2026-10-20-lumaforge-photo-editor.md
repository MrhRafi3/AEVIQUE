# LumaForge Photo Editor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a premium, high-performance Flutter mobile photo editor (LumaForge) inspired by professional photo editing tools, featuring real non-destructive image processing, undo/redo history, fine-grained adjustments (Tune, Details, Curves, Color Mixer, Vignette, Effects), Crop/Rotate, Before/After comparison, and high-fidelity export/sharing.

**Architecture:** Clean separation of concerns with a pure Dart image processing engine (`lib/core/image_engine/`) running deterministic edit pipelines (using LUT optimizations and isolate background workers for large images), an immutable `EditState` and `HistoryManager` for non-destructive undo/redo, a dark photography-first design system (`lib/theme/`), and modular UI screens (`lib/screens/` and `lib/widgets/`).

**Tech Stack:** Flutter 3.44.5 (Dart 3.12.2), `image: ^4.12.0`, `image_picker: ^1.2.4`, `path_provider: ^2.1.6`, `share_plus: ^13.3.1`, `gal: ^2.3.3`.

**Spec:** Project specification provided in user prompt.

## Global Constraints
- Minimal, sophisticated dark editing theme (#0D0E11 canvas, neutral tones, refined typography).
- Every tool must perform REAL image processing; no dummy or cosmetic-only sliders.
- Non-destructive editing architecture: original image preserved; changes stored as structured parameters.
- Undo/redo must restore actual rendered states.
- High-resolution processing for export, preview-sized caching for interactive fluidity.
- Android-first support with iOS/macOS compatibility.

## Review Focus
1. Large image decode out-of-memory: Must downsample preview buffer safely while preserving full-resolution source for export.
2. Center-detent slider zero jump: Adjustments must map linearly with zero being exact identity transform.
3. Concurrent slider interaction flooding: Compute jobs must cancel obsolete preview frames or debounce updates to keep 60fps UI responsive.
4. Crop/Rotation coordinate integrity: Geometry transforms must compose correctly before pixel color adjustments.
5. Export format and gallery permissions: Graceful error handling if photo access is denied or media writing fails.

---

### Task 1: Domain Models & Non-Destructive State Architecture
**Files:**
- Create: `lib/core/models/edit_state.dart`
- Create: `lib/core/models/history_manager.dart`
- Test: `test/core/edit_state_test.dart`

**Interfaces:**
- Produces: `EditState`, `TuneAdjustments`, `DetailsAdjustments`, `ToneCurves`, `CurvePoint`, `VignetteAdjustments`, `GeometryAdjustments`, `EffectsAdjustments`, `HistoryManager`.

- [ ] **Step 1: Write the failing test for `EditState` and `HistoryManager`**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `EditState` and `HistoryManager` with immutability, copyWith, serialization, undo/redo**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 2: Core Image Processing Pipeline Engine
**Files:**
- Create: `lib/core/image_engine/image_pipeline.dart`
- Create: `lib/core/image_engine/lut_generator.dart`
- Create: `lib/core/image_engine/filter_kernels.dart`
- Create: `lib/core/presets/preset_catalogue.dart`
- Test: `test/core/image_pipeline_test.dart`

**Interfaces:**
- Consumes: `EditState`, `TuneAdjustments`, etc.
- Produces: `ImagePipeline.processImage(Uint8List bytes, EditState state, {int? maxDimension}) -> Future<Uint8List>`, `PresetCatalogue.presets`.

- [ ] **Step 1: Write unit tests verifying real pixel modifications (brightness increases luma, contrast stretches histogram, crop changes dimensions, B&W zeroes saturation, etc.)**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement LUT generator, convolution filters, geometric transforms, and `ImagePipeline` execution**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 3: Design System, Theme & Tactile Widgets
**Files:**
- Create: `lib/theme/luma_theme.dart`
- Create: `lib/widgets/luma_slider.dart`
- Create: `lib/widgets/before_after_viewer.dart`
- Create: `lib/widgets/curve_editor_widget.dart`
- Create: `lib/widgets/crop_overlay_widget.dart`
- Test: `test/widgets/luma_widgets_test.dart`

**Interfaces:**
- Consumes: `LumaTheme`
- Produces: `LumaSlider`, `BeforeAfterViewer`, `CurveEditorWidget`, `CropOverlayWidget`.

- [ ] **Step 1: Write widget tests for `LumaSlider` and `BeforeAfterViewer`**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement custom dark theme, tactile slider with zero detent, interactive curve canvas, and before/after comparison**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 4: Home Screen & Media Import Flow
**Files:**
- Create: `lib/screens/home_screen.dart`
- Create: `lib/services/image_repository.dart`
- Modify: `lib/main.dart`
- Test: `test/screens/home_screen_test.dart`

**Interfaces:**
- Consumes: `ImageRepository`, `LumaTheme`
- Produces: `HomeScreen`, route to `EditorScreen`.

- [ ] **Step 1: Write widget test for `HomeScreen` verifying title, open photo button, and sample gallery**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `HomeScreen` with photo picker, camera picker, and bundled sample photo loader**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 5: Editor Screen with Tool Navigation & Live Non-Destructive Editing
**Files:**
- Create: `lib/screens/editor_screen.dart`
- Create: `lib/widgets/tool_panels/tune_panel.dart`
- Create: `lib/widgets/tool_panels/details_panel.dart`
- Create: `lib/widgets/tool_panels/curves_panel.dart`
- Create: `lib/widgets/tool_panels/crop_panel.dart`
- Create: `lib/widgets/tool_panels/effects_panel.dart`
- Create: `lib/widgets/tool_panels/presets_panel.dart`
- Test: `test/screens/editor_screen_test.dart`

**Interfaces:**
- Consumes: `EditState`, `HistoryManager`, `ImagePipeline`, `HomeScreen`
- Produces: `EditorScreen`, interactive preview, undo/redo top bar, tool category selector (Refine, Fix, Style, Presets).

- [ ] **Step 1: Write tests for editor interactions, tool switching, undo/redo, and apply/cancel**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `EditorScreen` with asynchronous rendering, cancelable background updates, and tool panels**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 6: Export & Share Flow
**Files:**
- Create: `lib/screens/export_screen.dart`
- Create: `lib/services/export_service.dart`
- Test: `test/screens/export_screen_test.dart`

**Interfaces:**
- Consumes: `EditState`, `ImagePipeline`, `ExportService`
- Produces: `ExportScreen`, full-resolution save to gallery via `gal`, and system share sheet via `share_plus`.

- [ ] **Step 1: Write unit and widget tests for `ExportService` and `ExportScreen`**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement full-res render pipeline, JPEG/PNG format options, quality selection, progress bar, gallery save, and share sheet**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit**

---

### Task 7: Comprehensive Verification & Release Readiness
**Files:**
- Verify: static analysis, formatting, unit tests, widget tests, debug APK compilation.
- Create: `docs/USER_MANUAL.md` detailing tool capabilities, non-destructive editing instructions, and feature guide.

- [ ] **Step 1: Run `dart format --output=none --set-exit-if-changed .`**
- [ ] **Step 2: Run `flutter analyze`**
- [ ] **Step 3: Run `flutter test` across all suites**
- [ ] **Step 4: Verify Android build: `flutter build apk --debug`**
- [ ] **Step 5: Final review and documentation**
