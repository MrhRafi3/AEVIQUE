<div align="center">

# LUMAFIX

### Professional On-Device Photo Editing Studio

**LumaFix is a professional Flutter-powered photo editing application with a high-performance native C++ image processing engine.**

Crafted for photographers, visual artists, and enthusiasts who demand non-destructive pixel precision, tactile feedback, and instantaneous rendering.

<br>

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![C++](https://img.shields.io/badge/C++-17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)](https://isocpp.org/)
[![Platform](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20macOS-black?style=for-the-badge)](https://github.com/MrhRafi3/LumaFix)

<br>

**[Explore Repository](https://github.com/MrhRafi3/LumaFix)**

</div>

---

## ✦ About LumaFix

**LumaFix** is an on-device, privacy-first photo editing experience combining a fluid Flutter interface with a high-performance native C++ image processing engine (`lumafix_core`).

Operating with zero cloud dependencies, LumaFix provides immediate interactive feedback via a real-time preview pipeline while executing export-grade processing via hardware-optimized native C++ algorithms.

## ✨ Core Capabilities

- ⚡ **Dual-Tier Hybrid Architecture** — Real-time reactive preview pipeline connected to a native C++ engine via Dart FFI with seamless pure Dart fallbacks.
- 🎨 **Complete Tone & Color Grading** — Exposure, contrast, saturation, brightness, color temperature (warmth/tint), highlights, shadows, whites, blacks, and midtone ambiance.
- 📈 **Quad-Channel Tone Curves** — Interactive cubic spline curve adjustments for Master RGB, Red, Green, and Blue channels.
- 🎯 **8-Band HSL Color Mixer** — Surgical hue, saturation, and luminance adjustments across Red, Orange, Yellow, Green, Aqua, Blue, Purple, and Magenta with skin-tone protection.
- 🪄 **Photographic Effects Engine** — Film grain synthesis, vintage film tone, chiaroscuro drama, highlight bloom, soft diffusion mist, chromatic aberration, and lens blur bokeh.
- 🔄 **Non-Destructive History** — Instant undo/redo stack, visual history timeline, and real-time before/after comparison viewers.
- 📦 **Studio Presets** — Curated aesthetic profiles (Tokyo Neon, Muted Editorial, Warm Vintage, Moody Dark, High Contrast B&W) and custom preset persistence.
- 💾 **Full-Resolution Native Export** — Fast high-resolution export pipeline with hardware-accelerated JPEG compression and direct gallery saving.

## 🛠️ Architecture & Tech Stack

| Component | Technology | Description |
|---|---|---|
| **UI & Framework** | Flutter 3.44+ / Dart 3.12+ | Liquid Glass design language, custom gestures, tactile haptics |
| **Native Core** | C++17 (`lumafix_core`) | Fused image pipeline, zero-allocation pixel loops, SIMD-friendly layout |
| **Bridge Layer** | Dart FFI (`dart:ffi`) | Low-overhead C ABI bindings with automatic memory management |
| **Build System** | CMake 3.15+ & Gradle | Multiplatform build configuration for Android, macOS, iOS, Windows, Linux |

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.44.0 or newer)
- Dart SDK (v3.12.0 or newer)
- C++17 compatible compiler (Clang / AppleClang / GCC / MSVC)
- CMake (v3.15 or newer)
- Android Studio or Xcode for target platform builds

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/MrhRafi3/LumaFix.git
```

**2. Open the project directory**

```bash
cd LumaFix
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Build the native C++ engine (macOS / Host)**

```bash
mkdir -p native/lumafix_core/build
cd native/lumafix_core/build
cmake ..
cmake --build .
cd ../../..
```

**5. Run the application**

```bash
flutter run
```

## 🧪 Testing & Verification

LumaFix enforces thorough verification across both Flutter and native C++ subsystems:

```bash
# Run complete Flutter test suite (155+ unit & widget tests)
flutter test

# Run C++ native unit tests (27 comprehensive parity & numerical tests)
./native/lumafix_core/build/test_lumafix_engine

# Run static analysis
flutter analyze
```

## 📁 Project Structure

```text
lumafix/
├── android/                    # Android host project & Gradle configuration
├── ios/                        # iOS host project & Xcode configuration
├── macos/                      # macOS desktop runner & project files
├── native/
│   └── lumafix_core/           # High-performance C++17 processing core
│       ├── include/            # C ABI public headers (lumafix_engine.h)
│       ├── src/                # Kernel algorithms & fused pipeline
│       ├── tests/              # Native unit test suite
│       └── benchmarks/         # Micro-benchmarks
├── lib/
│   ├── core/
│   │   ├── image_engine/       # Preview pipeline, filter kernels & LUT generators
│   │   ├── models/             # Immutable EditState & HistoryManager
│   │   ├── native_engine/      # Dart FFI bindings & native engine wrapper
│   │   └── presets/            # Preset definitions & filter catalogues
│   ├── screens/                # Studio screens (Editor, Home, Gallery, Export, etc.)
│   ├── services/               # Image loading, preset persistence & export services
│   ├── theme/                  # LumaTheme Liquid Glass design tokens
│   └── widgets/                # Precision dials, sliders, docks & glass panels
├── assets/                     # Curated high-res samples, fonts & icons
└── test/                       # Comprehensive Flutter test suite
```

## 👨‍💻 Developer

<div align="center">

### Mrh Rafi

Flutter App Developer · Mobile UI Engineer

[![GitHub](https://img.shields.io/badge/GitHub-MrhRafi3-181717?style=for-the-badge&logo=github)](https://github.com/MrhRafi3)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-mrhrafi-0A66C2?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/mrhrafi)

**Developed by Mrh Rafi**

</div>

---

<div align="center">

**LUMAFIX — Precision Photo Studio.**

*Crafted with Flutter, modern C++, and a passion for creative precision.*

</div>
