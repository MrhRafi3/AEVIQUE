import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumaforge/theme/aevique_theme.dart';
import 'package:lumaforge/theme/luma_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AeviqueTheme Reference Glass Tokens', () {
    test('Primary dark glass color tokens match reference specification', () {
      expect(AeviqueTheme.deepBlack, const Color(0xFF09090C));
      expect(AeviqueTheme.textPrimary, const Color(0xFFFFFFFF));
      expect(AeviqueTheme.accentAmber, const Color(0xFFE5A125));
      expect(AeviqueTheme.textMuted, const Color(0xFF707080));
    });

    test('LumaTheme bridges correctly to AeviqueTheme', () {
      expect(LumaTheme.background, AeviqueTheme.deepBlack);
      expect(LumaTheme.accent, AeviqueTheme.accentAmber);
      expect(LumaTheme.textPrimary, AeviqueTheme.textPrimary);
      expect(LumaTheme.textMuted, AeviqueTheme.textMuted);
    });

    test('darkTheme configures correct colors', () {
      final theme = AeviqueTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF09090C));
      expect(theme.primaryColor, const Color(0xFFE5A125));
      expect(theme.colorScheme.onSurface, const Color(0xFFFFFFFF));
    });

    test('wordmarkStyle generates clean sans-serif tracking', () {
      final style = AeviqueTheme.wordmarkStyle();
      expect(style.letterSpacing, 3.0);
      expect(style.color, const Color(0xFFFFFFFF));
    });
  });
}
