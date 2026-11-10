import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LumaFix — Transparent Liquid Glass · Abstract 3D Motion · Blue / Orange / Red Theme
///
/// Designed as a premium, Apple-inspired creative photo application:
/// - Transparent liquid glass / water glassmorphism surfaces.
/// - Cobalt Blue (#3478F6) primary interactive accent.
/// - Vibrant Creative Orange (#FF8A32) secondary / creative emphasis.
/// - Modern Coral Red (#F04452) destructive / selected visual accents.
/// - Optical glass borders with specular refraction highlights.
/// - High-clarity modern typography.
class LumaTheme {
  // --- Core Balanced 3-Color System ---

  // Primary Blue: Cobalt Blue / Electric Blue
  static const Color primaryBlue = Color(0xFF3478F6);
  static const Color primaryBlueLight = Color(0xFF5E98FC);
  static const Color primaryBlueDark = Color(0xFF1E5AD6);
  static const Color primaryBlueGlow = Color(0x593478F6);
  static const Color primaryBlueSurface = Color(0x283478F6);

  // Secondary Orange: Vibrant Creative Orange
  static const Color creativeOrange = Color(0xFFFF8A32);
  static const Color creativeOrangeLight = Color(0xFFFFA663);
  static const Color creativeOrangeDark = Color(0xFFDF6B15);
  static const Color creativeOrangeGlow = Color(0x59FF8A32);
  static const Color creativeOrangeSurface = Color(0x28FF8A32);

  // Accent Red: Modern Coral Red
  static const Color coralRed = Color(0xFFF04452);
  static const Color coralRedLight = Color(0xFFF67580);
  static const Color coralRedDark = Color(0xFFD32635);
  static const Color coralRedGlow = Color(0x59F04452);
  static const Color coralRedSurface = Color(0x28F04452);

  // --- Deep Canvas & Ambient Base Palette ---
  static const Color deepCanvas = Color(0xFF080A10); // Ultra-deep studio space
  static const Color studioSurface = Color(0xFF0E131E);
  static const Color studioSurfaceElevated = Color(0xFF151C2C);
  static const Color studioSurfaceCard = Color(0xFF1A2337);

  // --- Transparent Liquid Glass Materials ---
  static const Color glassLiquidUltraClear = Color(
    0x0DFFFFFF,
  ); // 5% pure water glass
  static const Color glassLiquidClear = Color(0x17FFFFFF); // 9% liquid glass
  static const Color glassLiquidMedium = Color(0x26FFFFFF); // 15% optical glass
  static const Color glassLiquidDeep = Color(
    0x4D0E131F,
  ); // 30% tinted deep glass
  static const Color glassOverlay = Color(0x8004060A); // 50% dark overlay

  // --- Liquid Glass Specular Borders ---
  static const Color glassBorder = Color(0x33FFFFFF); // 20% translucent white
  static const Color glassBorderSubtle = Color(
    0x18FFFFFF,
  ); // 10% translucent white
  static const Color glassBorderLight = Color(
    0x47FFFFFF,
  ); // 28% translucent white
  static const Color glassBorderSpecular = Color(
    0x73FFFFFF,
  ); // 45% top specular highlight

  // --- Clean Modern Typography Colors ---
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure crisp white
  static const Color textSecondary = Color(
    0xFFA5B2D1,
  ); // Soft atmospheric silver-blue
  static const Color textMuted = Color(0xFF6B7A99); // Dim gray-blue

  // --- Semantic Aliases ---
  static const Color background = deepCanvas;
  static const Color surface = studioSurface;
  static const Color surfaceElevated = studioSurfaceElevated;
  static const Color surfaceHighlight = Color(0xFF222C42);
  static const Color accent = primaryBlue;
  static const Color accentSecondary = creativeOrange;
  static const Color accentDestructive = coralRed;
  static const Color accentCoral = coralRed;

  // --- Backward-Compatible Aliases ---
  static const Color deepBlack = deepCanvas;
  static const Color darkCanvas = deepCanvas;
  static const Color charcoalSurface = studioSurface;
  static const Color elevatedCharcoal = studioSurfaceElevated;
  static const Color surfaceCard = studioSurfaceCard;
  static const Color glassSmoked = glassLiquidDeep;
  static const Color glassElevated = glassLiquidDeep;
  static const Color glassPill = glassLiquidMedium;
  static const Color border = glassBorder;
  static const Color borderSubtle = glassBorderSubtle;
  static const Color borderLight = glassBorderLight;
  static const Color borderSpecular = glassBorderSpecular;
  static const Color accentAmber = creativeOrange;
  static const Color accentAmberLight = creativeOrangeLight;
  static const Color accentAmberDark = creativeOrangeDark;
  static const Color accentAmberGlow = creativeOrangeGlow;
  static const Color accentAmberBg = creativeOrangeSurface;
  static const Color champagneGold = creativeOrange;
  static const Color champagneGoldLight = creativeOrangeLight;
  static const Color champagneGoldDark = creativeOrangeDark;
  static const Color ivory = textPrimary;
  static const Color slateGray = textMuted;

  // --- Semantic Status Colors ---
  static const Color success = Color(0xFF34D399);
  static const Color error = coralRed;
  static const Color warning = creativeOrange;
  static const Color info = primaryBlue;

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
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.55),
      blurRadius: 36,
      spreadRadius: 2,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> get blueGlow => [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.45),
      blurRadius: 24,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get orangeGlow => [
    BoxShadow(
      color: creativeOrange.withValues(alpha: 0.45),
      blurRadius: 24,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get redGlow => [
    BoxShadow(
      color: coralRed.withValues(alpha: 0.45),
      blurRadius: 24,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  // Compatibility getter
  static List<BoxShadow> get amberGlow => orangeGlow;
  static List<BoxShadow> get goldGlow => orangeGlow;

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
      scaffoldBackgroundColor: deepCanvas,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: creativeOrange,
        tertiary: coralRed,
        surface: studioSurface,
        error: coralRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: wordmarkStyle(
          fontSize: 17,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryBlue,
        inactiveTrackColor: glassBorderSubtle,
        thumbColor: primaryBlue,
        overlayColor: primaryBlue.withValues(alpha: 0.2),
        trackHeight: 3.0,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 7.0,
          elevation: 3,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: glassBorderSubtle,
        thickness: 0.8,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: studioSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: glassBorder, width: 0.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: studioSurface,
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: glassBorderLight, width: 1),
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
        backgroundColor: glassLiquidClear,
        selectedColor: primaryBlue.withValues(alpha: 0.25),
        disabledColor: surfaceHighlight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: const BorderSide(color: glassBorder, width: 0.8),
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
