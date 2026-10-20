# AEVIQUE — Focused UI, Performance, Filters & Portrait Retouching Upgrade Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Address layout constraints, performance bottlenecks, demo content, filter curation, and portrait retouching in **AEVIQUE**:
1. Fix editor top toolbar and bottom category RenderFlex overflows.
2. Fix demo-image loading by properly slicing `rootBundle` buffers and providing real curated offline photography assets.
3. Remove duplicate Settings navigation (keep clean header icon).
4. Correct Signature Vivid algorithm (clean contrast, rich balanced colors, protected skin tones) and compact the filter catalogue to 10 iPhone-inspired styles.
5. Implement real on-device Portrait Retouching (Skin Smooth with facial edge preservation, Skin Tone Brighten, tap-to-heal Blemish Removal).
6. Robust JPEG, PNG, HEIF/HEIC import handling and strict single-active-photo state management.
7. Futuristic glassmorphism UI with subtle backdrop blur and refined multi-stage splash animation sequence.
8. Automated tests and platform verification (`flutter test`, `flutter analyze`, `flutter build apk --debug`).

---

## File Architecture & Component Plan

### 1. Layout & Constraints Fixes
- `lib/screens/editor_screen.dart`:
  - Top Toolbar: Wrap the central state pill in `Expanded`/`Flexible` with text truncation (`TextOverflow.ellipsis`), constrain action buttons to `compact` icon sizes, and guarantee fit on 320dp–400dp screens.
  - Bottom Category Navigation: Wrap category chips in a horizontal scrollable view or flexible wrap with responsive padding, eliminating RenderFlex right-overflow.

### 2. Demo Images & Preset Flow
- `lib/services/image_repository.dart`:
  - Fix `rootBundle.load` byte extraction: `byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)`.
  - Provide 5 curated, high-quality offline photographs:
    - Sunset Landscape (`assets/images/sample_landscape.jpg`)
    - Studio Portrait (`assets/images/sample_portrait.jpg`)
    - Nature & Greenery (`assets/images/sample_nature.jpg`)
    - Architecture & City (`assets/images/sample_architecture.jpg`)
    - Food Photography (`assets/images/sample_food.jpg`)
- `lib/screens/home_screen.dart`:
  - Tapping any demo photo loads genuine bytes and opens the single active editor session.
  - Curated Presets section: Horizontally scrollable cards showing real image previews for the 10 core presets.

### 3. Navigation Clean-up
- `lib/screens/home_screen.dart`:
  - Retain the top-right Settings header icon as the primary destination.
  - Clean bottom navigation: Home, Library, Presets (no redundant Settings tab).

### 4. Compact 10-Filter Suite & Vivid Tuning
- `lib/core/presets/filter_catalogue.dart`:
  - Re-tune **Vivid**: Moderated saturation (+12 instead of +28), zero unwanted warmth (0.0 warmth/tint), balanced midtone contrast (+10), protected highlights (-6) and shadows (+8).
  - Compact 10 curated styles:
    1. *Original* (neutral identity)
    2. *Vivid* (crisp, balanced color and contrast)
    3. *Vivid Warm* (subtle golden warmth without orange cast)
    4. *Vivid Cool* (clean oceanic coolness without blue clipping)
    5. *Dramatic* (deep cinematic contrast with shadow detail)
    6. *Dramatic Warm* (controlled warm filmic shadows)
    7. *Dramatic Cool* (sleek modern slate coolness)
    8. *Mono* (balanced classic monochrome)
    9. *Silvertone* (luminous high-key silver monochrome)
    10. *Noir* (deep rich high-contrast noir monochrome)
- `lib/widgets/tool_panels/filters_panel.dart`:
  - Asynchronous isolate thumbnail generation to keep the UI thread silky smooth.

### 5. Real Portrait Retouching Engine
- `lib/core/models/edit_state.dart`:
  - Add `PortraitAdjustments` with `skinSmooth` (0–100), `skinBrighten` (0–100), and `blemishes` (`List<BlemishPoint>`).
- `lib/core/image_engine/portrait_engine.dart`:
  - Color-space skin segmentation ($YC_bC_r$/HSV) combined with edge-detection exclusion (protecting eyes, eyebrows, lips, hair).
  - Bilateral/guided spatial-range smoothing for skin texture.
  - Skin tone brightening targeting skin midtones.
  - Interactive local inpainting/gradient blending for blemish removal.
