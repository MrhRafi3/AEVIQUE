import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumaforge/screens/home_screen.dart';
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

  testWidgets(
    'HomeScreen displays AEVIQUE branding, hero, quick tools and navigation',
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
      await tester.pumpAndSettle();

      // Verify Brand Header
      expect(find.text('AEVIQUE'), findsOneWidget);

      // Verify Hero Presentation
      expect(find.text('Transform Your Photos'), findsOneWidget);
      expect(
        find.text('Professional tools. Stunning results.'),
        findsOneWidget,
      );
      expect(find.text('Start Editing'), findsOneWidget);

      // Verify Quick Tools
      expect(find.text('Crop'), findsOneWidget);
      expect(find.text('Adjust'), findsOneWidget);
      expect(find.text('Portrait'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);

      // Verify Curated Presets
      expect(find.text('CURATED PRESETS'), findsOneWidget);

      // Verify Bottom Navigation items (Home, Library, Presets - Settings is header-only)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Presets'), findsOneWidget);

      // Verify Header Settings icon
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Verify Camera Capture Bar
      expect(find.text('Open Camera'), findsOneWidget);
    },
  );
}
