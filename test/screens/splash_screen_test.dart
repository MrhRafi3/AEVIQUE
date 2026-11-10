import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumafix/screens/splash_screen.dart';
import 'package:lumafix/theme/luma_theme.dart';
import 'package:lumafix/widgets/luma_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SplashScreen renders LumaLogo, LumaFix, tagline, and exact developer credit',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: const SplashScreen(
            displayDuration: Duration(seconds: 10),
            nextScreen: Scaffold(body: Text('Next Screen Placeholder')),
          ),
        ),
      );

      // Fast-forward animation to completion
      await tester.pump(const Duration(milliseconds: 1400));

      expect(find.byType(LumaLogo), findsOneWidget);
      expect(find.text('LUMAFIX'), findsOneWidget);
      expect(find.text('See Beyond Ordinary.'), findsOneWidget);
      expect(find.text('Developed by Mrh Rafi'), findsOneWidget);
    },
  );
}
