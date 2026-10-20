import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumaforge/theme/aevique_theme.dart';
import 'package:lumaforge/theme/luma_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AeviqueTheme Tokens', () {
    test('Primary color tokens match specification', () {
      expect(AeviqueTheme.deepBlack, const Color(0xFF0B0B0D));
      expect(AeviqueTheme.ivory, const Color(0xFFF8F6F0));
      expect(AeviqueTheme.champagneGold, const Color(0xFFD4AF7C));
      expect(AeviqueTheme.slateGray, const Color(0xFF6B6B6B));
    });

    test('LumaTheme bridges correctly to AeviqueTheme', () {
      expect(LumaTheme.background, AeviqueTheme.deepBlack);
      expect(LumaTheme.accent, AeviqueTheme.champagneGold);
      expect(LumaTheme.textPrimary, AeviqueTheme.ivory);
      expect(LumaTheme.textMuted, AeviqueTheme.slateGray);
    });

    test('darkTheme configures correct colors', () {
      final theme = AeviqueTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0B0D));
      expect(theme.primaryColor, const Color(0xFFD4AF7C));
      expect(theme.colorScheme.onSurface, const Color(0xFFF8F6F0));
    });

    test('wordmarkStyle generates Playfair Display with tracking', () {
      final style = AeviqueTheme.wordmarkStyle();
      expect(style.letterSpacing, 3.5);
      expect(style.color, const Color(0xFFF8F6F0));
    });
  });
}
