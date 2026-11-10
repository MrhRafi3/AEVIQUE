import 'package:flutter/widgets.dart';

/// Design tokens, color palette, dimensions, and typography settings for LumaFix Login.
abstract final class RafiDesignTokens {
  // Stage & Viewport
  static const double stageSize = 1080.0;
  static const double phoneSpan = 500.0;

  // Colors - Page & Screen
  static const Color paper = Color(0xFFE6E1D8);
  static const Color screen = Color(0xFFEFEBE4);
  static const Color ink = Color(0xFF141218);
  static const Color characterInk = Color(0xFF15121C);
  static const Color muted = Color.fromRGBO(20, 18, 24, 0.55);
  static const Color placeholder = Color.fromRGBO(20, 18, 24, 0.32);
  static const Color fieldFill = Color(0xFFFFFFFF);
  static const Color fieldEdge = Color.fromRGBO(20, 18, 24, 0.08);

  // Status & Validation Colors
  static const Color ok = Color(0xFF22C55E);
  static const Color onOk = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE5383B);
  static const Color weak = Color(0xFFF59E0B);
  static const Color strong = Color(0xFF22C55E);

  // Character Palette (5 Vector Characters)
  static const Color cookie = Color(0xFFF2B705);
  static const Color bean = Color(0xFF2B4BDB);
  static const Color sun = Color(0xFF2F9E57);
  static const Color wobble = Color(0xFFF49AC1);
  static const Color pebble = Color(0xFFEF6B2F);
  static const Color eyeWhite = Color(0xFFFFFFFF);
  static const Color tongue = Color(0xFFFF6B8A);

  // Phone Frame & Rings
  static const double phoneLeft = 340.0;
  static const double phoneTop = 110.0;
  static const double phoneWidth = 400.0;
  static const double phoneHeight = 860.0;
  static const double phoneRadius = 60.0;
  static const double innerRing = 10.0;
  static const double outerRing = 1.5;
  static const Color ringInner = Color(0xFF141218);
  static const Color ringOuter = Color(0xFF3A3542);
  static const Color phoneShadowColor = Color.fromRGBO(60, 30, 120, 0.45);

  // Status Bar
  static const double timeLeft = 26.0;
  static const double timeTop = 20.0;
  static const double timeSize = 15.0;
  static const FontWeight timeWeight = FontWeight.w600;
  static const double islandLeft = 140.0;
  static const double islandTop = 14.0;
  static const double islandWidth = 120.0;
  static const double islandHeight = 34.0;
  static const double islandRadius = 20.0;
  static const double statusRight = 26.0;
  static const double statusTop = 22.0;
  static const double statusGap = 6.0;

  // Heading
  static const double titleTop = 262.0;
  static const double titleSize = 40.0;
  static const FontWeight titleWeight = FontWeight.w700;
  static const double titleTracking = -0.03 * 40.0; // -1.2 px
  static const double subtitleTop = 312.0;
  static const double subtitleSize = 16.0;
  static const FontWeight subtitleWeight = FontWeight.w400;

  // Form Fields
  static const double labelLeft = 30.0;
  static const double labelSize = 12.5;
  static const FontWeight labelWeight = FontWeight.w600;
  static const double labelTracking = 0.02 * 12.5; // 0.25 px
  static const double nameLabelTop = 352.0;
  static const double nameTop = 372.0;
  static const double emailLabelTop = 438.0;
  static const double emailTop = 458.0;
  static const double passwordLabelTop = 540.0;
  static const double passwordTop = 560.0;
  static const double fieldInset = 28.0;
  static const double fieldHeight = 56.0;
  static const double fieldRadius = 18.0;
  static const double fieldPaddingHorizontal = 18.0;
  static const double fieldSize = 16.0;
  static const FontWeight fieldWeight = FontWeight.w500;
  static const FontWeight placeholderWeight = FontWeight.w400;
  static const double dotsTracking = 3.0;
  static const double caretWidth = 2.0;
  static const double caretHeight = 20.0;
  static const double caretGap = 1.0;
  static const double caretRadius = 1.0;
  static const double checkSize = 24.0;
  static const double checkFontSize = 14.0;
  static const double errorLeft = 30.0;
  static const double errorTop = 518.0;
  static const double errorSize = 13.0;
  static const FontWeight errorWeight = FontWeight.w500;

  // Password Strength Meter
  static const double meterInset = 30.0;
  static const double meterTop = 624.0;
  static const double meterHeight = 5.0;
  static const double meterRadius = 3.0;
  static const Color meterTrack = Color.fromRGBO(20, 18, 24, 0.08);

  // Button
  static const double buttonInset = 28.0;
  static const double buttonTop = 648.0;
  static const double buttonHeight = 58.0;
  static const double buttonRadius = 999.0;
  static const Color buttonFill = Color(0xFF141218);
  static const Color buttonText = Color(0xFFFFFFFF);
  static const double buttonGap = 10.0;
  static const double buttonSize = 17.0;
  static const FontWeight buttonWeight = FontWeight.w600;
  static const double spinnerSize = 20.0;
  static const double spinnerWidth = 2.5;
  static const Color spinnerTrack = Color.fromRGBO(255, 255, 255, 0.25);

  // Member Footer
  static const double memberTop = 722.0;
  static const double memberSize = 14.0;
  static const FontWeight memberWeight = FontWeight.w400;
  static const FontWeight loginWeight = FontWeight.w700;

  // Tap Indicator
  static const double tapSize = 44.0;
  static const Color tapFill = Color.fromRGBO(20, 18, 24, 0.18);
  static const Color tapEdge = Color.fromRGBO(255, 255, 255, 0.90);

  // Font Family & Bundled Package
  static const String fontFamily = 'Outfit';
  static const String? fontPackage = null;
  static const String legacyPackageName = 'rafi_login_template';

  /// Helper returning a const [TextStyle] using the bundled Outfit font.
  static TextStyle textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      package: fontPackage,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

/// Compatibility aliases
typedef DesignTokens = RafiDesignTokens;
typedef LumaDesignTokens = RafiDesignTokens;
