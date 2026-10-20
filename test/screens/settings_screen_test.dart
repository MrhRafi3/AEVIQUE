import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumaforge/screens/settings_screen.dart';
import 'package:lumaforge/screens/splash_screen.dart';
import 'package:lumaforge/theme/aevique_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Tests', () {
    testWidgets('Displays AEVIQUE branding and Developer credit Mrh Rafi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AeviqueTheme.darkTheme,
          home: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Brand Name and Tagline
      expect(find.text('AEVIQUE'), findsWidgets);
      expect(find.text('See Beyond Ordinary.'), findsOneWidget);
      expect(find.text('Professional Photo Editor'), findsOneWidget);

      // Verify exact required developer credit: Developed by Mrh Rafi
      expect(find.text('Developed by Mrh Rafi'), findsWidgets);

      // Verify Description text
      expect(
        find.text(
          'AEVIQUE is a photo-editing experience built to help you refine colors, enhance details, and express your creative vision.',
        ),
        findsOneWidget,
      );

      // Verify preference controls
      expect(find.text('Default Export Format'), findsOneWidget);
      expect(find.text('High-Precision Preview Cache'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);
    });

    testWidgets('Toggles haptic feedback preference', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AeviqueTheme.darkTheme,
          home: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final hapticFinder = find.widgetWithText(
        SwitchListTile,
        'Haptic Feedback',
      );
      expect(hapticFinder, findsOneWidget);

      await tester.tap(hapticFinder);
      await tester.pumpAndSettle();
    });
  });

  group('SplashScreen Tests', () {
    testWidgets('Renders AEVIQUE logo, wordmark, tagline and credit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AeviqueTheme.darkTheme,
          home: const SplashScreen(displayDuration: Duration(seconds: 10)),
        ),
      );

      expect(find.text('AEVIQUE'), findsOneWidget);
      expect(find.text('See Beyond Ordinary.'), findsOneWidget);
      expect(find.text('Developed by Mrh Rafi'), findsOneWidget);
    });
  });
}
