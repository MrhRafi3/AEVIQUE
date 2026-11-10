import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumafix/theme/luma_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('LumaTheme Blue / Orange / Red Liquid Glass Tokens', () {
    test('Primary Liquid Glass and 3-color tokens match specification', () {
      expect(LumaTheme.deepCanvas, const Color(0xFF080A10));
      expect(LumaTheme.primaryBlue, const Color(0xFF3478F6));
      expect(LumaTheme.creativeOrange, const Color(0xFFFF8A32));
      expect(LumaTheme.coralRed, const Color(0xFFF04452));
      expect(LumaTheme.textPrimary, const Color(0xFFFFFFFF));
    });

    test('LumaTheme semantic aliases match specification', () {
      expect(LumaTheme.background, LumaTheme.deepCanvas);
      expect(LumaTheme.accent, LumaTheme.primaryBlue);
      expect(LumaTheme.accentSecondary, LumaTheme.creativeOrange);
      expect(LumaTheme.accentCoral, LumaTheme.coralRed);
      expect(LumaTheme.textPrimary, LumaTheme.textPrimary);
    });

    test('darkTheme configures correct colors', () {
      final theme = LumaTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF080A10));
      expect(theme.primaryColor, const Color(0xFF3478F6));
      expect(theme.colorScheme.onSurface, const Color(0xFFFFFFFF));
    });

    test('wordmarkStyle generates clean sans-serif tracking', () {
      final style = LumaTheme.wordmarkStyle();
      expect(style.letterSpacing, 3.0);
      expect(style.color, const Color(0xFFFFFFFF));
    });
  });
}
