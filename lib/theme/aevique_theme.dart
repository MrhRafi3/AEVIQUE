import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AEVIQUE iOS 26 Reference-Driven Glass UI Theme
///
/// Designed strictly according to the reference image:
/// - Dark cinematic atmosphere (deep neutral black canvas).
/// - Translucent smoked-glass layers with specular borders.
/// - Warm Amber / Sun Yellow accent for active states & glowing checkmark FAB.
/// - Clean, modern sans-serif typography (no serif or Playfair Display).
class AeviqueTheme {
  // --- Dark Cinematic Base Palette ---
  static const Color deepBlack = Color(0xFF09090C);
  static const Color darkCanvas = Color(0xFF0C0C10);
  static const Color charcoalSurface = Color(0xFF14141A);
  static const Color elevatedCharcoal = Color(0xFF1C1C24);
  static const Color surfaceCard = Color(0xFF16161E);

  // --- Translucent Glass Materials ---
  static const Color glassSmoked = Color(0x731C1C26); // 45% translucent smoked glass
  static const Color glassElevated = Color(0x8C22222E); // 55% translucent elevated glass
  static const Color glassPill = Color(0x59282836); // 35% translucent pill glass
  static const Color glassOverlay = Color(0x80000000); // 50% dark overlay

  // --- Translucent Subtle Glass Borders ---
  static const Color border = Color(0x1FFFFFFF); // 12% translucent white
  static const Color borderSubtle = Color(0x12FFFFFF); // 7% translucent white
  static const Color borderLight = Color(0x28FFFFFF); // 16% translucent white
  static const Color borderSpecular = Color(0x38FFFFFF); // 22% specular top highlight

  // --- Clean Modern Typography Colors ---
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure crisp white
  static const Color textSecondary = Color(0xFFA2A2B2); // Muted silver
  static const Color textMuted = Color(0xFF707080); // Dim gray

  // --- Reference Warm Amber / Golden Sun Accent ---
  // Derived strictly from Phone 3 FAB, Phone 1 Vintage chip, Phone 3 -10° badge, Phone 5 curve
  static const Color accentAmber = Color(0xFFE5A125);
  static const Color accentAmberLight = Color(0xFFFFD562);
  static const Color accentAmberDark = Color(0xFFB87810);
  static const Color accentAmberGlow = Color(0x59E5A125);
  static const Color accentAmberBg = Color(0x2EE5A125);

  // Semantic Aliases
  static const Color background = deepBlack;
  static const Color surface = charcoalSurface;
  static const Color surfaceElevated = elevatedCharcoal;
  static const Color surfaceHighlight = Color(0xFF262634);
  static const Color accent = accentAmber;
  static const Color accentSecondary = accentAmberLight;

  // Backwards compatibility aliases (to prevent compile breakage during refactoring)
  static const Color champagneGold = accentAmber;
  static const Color champagneGoldLight = accentAmberLight;
  static const Color champagneGoldDark = accentAmberDark;
  static const Color ivory = textPrimary;
  static const Color slateGray = textMuted;

  // Semantic Status Colors
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF60A5FA);

  // Geometry & Radii Tokens
  static const double radiusXs = 6.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;
  static const double radiusFull = 999.0;

  // Spacing Tokens
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // Glass Drop Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 30,
          spreadRadius: 2,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get amberGlow => [
        BoxShadow(
          color: accentAmber.withValues(alpha: 0.4),
          blurRadius: 24,
          spreadRadius: 2,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get goldGlow => amberGlow;

  // Modern Clean Sans-Serif Typography
  static TextStyle wordmarkStyle({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 3.0,
    Color color = textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle sectionHeaderStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.2,
    Color color = textSecondary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle numericValueStyle({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
    Color color = textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // App Interface Theme
  static ThemeData get darkTheme {
    final baseTextTheme = Typography.material2021().white;
    final interTextTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: accentAmber,
      colorScheme: const ColorScheme.dark(
        primary: accentAmber,
        secondary: accentAmberLight,
        surface: charcoalSurface,
        error: error,
        onPrimary: deepBlack,
        onSecondary: deepBlack,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: wordmarkStyle(fontSize: 17, letterSpacing: 1.0, fontWeight: FontWeight.w500),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentAmber,
        inactiveTrackColor: elevatedCharcoal,
        thumbColor: accentAmber,
        overlayColor: accentAmber.withValues(alpha: 0.2),
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6.0,
          elevation: 2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 0.8,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border, width: 0.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: charcoalSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: elevatedCharcoal,
        selectedColor: accentAmber.withValues(alpha: 0.2),
        disabledColor: surfaceHighlight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: border, width: 0.8),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      textTheme: interTextTheme.copyWith(
        headlineMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.normal,
        ),
        labelSmall: GoogleFonts.inter(
          color: textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
