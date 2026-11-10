import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumafix/screens/login_screen.dart';
import 'package:lumafix/theme/luma_theme.dart';
import 'package:lumafix/widgets/luma_logo.dart';
import 'package:lumafix/widgets/auth/design_tokens.dart';
import 'package:lumafix/widgets/auth/password_strength.dart';

Widget buildTestableScreen(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: LumaTheme.darkTheme,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('LumaFix LoginScreen Integration Tests', () {
    testWidgets('1. Renders default LumaFix branding, title, and LumaLogo', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080.0, 1080.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableScreen(const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(LumaLogo), findsOneWidget);
      expect(find.text('LumaFix'), findsOneWidget);
      expect(find.text('Precision Photo Studio'), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.byKey(const Key('identifier_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('skip_to_studio_button')), findsOneWidget);
    });

    testWidgets('2. Empty form validation displays error and prevents submission', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080.0, 1080.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool loginCalled = false;
      await tester.pumpWidget(
        buildTestableScreen(
          LoginScreen(
            onLogin: (credentials) {
              loginCalled = true;
              return const AuthResult.success();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final buttonFinder = find.byKey(const Key('login_button'));
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.textContaining('Please enter your email'), findsOneWidget);
      expect(loginCalled, false);
    });

    testWidgets('3. Valid identifier and password clears errors and submits', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080.0, 1080.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      LoginCredentials? capturedCredentials;
      bool authenticated = false;

      await tester.pumpWidget(
        buildTestableScreen(
          LoginScreen(
            onLogin: (credentials) {
              capturedCredentials = credentials;
              return const AuthResult.success();
            },
            onAuthenticated: (credentials) {
              authenticated = true;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Enter valid email and password
      await tester.enterText(
        find.byKey(const Key('identifier_field')),
        'creator@lumafix.app',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'studioPass123',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(capturedCredentials, isNotNull);
      expect(capturedCredentials!.identifier, 'creator@lumafix.app');
      expect(capturedCredentials!.password, 'studioPass123');
      expect(authenticated, true);
    });

    testWidgets('4. Password visibility toggle shows and hides password text', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080.0, 1080.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableScreen(const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 50));

      final passwordFieldFinder = find.byKey(const Key('password_field'));
      TextField textField = tester.widget<TextField>(passwordFieldFinder);
      expect(textField.obscureText, true);

      final toggleFinder = find.byKey(
        const Key('password_visibility_toggle'),
      );
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pump();

      textField = tester.widget<TextField>(passwordFieldFinder);
      expect(textField.obscureText, false);
    });

    testWidgets('5. Skip to studio bypass invokes onSkip or navigates', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080.0, 1080.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool skipCalled = false;
      await tester.pumpWidget(
        buildTestableScreen(
          LoginScreen(
            onSkip: () {
              skipCalled = true;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final skipFinder = find.byKey(const Key('skip_to_studio_button'));
      expect(skipFinder, findsOneWidget);
      await tester.tap(skipFinder);
      await tester.pump();

      expect(skipCalled, true);
    });

    testWidgets('6. Responsive rendering across mobile and large formats', (
      WidgetTester tester,
    ) async {
      final testSizes = [
        const Size(360.0, 640.0),
        const Size(390.0, 844.0),
        const Size(1080.0, 1080.0),
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(buildTestableScreen(const LoginScreen()));
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('login_button')), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('7. 3-field mode with optional Name validates correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080.0, 1080.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableScreen(
          const LoginScreen(showNameField: true, showPasswordStrength: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byType(PasswordStrengthMeter), findsOneWidget);
    });

    test('8. DesignTokens correctly defines Outfit font', () {
      expect(RafiDesignTokens.fontFamily, 'Outfit');
      expect(RafiDesignTokens.legacyPackageName, 'rafi_login_template');
    });
  });
}
