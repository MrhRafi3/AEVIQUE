---
last_mapped_commit: f67daecc77d163ac9a4956fe76ebdf307ac95752
last_mapped_at: 2026-11-06
---
# Conventions

**Analysis Date:** 2026-11-06

## Code Style & Formatting

- Follow standard `dart format` (80 character limit preference)
- Lints governed by `analysis_options.yaml` (`package:flutter_lints/flutter.yaml`)
- Explicit typing preferred for public API boundaries and model properties

## State & Architecture Patterns

- **Immutability:** All editing adjustments (`TuneAdjustments`, `CurvesAdjustments`, `DetailsAdjustments`, `PortraitAdjustments`, etc.) are immutable value objects using `copyWith` methods.
- **Null Safety:** Strict sound null safety throughout all Dart code.
- **Resource Management:** Every `ui.Image`, `AnimationController`, and `Timer` must be explicitly disposed in `dispose()` to prevent memory leaks.
- **Async Safety:** All asynchronous callbacks touching UI state must check `if (!mounted) return;` before invoking `setState`.
- **Haptic Feedback:** Interactive buttons and precision sliders invoke appropriate system haptics (`HapticFeedback.selectionClick()` or `HapticFeedback.lightImpact()`).

## Design System Usage

- Never hardcode raw hex colors or magic spacing in screens or widgets.
- Colors must reference `LumaFixTheme` tokens:
  - Background: `LumaFixTheme.deepBlack` (`#0B0B0D`)
  - Typography: `LumaFixTheme.ivory` (`#F8F6F0`)
  - Accent: `LumaFixTheme.champagneGold` (`#D4AF7C`)
  - Surface: `LumaFixTheme.charcoalSurface` (`#141418`)
  - Elevated: `LumaFixTheme.elevatedCharcoal` (`#1E1E26`)
  - Border: `LumaFixTheme.border` (`#282834`)

## Native C++ Engine Conventions

- C ABI exported functions prefixed with `lumafix_`
- Safe pointer validation and bounds checking on every exported API
- Zero dynamic memory allocations inside inner pixel transformation loops
- OpenMP / vectorized compiler optimizations where supported

---
*Codebase analysis: 2026-11-06*
