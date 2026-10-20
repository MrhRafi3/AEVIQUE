import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/luma_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation bar and status bar overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: LumaTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LumaForgeApp());
}

class LumaForgeApp extends StatelessWidget {
  const LumaForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumaForge',
      debugShowCheckedModeBanner: false,
      theme: LumaTheme.darkTheme,
      home: HomeScreen(),
    );
  }
}
