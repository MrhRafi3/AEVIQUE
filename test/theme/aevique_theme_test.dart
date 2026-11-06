import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumaforge/theme/aevique_theme.dart';
import 'package:lumaforge/theme/luma_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AeviqueTheme Blue / Orange / Red Liquid Glass Tokens', () {
    test('Primary Liquid Glass and 3-color tokens match specification', () {
      expect(AeviqueTheme.deepCanvas, const Color(0xFF080A10));
      expect(AeviqueTheme.primaryBlue, const Color(0xFF3478F6));
      expect(AeviqueTheme.creativeOrange, const Color(0xFFFF8A32));
      expect(AeviqueTheme.coralRed, const Color(0xFFF04452));
      expect(AeviqueTheme.textPrimary, const Color(0xFFFFFFFF));
    });

    test('LumaTheme bridges correctly to AeviqueTheme', () {
      expect(LumaTheme.background, AeviqueTheme.deepCanvas);
      expect(LumaTheme.accent, AeviqueTheme.primaryBlue);
      expect(LumaTheme.accentSecondary, AeviqueTheme.creativeOrange);
      expect(LumaTheme.accentCoral, AeviqueTheme.coralRed);
      expect(LumaTheme.textPrimary, AeviqueTheme.textPrimary);
    });

    test('darkTheme configures correct colors', () {
      final theme = AeviqueTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF080A10));
      expect(theme.primaryColor, const Color(0xFF3478F6));
      expect(theme.colorScheme.onSurface, const Color(0xFFFFFFFF));
    });

    test('wordmarkStyle generates clean sans-serif tracking', () {
      final style = AeviqueTheme.wordmarkStyle();
      expect(style.letterSpacing, 3.0);
      expect(style.color, const Color(0xFFFFFFFF));
    });
  });
}
