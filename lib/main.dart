import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/models/edit_state.dart';
import 'core/native_engine/aevique_ffi.dart';
import 'screens/editor_screen.dart';
import 'screens/export_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/home_screen.dart';
import 'screens/presets_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/image_repository.dart';
import 'theme/aevique_theme.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize native C++ image engine if dynamic library is available on host platform
  AeviqueNativeEngine.tryLoad();

  // Pure dark navigation bar and status bar overlay matching AEVIQUE Deep Black
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AeviqueTheme.deepBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  Widget? initialScreen;
  String? targetScreen;
  for (final arg in args) {
    if (arg.startsWith('--screen=')) {
      targetScreen = arg.substring('--screen='.length).trim().toLowerCase();
      break;
    }
  }

  if (targetScreen != null) {
    initialScreen = await _buildTargetScreen(targetScreen);
  }

  runApp(AeviqueApp(home: initialScreen));
}

Future<Widget> _buildTargetScreen(String screenName) async {
  final imageRepo = DefaultImageRepository();
  ByteData? sampleData;
  try {
    sampleData = await rootBundle.load('assets/images/sample_portrait.jpg');
  } catch (_) {
    try {
      sampleData = await rootBundle.load('assets/images/sample.jpg');
    } catch (_) {}
  }
  final sampleBytes = sampleData?.buffer.asUint8List() ?? Uint8List(0);

  switch (screenName) {
    case 'home':
      return HomeScreen(imageRepository: imageRepo);
    case 'gallery':
      return GalleryScreen(
        imageRepository: imageRepo,
        onBackToHome: () {},
      );
    case 'editor':
      return EditorScreen(
        initialImageBytes: sampleBytes,
        imageName: 'Studio Portrait',
      );
    case 'crop':
      return EditorScreen(
        initialImageBytes: sampleBytes,
        imageName: 'Studio Portrait',
        initialTool: 'crop',
      );
    case 'adjust':
    case 'tune':
      return EditorScreen(
        initialImageBytes: sampleBytes,
        imageName: 'Studio Portrait',
        initialTool: 'adjust',
      );
    case 'filter':
      return EditorScreen(
        initialImageBytes: sampleBytes,
        imageName: 'Studio Portrait',
        initialTool: 'filter',
      );
    case 'curves':
      return EditorScreen(
        initialImageBytes: sampleBytes,
        imageName: 'Studio Portrait',
        initialTool: 'curves',
      );
    case 'effects':
      return EditorScreen(
        initialImageBytes: sampleBytes,
        imageName: 'Studio Portrait',
        initialTool: 'effects',
      );
    case 'presets':
      return PresetsScreen(
        imageRepository: imageRepo,
        onBackToHome: () {},
      );
    case 'export':
      return ExportScreen(
        sourceBytes: sampleBytes,
        state: EditState.identity(),
      );
    case 'settings':
      return const SettingsScreen();
    case 'splash':
    default:
      return const SplashScreen();
  }
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
