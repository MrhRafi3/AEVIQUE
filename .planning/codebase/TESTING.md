---
last_mapped_commit: f67daecc77d163ac9a4956fe76ebdf307ac95752
last_mapped_at: 2026-11-06
---
# Testing

**Analysis Date:** 2026-11-06

## Test Framework & Organization

- **Unit & Widget Tests:** `flutter_test`
- **Native Unit Tests:** C++ executable `native/lumafix_core/build/test_lumafix_engine`
- **Test Locations:**
  - `test/core/`: Image pipeline, numerical parity between Dart and C++, edit state mutations, history undo/redo.
  - `test/screens/`: Screen rendering, navigation transitions, tool drawer interactions, and responsive layout tests (from 320px narrow phones to 1200px desktop widths).
  - `test/theme/`: Brand color tokens and typography verification.
  - `test/widgets/`: Slider detents, before-after viewers, and custom glass surfaces.

## Execution Commands

- **Run all Flutter tests:**
  ```bash
  flutter test test/screens test/core test/theme test/widgets
  ```
- **Run native C++ tests:**
  ```bash
  ./native/lumafix_core/build/test_lumafix_engine
  ```
- **Run static analysis:**
  ```bash
  flutter analyze
  ```

## Testing Patterns & Best Practices

- **Repository Abstraction:** External platform dependencies (`ImageRepository`, `ExportService`, `RecentEditsRepository`) are injected as interface dependencies, allowing fast in-memory mocking in widget tests without hardware or simulator dependencies.
- **Offline Font Handling:** Tests run in headless environments where online Google Fonts fetch is disabled; tests verify structure and behavior with bundled font fallbacks.

---
*Codebase analysis: 2026-11-06*
