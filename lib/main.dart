import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'theme/aevique_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Pure dark navigation bar and status bar overlay matching AEVIQUE Deep Black
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AeviqueTheme.deepBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AeviqueApp());
}

class AeviqueApp extends StatelessWidget {
  final Widget? home;

  const AeviqueApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AEVIQUE',
      debugShowCheckedModeBanner: false,
      theme: AeviqueTheme.darkTheme,
      home: home ?? const SplashScreen(),
    );
  }
}

// Backward-compatible alias
typedef LumaForgeApp = AeviqueApp;
