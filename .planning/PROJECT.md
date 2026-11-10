# LumaFix — iOS 26 Reference-Driven Glass Interface Redesign

## What This Is

LumaFix is a commercial-grade, premium photo editing application for macOS and Android powered by an on-device high-performance native C++ image processing engine (v1.2.0).

This milestone completely replaces the entire legacy visual identity with an **iOS 26-inspired dark translucent layered glass UI**, exactly derived from the user's provided visual reference.

## Primary Design Directive

The user-supplied reference image (`media_1793957422727_c4da5a91.jpg`) is the sole design specification:
- Dark cinematic atmosphere (deep OLED charcoal/black backgrounds `#08080A` - `#0D0D11`).
- Genuine translucent glass materials (`BackdropFilter`, `ImageFilter.blur`, smoked glass fills, specular borders).
- Warm Amber / Golden Sun accent (`#E5A125`, `#F5B738`) strictly for active states, selected rims, curve spline, and the circular checkmark FAB with ambient warm bloom.
- Clean modern sans-serif typography (no serif or Playfair Display).
- Photography-first presentation with uncluttered, floating glass controls.
- Recreated Phone 1 (Home/Templates), Phone 2 (Action Sheet & Gallery), Phone 3 (Crop & Geometry), Phone 4 (Filter Carousel), Phone 5 (Adjust Dials & Tone Curves).
- macOS desktop and Android mobile responsive adaptation.

## Non-Negotiable Rules

1. Zero legacy visual retention: No champagne/gold theme, no ivory text, no Playfair Display, no old card designs or dashboard widgets.
2. 100% functional preservation: Native C++ engine (23/23 tests), FFI bridge, preview pipeline, full-res export, undo/redo history, filter kernels.
3. Verification with genuine screenshots on macOS and accurate reporting of Android device availability.

## Developer Credit

Mrh Rafi
