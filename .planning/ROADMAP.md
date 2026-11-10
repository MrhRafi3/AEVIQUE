# Roadmap: LumaFix Reference-Driven iOS 26 Glass UI Redesign

## Overview

Complete visual and interaction redesign of LumaFix to match the user-provided iOS 26 dark translucent layered glass reference image across all screens, controls, and platforms.

## Execution Phases

- [x] **Phase 1: Glass Material System & Design Tokens**
  - Implement neutral dark-glass palette in `luma_theme.dart`.
  - Build reference glass components in `luma_glass.dart` and `luma_ui_components.dart`: frosted glass capsules, specular borders, amber glowing FABs, category pills, precision dials, and rulers.
  - Eliminate all traces of legacy champagne/gold, ivory, and Playfair Display typography.

- [x] **Phase 2: Screen Redesigns — Splash, Home, Gallery & Action Sheets**
  - Rebuild Splash screen with dark cinematic atmosphere and clean sans-serif logo.
  - Rebuild Home screen to match Phone 1 in reference ("Explore templates", category pills, large "Year in Review" card, floating amber "+" FAB, floating frosted glass dock).
  - Rebuild Gallery screen with dark grid and Phone 2 bottom sheet (aspect cards & glass action pills).

- [x] **Phase 3: Central Editor & Crop Screen Overhaul**
  - Rebuild Main Editor workspace with maximized photo canvas, before/after toggle, undo/redo, and floating mode dock.
  - Implement Crop mode matching Phone 3 (3x3 grid, corner handles, angle slider with floating "-10°" badge and tick ruler, mode selector pill, circular golden checkmark FAB with ambient bloom).

- [x] **Phase 4: Tool Panels Overhaul — Adjust, Curves, Filters & Effects**
  - Implement Adjust panel matching Phone 5 (circular dials with perimeter ticks for Exposure, Contrast, Grain; precision sliders; mini Tone Curve box).
  - Implement dedicated Curves panel (RGB and Master channels, interactive glowing spline).
  - Implement Filters panel matching Phone 4 (glass sheet with grab handle, horizontal thumbnail cards, amber selected border, intensity slider).
  - Implement Effects and Presets panels with image-first previews and clean glass controls.

- [x] **Phase 5: Export, Settings & Responsive macOS/Android Architecture**
  - Rebuild Export screen with glass materials, format selector, quality slider, metrics, and native render progress.
  - Rebuild Settings screen with grouped glass cards, diagnostics, privacy guarantee, and developer credit (Mrh Rafi).
  - Ensure responsive adaptation: desktop floating inspector for macOS (>= 768px) and touch ergonomics for mobile (< 768px).

- [x] **Phase 6: Verification, Genuine Screenshots & Final Audit**
  - Verify Flutter tests and C++ native tests.
  - Run `flutter analyze`.
  - Build Android APK debug target.
  - Run macOS desktop app and capture genuine screenshots for all 10 required screens:
    1. Home
    2. Gallery
    3. Crop
    4. Adjust
    5. Filter
    6. Curves
    7. Effects
    8. Presets
    9. Export
    10. Settings
  - Validate visual alignment with user's reference image and compile comprehensive report.
