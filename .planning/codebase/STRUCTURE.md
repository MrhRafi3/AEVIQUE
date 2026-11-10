---
last_mapped_commit: f67daecc77d163ac9a4956fe76ebdf307ac95752
last_mapped_at: 2026-11-06
---
# Structure

**Analysis Date:** 2026-11-06

## Directory Layout

```
.
├── android/                   # Android native runner and Gradle scripts
├── assets/images/             # Bundled sample photography assets
├── docs/                      # Architectural plans and documentation
├── ios/                       # iOS native runner
├── lib/                       # Flutter Dart codebase
│   ├── core/                  # Core algorithms, data models, and FFI
│   │   ├── image_engine/      # Pure Dart pipeline & isolate helpers
│   │   ├── models/            # EditState, HistoryManager, adjustment models
│   │   ├── native_engine/     # FFI bindings and dynamic library loader
│   │   └── presets/           # Filter catalogue and curated presets
│   ├── main.dart              # Application entry point
│   ├── screens/               # Screen widgets (Splash, Home, Editor, Presets, Export, Settings)
│   ├── services/              # Platform services (ImageRepository, ExportService)
│   ├── theme/                 # LumaFixTheme design tokens & Google Fonts
│   └── widgets/               # Reusable UI components & individual tool panels
│       └── tool_panels/       # Panels (tune, curves, details, effects, portrait, crop, filters)
├── macos/                     # macOS native runner & Xcode project
├── native/                    # High-performance C++ native engine
│   └── lumafix_core/          # CMake project (include/, src/, tests/, benchmarks/)
└── test/                      # Comprehensive test suite (100+ tests)
    ├── benchmark/             # Performance benchmarks
    ├── core/                  # Pipeline and state unit tests
    ├── screens/               # Screen widget and responsive layout tests
    ├── theme/                 # Theme token tests
    └── widgets/               # UI component tests
```

## Key File Locations

- **Entry Point:** `lib/main.dart`
- **Design Tokens:** `lib/theme/luma_theme.dart`
- **UI Components:** `lib/widgets/luma_ui_components.dart`, `lib/widgets/luma_glass.dart`
- **Editor Canvas:** `lib/screens/editor_screen.dart`
- **Processing Engine:** `lib/core/image_engine/image_pipeline.dart`
- **Native FFI Bridge:** `lib/core/native_engine/lumafix_ffi.dart`
- **Native C++ Engine:** `native/lumafix_core/src/lumafix_engine.cpp`
- **Export Controller:** `lib/screens/export_screen.dart`

---
*Codebase analysis: 2026-11-06*
