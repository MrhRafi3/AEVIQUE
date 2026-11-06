import 'package:flutter/material.dart';
import 'aevique_theme.dart';

/// Backward-compatible bridge to [AeviqueTheme].
class LumaTheme {
  static const Color background = AeviqueTheme.deepCanvas;
  static const Color surface = AeviqueTheme.studioSurface;
  static const Color surfaceElevated = AeviqueTheme.studioSurfaceElevated;
  static const Color accent = AeviqueTheme.primaryBlue;
  static const Color accentSecondary = AeviqueTheme.creativeOrange;
  static const Color accentCoral = AeviqueTheme.coralRed;
  static const Color textPrimary = AeviqueTheme.textPrimary;
  static const Color textSecondary = AeviqueTheme.textSecondary;
  static const Color textMuted = AeviqueTheme.textMuted;
  static const Color border = AeviqueTheme.glassBorder;
  static const Color borderSubtle = AeviqueTheme.glassBorderSubtle;

  static ThemeData get darkTheme => AeviqueTheme.darkTheme;
}
