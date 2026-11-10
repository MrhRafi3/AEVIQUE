import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumafix/screens/camera_screen.dart';
import 'package:lumafix/screens/home_screen.dart';
import 'package:lumafix/screens/profile_screen.dart';
import 'package:lumafix/screens/settings_screen.dart';
import 'package:lumafix/services/image_repository.dart';
import 'package:lumafix/theme/luma_theme.dart';
import 'package:lumafix/widgets/motion/abstract_3d_graphics.dart';

class MockImageRepository implements ImageRepository {
  @override
  Future<Uint8List?> pickImageFromGallery() async => null;

  @override
  Future<Uint8List?> pickImageFromCamera() async => null;

  @override
  Future<Uint8List?> loadSampleAsset(String path) async {
    return Uint8List.fromList([1, 2, 3, 4]);
  }

  @override
  List<SampleImageItem> getSampleImages() {
    return const [
      SampleImageItem(
        title: 'Sunset Landscape',
        assetPath: 'assets/images/sample.jpg',
        description: 'Dynamic range landscape',
      ),
      SampleImageItem(
        title: 'Studio Portrait',
        assetPath: 'assets/images/sample_portrait.jpg',
        description: 'Warm studio lighting',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'HomeScreen has exactly the 4 required elements and Abstract 3D Motion Graphics',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockImageRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: HomeScreen(imageRepository: mockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify 3D Motion Graphics background is present
      expect(find.byType(Abstract3DMotionGraphics), findsOneWidget);

      // 2. Verify Minimal LumaFix Branding
      expect(find.text('LUMAFIX'), findsOneWidget);
      expect(find.text('CREATIVE PHOTO ENGINE'), findsOneWidget);

      // 3. Verify The 4 Main Elements:
      // Element A: Start Editing
      expect(find.text('Start Editing'), findsOneWidget);

      // Element B: Open Camera
      expect(find.text('Open Camera'), findsOneWidget);

      // Element C: Profile
      expect(find.text('Profile'), findsOneWidget);

      // Element D: Settings
      expect(find.text('Settings'), findsOneWidget);

      // 4. Verify Tapping Profile navigates to ProfileScreen
      await tester.tap(find.text('Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Pop back
      Navigator.of(tester.element(find.byType(ProfileScreen))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 5. Verify Tapping Settings navigates to SettingsScreen
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Pop back
      Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // 6. Verify Tapping Open Camera navigates to CameraScreen
      await tester.tap(find.text('Open Camera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CameraScreen), findsOneWidget);
    },
  );
}
