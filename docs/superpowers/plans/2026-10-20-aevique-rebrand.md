# AEVIQUE Rebrand & UI Transformation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Transform the Flutter photo-editing app into **AEVIQUE** ("See Beyond Ordinary."), featuring an original aperture-inspired geometric logo, a Deep Black (`#0B0B0D`) and Champagne Gold (`#D4AF7C`) design system, Google Fonts typography (Playfair Display & Inter), a native Android launch screen with no white flash, an elegant Splash screen, an upgraded Home screen with quick tools and featured photos, a streamlined 5-category editor (Light, Color, Effects, Detail, Crop), a comprehensive Settings & About screen crediting **Mrh Rafi**, and updated Android app identity.

---

## Proposed Changes & File Architecture

### 1. Brand Tokens & Theme
- Create `lib/theme/aevique_theme.dart`:
  - Primary tokens: Deep Black (`#0B0B0D`), Ivory (`#F8F6F0`), Champagne Gold (`#D4AF7C`), Slate Gray (`#6B6B6B`), Charcoal Surface (`#141418`), Elevated Charcoal (`#1E1E26`), Border (`#282834`).
  - Typography: `GoogleFonts.playfairDisplay` for wordmark & headings; `GoogleFonts.inter` for body and UI controls.
  - Consistent slider themes, buttons, cards, app bar, dialog styles.
- Keep `lib/theme/luma_theme.dart` as an alias/redirect to prevent breaking legacy imports.

### 2. Aperture "A" Logo & Icon System
- Create `lib/widgets/aevique_logo.dart`:
  - `AeviqueLogo`: Vector `CustomPainter` drawing an aperture-inspired geometric "A" with champagne-gold metallic accents and ivory highlights.
  - Scalable for splash screen, app header, about card, and icon sizes.
- Create tool script `scripts/generate_icons.dart`:
  - Generates PNG assets: `assets/images/aevique_logo.png`, `assets/images/aevique_logo_gold.png`, and Android launcher mipmaps:
    - `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
    - `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
    - `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
    - `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
    - `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

### 3. Native Android Launch Screen & Android Configuration
- Update `android/app/src/main/res/values/colors.xml`: Define `splash_color` as `#0B0B0D`.
- Update `android/app/src/main/res/drawable/launch_background.xml` and `drawable-v21/launch_background.xml`: Eliminate white flash by setting window background to `@color/splash_color`.
- Update `android/app/src/main/AndroidManifest.xml`: Set `android:label="AEVIQUE"`.
- Update `pubspec.yaml` name/description/assets.

### 4. Splash Screen
- Create `lib/screens/splash_screen.dart`:
  - Deep Black `#0B0B0D` background with subtle champagne gold ambient radial glow at bottom.
  - Centered animated aperture "A" logo and Playfair Display "AEVIQUE" wordmark.
  - Tagline: "See Beyond Ordinary."
  - Subtle footer: "Developed by Mrh Rafi"
  - Fast, smooth entrance fade (800ms) with direct navigation to `HomeScreen`.

### 5. Settings & About Screen
- Create `lib/screens/settings_screen.dart`:
  - Header: Settings with back button.
  - Preferences: Default Export Format (JPEG/PNG), Quality presets (85%/92%/100%), Haptic feedback toggle.
  - About Section:
    - Large Aperture "A" mark.
    - Wordmark: "AEVIQUE" (Playfair Display).
    - Tagline: *See Beyond Ordinary.*
    - Subtitle: **Professional Photo Editor**
    - Prominent Developer Credit: **Developed by Mrh Rafi** (exact spelling).
    - Description: “AEVIQUE is a photo-editing experience built to help you refine colors, enhance details, and express your creative vision.”
    - Version info (`1.0.0`).
  - Subtle footer at bottom of settings: "Developed by Mrh Rafi".

### 6. Home Screen Upgrades
- Update `lib/screens/home_screen.dart`:
  - Top Bar: Aperture "A" logo, "AEVIQUE" wordmark, Settings icon button.
  - Hero Section: High-impact photographic card with "Transform Your Photos", "Professional tools. Stunning results.", and "Start Editing" CTA in champagne gold.
  - Quick Tools Grid: 4 direct functional entry points (Crop, Adjust, Filters, Effects).
  - Featured Gallery: Sample photos (landscape, portrait, architecture, still life) with one-touch opening into the editor.
  - Bottom Navigation Bar: Home, Library, Presets, Settings.

### 7. Professional Editor Interface
- Update `lib/screens/editor_screen.dart`:
  - Header: Back button (with unsaved edits protection), "AEVIQUE" wordmark, "Original • No Filter" status pill, Undo, Redo, and "Export" button in champagne gold.
  - InteractiveViewer canvas with pinch-to-zoom/pan and press-and-hold before/after comparison.
  - Reorganized 5-category bottom navigation:
    - **Light:** Exposure (EV), Brightness, Contrast, Highlights, Shadows, Whites, Blacks
    - **Color:** Saturation, Vibrance, Warmth (Temperature), Tint
    - **Effects:** Filters (with 30+ categorized catalogue), Vignette, Grain
    - **Detail:** Clarity, Sharpening
    - **Crop:** Crop, Rotate, Aspect Ratio
  - Direct access to Filters panel and individual adjustment drawers.

