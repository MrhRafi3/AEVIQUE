import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumaforge/screens/home_screen.dart';
import 'package:lumaforge/screens/presets_screen.dart';
import 'package:lumaforge/services/image_repository.dart';
import 'package:lumaforge/theme/aevique_theme.dart';

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
    'HomeScreen displays AEVIQUE branding, Open Photo, and navigates to Presets',
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
          theme: AeviqueTheme.darkTheme,
          home: HomeScreen(imageRepository: mockRepo),
        ),
      );
      await tester.pump();

      // Verify Brand Header & Tagline
      expect(find.text('AEVIQUE'), findsOneWidget);
      expect(find.text('See Beyond Ordinary.'), findsOneWidget);

      // Verify Prominent Open Photo primary CTA
      expect(find.text('Open Photo'), findsOneWidget);

      // Verify Open Camera action
      expect(find.text('Open Camera'), findsOneWidget);

      // Verify Recent Edits section and empty state
      expect(find.text('RECENT EDITS'), findsOneWidget);
      expect(find.text('Studio Canvas Ready'), findsOneWidget);

      // Verify Developer Credit
      expect(find.text('Developed by Mrh Rafi'), findsOneWidget);

      // Verify Bottom Navigation items: Home and Presets
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Presets'), findsOneWidget);

      // Verify Header Settings icon
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Tap Presets bottom navigation item
      await tester.tap(find.text('Presets'));
      await tester.pump();

      // Verify PresetsScreen is displayed
      expect(find.byType(PresetsScreen), findsOneWidget);
    },
  );
}
