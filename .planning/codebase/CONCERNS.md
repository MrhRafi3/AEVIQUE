---
last_mapped_commit: f67daecc77d163ac9a4956fe76ebdf307ac95752
last_mapped_at: 2026-11-06
---
# Concerns & Technical Debt

**Analysis Date:** 2026-11-06

## 1. UI Redesign & Brand Transition
- **Remaining Legacy Naming:** The project was originally named `lumaforge` before rebranding to `AEVIQUE`. Backward-compatibility aliases (`LumaTheme`, `LumaForgeApp`) exist to prevent regressions, but older styling conventions linger in some tool panels.
- **Desktop/macOS Optimization:** The existing layout is predominantly phone-first. While it scales without overflow, macOS users benefit from a true desktop workspace featuring a sidebar inspector and mouse-friendly controls rather than mobile-style bottom sheets.

## 2. Tool Panels Visual Cohesion
- Individual editing panels (`tune_panel.dart`, `crop_panel.dart`, `details_panel.dart`, `effects_panel.dart`, `filters_panel.dart`, `portrait_panel.dart`, `presets_panel.dart`, `curve_editor_widget.dart`) must adhere strictly to the new AEVIQUE luxury darkroom visual identity (deep charcoal, champagne gold, ivory, zero-detent sliders, and refined spacing).
- Old material styling in tool subpanels must be replaced with `AeviqueUIComponents` and `AeviqueTheme`.

## 3. High-DPI & Large Photo Memory Management
- Full-resolution camera imports on modern smartphones (48MP–200MP) require careful memory handling during preview generation and export.
- The pipeline correctly generates a 1200px max preview buffer, but native export must continuously monitor memory pressure.

## 4. Test Hygiene
- Scratch screenshot tests in `test/verify_screenshot_test.dart` contain print statements and unhandled font loading that must be cleaned up to achieve a spotless `flutter analyze`.

---
*Codebase analysis: 2026-11-06*
