# Requirements: AEVIQUE Reference-Driven iOS 26 Glass Redesign

## Core Requirements

- **REQ-01: Neutral Dark Glass Material System & Design Tokens**
  - Deep OLED near-black canvas (`#08080A` to `#0D0D11`).
  - Smoked glass translucent fills (`rgba(22, 22, 28, 0.65)` to `rgba(32, 32, 40, 0.75)`).
  - Genuine `BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20))`.
  - Translucent specular borders (`rgba(255, 255, 255, 0.08)` to `0.14)`).
  - Warm Amber / Golden Sun accent (`#E5A125` / `#F5B738`) for active selection, active slider thumbs, degree badges, and ambient glowing FAB.
  - Modern clean sans-serif typography (zero serif/Playfair Display).
  - Floating capsule docks, rounded sheets (`Radius.circular(28-32)`), and perimeter-tick circular dials.

- **REQ-02: Reference-Matched Splash Screen**
  - Dark cinematic atmosphere with subtle ambient lighting.
  - Minimal clean sans-serif AEVIQUE wordmark.
  - Smooth glass fade transition to Home screen.

- **REQ-03: Reference-Matched Home Screen (Phone 1)**
  - Minimal top header: "Explore templates" centered in clean modern sans-serif.
  - Horizontally scrolling category pills ("Reel", "Post", "Vintage", "Classic", "Travel"). Active pill features warm amber rim and subtle warm glow.
  - Large vertical rounded card (corner radius 30) with full-bleed photo, "(06)" badge, "Year in\nReview" clean title, "by Gijack.en" subtitle, and circular amber "+" FAB with warm bloom.
  - Floating frosted glass bottom navigation dock (Star, Gallery, History, Settings).

- **REQ-04: Reference-Matched Gallery & Action Sheet (Phone 2)**
  - Dark photography-first image grid with category filtering.
  - Selected state with amber rim and checkmark.
  - Bottom glass sheet with format chips ("Reel", "Story", "Post", "Carousel") and sleek glass action rows ("Open in Studio Editor", "Remove background", "Create link in bio", "Edit video").

- **REQ-05: Reference-Matched Crop Interface (Phone 3)**
  - Large photo preview with clean 3x3 crop grid, corner bracket handles, and corner white dot nodes.
  - Rotation ruler with floating degree badge ("-10°") and precision tick marks (center tick in amber).
  - Floating contextual mode dock: `[Crop] [Adjust] [Filter] [Curves] [Effects] [Presets]`.
  - Prominent circular golden checkmark FAB at bottom with ambient bloom.
  - Aspect ratio selectors (Free, 1:1, Story 9:16, Post 4:5, 16:9) and rotate/flip controls.

- **REQ-06: Reference-Matched Adjust Interface (Phone 5)**
  - Top row: Perimeter-tick circular dials for Exposure, Contrast, Grain with real-time interactive adjustments.
  - Below dials: Precision sliders with amber glowing thumbs for Brightness, Contrast, Grain, Saturation, Temperature, Highlights, Shadows.
  - Interactive Tone Curve graph preview with glowing spline.

- **REQ-07: Reference-Matched Filters Screen & Panel (Phone 4)**
  - Drag-handled glass bottom sheet.
  - Horizontally scrolling preset cards with real preview thumbnails ("Natural", "Sunset", "Golden hour", "Aesthetic", "Cinematic", "Noir", etc.).
  - Active filter card highlighted with warm amber border and subtle glow.
  - Floating intensity slider.
  - Compact bottom tool icon dock.

- **REQ-08: Reference-Matched Interactive Curves Panel**
  - Full-featured tone curve editor with Master (White), Red, Green, and Blue channel selection.
  - Subtle grid, diagonal baseline, and smooth glowing spline with draggable control points.
  - Direct real-time updates to native C++ engine pipeline.

- **REQ-09: Glass Effects & Presets Experience**
  - Visual cards for Vignette, Film Grain, Light Leak, Halftone, Bloom, Chromatic Aberration.
  - Dedicated Presets browser with category chips, live thumbnails, and intensity slider.

- **REQ-10: Clean Glass Export Flow**
  - Large image preview with format selector (JPEG, PNG).
  - Quality slider with percentage badge and amber track.
  - Resolution metrics and file size estimation.
  - Native C++ full-resolution rendering progress bar.
  - Sleek glass save to disk and share actions.

- **REQ-11: Minimal Grouped Settings Screen**
  - Dark glass grouped cards.
  - Native C++ engine diagnostics (v1.2.0, FFI status, active SIMD).
  - Image quality and export defaults.
  - On-device local privacy guarantee.
  - Developer credit: Mrh Rafi.

- **REQ-12: macOS Desktop & Android Mobile Responsive Layout**
  - Mobile (< 768px): Exact phone layouts matching the reference image.
  - macOS Desktop (>= 768px): Responsive widescreen layout with desktop glass side inspector, keyboard shortcuts, and window adaptability.

- **REQ-13: 100% Engineering Foundation Preservation**
  - Full compatibility with C++ native core v1.2.0, FFI bridge, RGB888/RGBA8888 handling, undo/redo history, preview generation, and full-resolution export.
  - All 23 native C++ tests and 100+ Flutter tests must pass cleanly.

- **REQ-14: Real Visual Acceptance with Genuine Screenshots**
  - Run the application on macOS.
  - Capture genuine screenshots for all 10 required screens:
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
  - Verify match against the user's reference image.
  - Accurately report Android runtime availability.
