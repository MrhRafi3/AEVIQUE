import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AEVIQUE Luxury Brand Theme & Design Tokens
///
/// Palette:
/// - Deep Black: #0B0B0D (dominant background)
/// - Ivory: #F8F6F0 (primary typography & high-contrast highlights)
/// - Champagne Gold: #D4AF7C (refined active controls, selected states & accents)
/// - Slate Gray: #6B6B6B (secondary labels & subtle icons)
/// - Charcoal Surface: #141418 (primary card / panel surface)
/// - Elevated Charcoal: #1E1E26 (toolbars, chips & elevated components)
/// - Subtle Border: #282834 (divider lines & subtle framing)
class AeviqueTheme {
  // Brand Color Tokens
  static const Color deepBlack = Color(0xFF0B0B0D);
  static const Color ivory = Color(0xFFF8F6F0);
  static const Color champagneGold = Color(0xFFD4AF7C);
  static const Color champagneGoldLight = Color(0xFFE8CF9F);
  static const Color champagneGoldDark = Color(0xFFA68550);
  static const Color slateGray = Color(0xFF6B6B6B);

  // Surfaces & Borders
  static const Color charcoalSurface = Color(0xFF141418);
  static const Color elevatedCharcoal = Color(0xFF1E1E26);
  static const Color border = Color(0xFF282834);
  static const Color borderLight = Color(0xFF383848);

  // Semantic Aliases for compatibility
  static const Color background = deepBlack;
  static const Color surface = charcoalSurface;
  static const Color surfaceElevated = elevatedCharcoal;
  static const Color surfaceHighlight = Color(0xFF2A2A36);
  static const Color accent = champagneGold;
  static const Color accentSecondary = champagneGoldLight;
  static const Color textPrimary = ivory;
  static const Color textSecondary = Color(0xFFA0A0B0);
  static const Color textMuted = slateGray;

  /// Signature Wordmark Typography Style
  static TextStyle wordmarkStyle({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 3.5,
    Color color = ivory,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// App Interface Theme
  static ThemeData get darkTheme {
    final baseTextTheme = Typography.material2021().white;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: champagneGold,
      colorScheme: const ColorScheme.dark(
        primary: champagneGold,
        secondary: champagneGoldLight,
        surface: charcoalSurface,
        error: Color(0xFFE05252),
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: ivory,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack,
        foregroundColor: ivory,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: wordmarkStyle(fontSize: 18, letterSpacing: 2.5),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: champagneGold,
        inactiveTrackColor: elevatedCharcoal,
        thumbColor: champagneGold,
        overlayColor: champagneGold.withValues(alpha: 0.2),
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: charcoalSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: charcoalSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      textTheme: interTextTheme.copyWith(
        headlineMedium: GoogleFonts.playfairDisplay(
          color: ivory,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          color: ivory,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        titleMedium: GoogleFonts.inter(
          color: ivory,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          color: ivory,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        labelSmall: GoogleFonts.inter(
          color: slateGray,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
