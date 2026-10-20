# LumaForge — Professional Mobile Photo Editor

**LumaForge** is a premium, minimal, photography-first mobile photo editing application built with Flutter and Dart. It delivers professional non-destructive image adjustments, high-fidelity real pixel processing, tactile controls, and high-resolution export.

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

### Real Pixel-Level Image Processing Pipeline
All slider and tool movements perform real pixel transformations via `ImagePipeline`:
1. **Geometry Pipeline:**
   - 90° clockwise incremental rotations.
   - Horizontal and vertical flips.
   - Interactive rule-of-thirds crop rectangle with corner drag handles and aspect ratio presets (Free, 1:1, 4:5, 16:9, 9:16, 3:2).
2. **Look-Up Table (LUT) Tone Optimization:**
   - Precomputed 256-entry channel transfer curves for sub-second, $O(N)$ execution in background isolates.
   - Adjustments: Brightness, Contrast, Highlights, Shadows, Warmth, Tint, and Ambiance.
3. **Tone Curves:**
   - Full RGB master curve and individual Red, Green, and Blue channel curves.
   - Smooth cubic Hermite spline interpolation with draggable control points.
4. **Details & Structure:**
   - Unsharp mask sharpening and local micro-contrast enhancement.
5. **Photographic Effects:**
   - B&W Monochrome conversion (Rec. 709 luminance weights).
   - Analog film grain synthesis with pseudo-random noise generator.
   - Highlight bloom glow with downscaled threshold extraction and screen blending.
   - Chromatic aberration color fringing.
   - Moody drama contrast and vintage film fading.
   - Radial vignette with customizable radius, feather, and inner/outer brightness.
6. **Curated Original Presets:**
   - *Portra Warm:* Soft skin highlights, gentle warmth, subtle grain.
   - *Noir Contrast:* Deep blacks, commanding midtone contrast, crisp monochrome.
   - *Nordic Crisp:* Cool tones, clean whites, razor-sharp clarity.
   - *Golden Hour:* Radiant sunset glow, lifted shadows, warm ambiance.
   - *Cinematic Moody:* Atmospheric split-tones with lifted blacks.
   - *Vibrant Nature:* Punchy vivid colors and local edge detail.
   - *Vintage 70s:* Retro washed warmth, subtle fade, and heavy film grain.

---

## 2. Project Structure

```
lib/
├── core/
│   ├── image_engine/
│   │   ├── filter_kernels.dart   # Sharpening, structure, vignette, grain, bloom, etc.
│   │   ├── image_pipeline.dart   # Deterministic isolate processing & pipeline orchestration
│   │   └── lut_generator.dart    # Fast 256-element LUT precomputations & spline interpolation
│   ├── models/
│   │   ├── edit_state.dart       # Immutable, serializable edit state domain models
│   │   └── history_manager.dart  # Discrete undo/redo state stack
│   └── presets/
│       └── preset_catalogue.dart # Curated photographic aesthetic presets
├── screens/
│   ├── home_screen.dart          # Gallery, Camera, and Studio Samples launcher
│   ├── editor_screen.dart        # Main editing workspace, InteractiveViewer, tool drawer
│   └── export_screen.dart        # Full-res render progress, JPEG/PNG settings, save/share
├── services/
│   ├── export_service.dart       # Gal photo gallery saving and SharePlus integration
│   └── image_repository.dart     # Photo picker, camera capture, and asset loading
├── theme/
│   └── luma_theme.dart           # Photography-first dark aesthetic, palette, typography
└── widgets/
    ├── before_after_viewer.dart  # Press-and-hold instant original/edited comparison
    ├── crop_overlay_widget.dart  # Interactive rule-of-thirds crop canvas
    ├── curve_editor_widget.dart  # Interactive spline curve canvas (RGB, R, G, B)
    ├── luma_slider.dart          # Center-detent tactile slider with numeric feedback
    └── tool_panels/              # Modular tool controls (Tune, Details, Curves, Crop, etc.)
```

---

## 3. Running & Verifying the Application

### Running Tests
Execute the full automated test suite (unit tests, image transformations, and widget tests):
```bash
flutter test
```

### Static Analysis & Formatting
Ensure zero analysis issues and proper code formatting:
```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
```

### Building for Android
Build a debug APK:
```bash
flutter build apk --debug
```
Output APK location:
`build/app/outputs/flutter-apk/app-debug.apk`

### Launching on Connected Device or Simulator
```bash
flutter run
```
