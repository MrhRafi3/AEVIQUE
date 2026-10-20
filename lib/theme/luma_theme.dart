import 'package:flutter/material.dart';
import 'aevique_theme.dart';

/// Backward-compatible alias directing to [AeviqueTheme].
class LumaTheme {
  static const Color background = AeviqueTheme.deepBlack;
  static const Color surface = AeviqueTheme.charcoalSurface;
  static const Color surfaceElevated = AeviqueTheme.elevatedCharcoal;
  static const Color surfaceHighlight = AeviqueTheme.surfaceHighlight;

  static const Color border = AeviqueTheme.border;
  static const Color borderLight = AeviqueTheme.borderLight;

  static const Color accent = AeviqueTheme.champagneGold;
  static const Color accentSecondary = AeviqueTheme.champagneGoldLight;
  static const Color accentGreen = Color(0xFF34D399);

  static const Color textPrimary = AeviqueTheme.ivory;
  static const Color textSecondary = AeviqueTheme.textSecondary;
  static const Color textMuted = AeviqueTheme.slateGray;

  static ThemeData get darkTheme => AeviqueTheme.darkTheme;
}