- `lib/widgets/tool_panels/portrait_panel.dart`:
  - Sliders for Skin Smooth and Skin Brighten.
  - Tap-to-heal blemish tool with target ring and undo.
- Add Portrait tool to Editor's tool navigation.

### 6. Single Active Photo State & Safe Format Ingestion
- `lib/screens/editor_screen.dart`:
  - Enforce single active photo session; prompt unsaved confirmation before replacing photo.
  - Proper image resource release (`dispose`).
- `lib/core/image_engine/image_pipeline.dart`:
  - Safe format detection for JPEG, PNG (with alpha handling), HEIF/HEIC (with format verification and clear failure messaging).

### 7. Glassmorphism UI & Multi-Stage Splash Animation
- `lib/widgets/aevique_glass.dart`:
  - Translucent glass surfaces (`BackdropFilter`, subtle blur, 1px champagne-gold borders).
- `lib/screens/splash_screen.dart`:
  - Multi-stage sequence: Logo fade-in $\rightarrow$ Champagne gold shimmer $\rightarrow$ AEVIQUE wordmark slide $\rightarrow$ "See Beyond Ordinary." $\rightarrow$ smooth transition.

---

## Tasks

### Task 1: Fix Editor Layout Overflows
- [ ] Fix `_buildTopBar()` in `lib/screens/editor_screen.dart`: wrap state pill in `Expanded`/`Flexible`, shrink action paddings to fit 320–400dp screens.
- [ ] Fix `_buildCategoryAndToolsSelector()` in `lib/screens/editor_screen.dart`: make category tabs scrollable horizontally or compact with flexible spacing.
- [ ] Add widget test verifying narrow screen (320px width) renders without RenderFlex overflow.

### Task 2: Real Demo Images & Preset Flow on Homepage
- [ ] Fix `rootBundle.load` in `lib/services/image_repository.dart` to use buffer offset and length.
- [ ] Generate/bundle all 5 offline sample images: Landscape, Portrait, Nature, Architecture, Food.
- [ ] Add real preset cards to `lib/screens/home_screen.dart` linking to the editor with a sample photo and active preset.
- [ ] Write widget tests verifying sample photo loading and editing.

### Task 3: Remove Duplicate Settings Navigation
- [ ] Update `lib/screens/home_screen.dart` bottom navigation: remove duplicate Settings tab, leaving Home, Library, Presets.
- [ ] Ensure header Settings icon remains the single, primary destination.

### Task 4: Compact Filter Collection & Correct Vivid
- [ ] Rewrite `lib/core/presets/filter_catalogue.dart` to provide the 10 curated iPhone-inspired filters.
- [ ] Tune `Vivid` with natural skin tones and clean contrast.
- [ ] Update `FiltersPanel` with asynchronous off-thread thumbnail generation.
- [ ] Add unit tests verifying filter blending, neutral 0% output, and Vivid parameters.

### Task 5: Portrait Retouching Engine & UI
- [ ] Add `PortraitAdjustments` and `BlemishPoint` to `lib/core/models/edit_state.dart`.
- [ ] Create `lib/core/image_engine/portrait_engine.dart` with skin detection, edge-preserving smoothing, skin tone brightening, and blemish healing.
- [ ] Integrate portrait processing into `ImagePipeline.processRawImage()` and `processPreviewFast()`.
- [ ] Create `lib/widgets/tool_panels/portrait_panel.dart` and add `Portrait` to the editor's toolset.
- [ ] Add unit tests verifying portrait smoothing, brightening, and blemish removal.

### Task 6: Robust Multi-Format Import & Single-Photo State
- [ ] Add format inspection in `ImagePipeline` for JPEG, PNG, HEIF/HEIC.
- [ ] Ensure single active image state in editor with proper resource cleanup.
- [ ] Test format handling with mock byte streams.

### Task 7: Glassmorphism Styling & Staged Splash Animation
- [ ] Create `lib/widgets/aevique_glass.dart` for backdrop blur and frosted glass panels.
- [ ] Apply glass styling to editor bottom drawers and top bar.
- [ ] Upgrade `SplashScreen` with sequential animation (Logo $\rightarrow$ Gold Shimmer $\rightarrow$ Wordmark $\rightarrow$ Tagline).

### Task 8: Verification & APK Build
- [ ] Run `dart format .`
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Run `flutter build apk --debug`
- [ ] Commit all changes to git.