### 8. Export Screen
- Update `lib/screens/export_screen.dart`:
  - Branded with AEVIQUE Deep Black & Champagne Gold theme.
  - Format selection (JPEG / PNG), quality slider, estimated file size.
  - Non-destructive full-resolution background rendering.
  - Save to Gallery and Share actions.

### 9. Test Suite & Verification
- Update and extend widget and unit tests to verify:
  - AEVIQUE theme tokens and typography.
  - Splash screen and Home screen navigation.
  - Settings screen with required credit "Developed by Mrh Rafi".
  - Editor 5-category tool layout and neutral state preservation.
  - Full test suite passing (`flutter test`).
  - Static analysis clean (`flutter analyze`).
  - Android debug APK build verification (`flutter build apk --debug`).

---

## Tasks

### Task 1: AEVIQUE Design System & Brand Theme
- [ ] Create `lib/theme/aevique_theme.dart` with Deep Black (`#0B0B0D`), Ivory (`#F8F6F0`), Champagne Gold (`#D4AF7C`), Slate Gray (`#6B6B6B`), and Google Fonts (Playfair Display & Inter).
- [ ] Update `lib/theme/luma_theme.dart` to export and alias `AeviqueTheme` so existing code remains backward-compatible.
- [ ] Create unit tests in `test/theme/aevique_theme_test.dart` asserting color tokens and text themes.
- [ ] Verify formatting and analysis.

### Task 2: Aperture "A" Logo & Icon Generation
- [ ] Create `lib/widgets/aevique_logo.dart` implementing the aperture-inspired geometric "A" vector `CustomPainter` with gold and ivory gradients.
- [ ] Write and run `scripts/generate_icons.dart` to generate `assets/images/aevique_logo.png` and all Android launcher mipmap icons (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- [ ] Update `pubspec.yaml` to ensure all asset paths are properly registered.
- [ ] Verify icons exist and are valid PNG images.

### Task 3: Android Native Configuration & Dark Launch
- [ ] Create `android/app/src/main/res/values/colors.xml` with `splash_color` (`#0B0B0D`).
- [ ] Update `android/app/src/main/res/drawable/launch_background.xml` and `android/app/src/main/res/drawable-v21/launch_background.xml` to use `@color/splash_color`.
- [ ] Update `android/app/src/main/AndroidManifest.xml` with `android:label="AEVIQUE"`.
- [ ] Run `flutter build apk --debug` check or build validation.

### Task 4: Splash Screen & Settings / About Screen
- [ ] Create `lib/screens/splash_screen.dart` with deep black background, centered aperture logo, Playfair wordmark, "See Beyond Ordinary.", and subtle developer credit.
- [ ] Create `lib/screens/settings_screen.dart` with preferences and the required About section prominently featuring **Developed by Mrh Rafi**.
- [ ] Write tests in `test/screens/settings_screen_test.dart` asserting "AEVIQUE", "See Beyond Ordinary.", and "Developed by Mrh Rafi" are rendered.

### Task 5: Home Screen & Photo Library Redesign
- [ ] Update `lib/screens/home_screen.dart` to adopt the AEVIQUE design:
  - Header with aperture logo and settings button.
  - Hero card ("Transform Your Photos" / "Professional tools. Stunning results." / "Start Editing").
  - Quick Tools shortcuts (Crop, Adjust, Filters, Effects).
  - Featured samples gallery with multiple photo styles.
  - Bottom navigation bar (Home, Library, Presets, Settings).
- [ ] Update `test/screens/home_screen_test.dart` to verify new branding and actions.

### Task 6: Professional Editor Interface (5 Intuitive Categories)
- [ ] Update `lib/screens/editor_screen.dart` to organize tools into:
  - Light (Exposure, Brightness, Contrast, Highlights, Shadows, Whites, Blacks)
  - Color (Saturation, Vibrance, Warmth, Tint)
  - Effects (Filters, Vignette, Grain)
  - Detail (Clarity, Sharpening)
  - Crop (Crop, Rotate, Aspect Ratio)
- [ ] Ensure the top bar displays "AEVIQUE" with champagne gold accents and the "Original • No Filter" status pill.
- [ ] Update `test/screens/editor_screen_test.dart` to verify all tool categories open and operate seamlessly.

### Task 7: Export Screen & App Entry Point Branding
- [ ] Update `lib/screens/export_screen.dart` to match AEVIQUE luxury styling with Champagne Gold accents.
- [ ] Update `lib/main.dart` with app title "AEVIQUE", initial route pointing to `SplashScreen`, and dark system UI overlay.
- [ ] Update `test/widget_test.dart` to verify the full app flow from Splash to Home.

### Task 8: Full Verification, Static Analysis & Android APK Build
- [ ] Run `dart format .`
- [ ] Run `flutter analyze`
- [ ] Run `flutter test` across all unit, widget, and screen suites.
- [ ] Run `flutter build apk --debug` and verify successful APK creation.
- [ ] Commit all changes to git with a clear commit message.
