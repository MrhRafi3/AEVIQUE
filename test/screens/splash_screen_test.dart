import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumaforge/screens/splash_screen.dart';
import 'package:lumaforge/theme/aevique_theme.dart';
import 'package:lumaforge/widgets/aevique_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SplashScreen renders AeviqueLogo, AEVIQUE, tagline, and exact developer credit',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AeviqueTheme.darkTheme,
          home: const SplashScreen(
            displayDuration: Duration(seconds: 10),
            nextScreen: Scaffold(body: Text('Next Screen Placeholder')),
          ),
        ),
      );

      // Fast-forward animation to completion
      await tester.pump(const Duration(milliseconds: 1400));

      expect(find.byType(AeviqueLogo), findsOneWidget);
      expect(find.text('AEVIQUE'), findsOneWidget);
      expect(find.text('See Beyond Ordinary.'), findsOneWidget);
      expect(find.text('Developed by Mrh Rafi'), findsOneWidget);
    },
  );
}
