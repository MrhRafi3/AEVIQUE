import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumaforge/screens/home_screen.dart';
import 'package:lumaforge/screens/presets_screen.dart';
import 'package:lumaforge/services/image_repository.dart';
import 'package:lumaforge/theme/aevique_theme.dart';
import 'package:lumaforge/widgets/aevique_ui_components.dart';

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
    'HomeScreen matches Phone 1 reference: Explore templates, categories, and floating dock',
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

      // Verify Phone 1 Top Bar
      expect(find.text('Explore templates'), findsOneWidget);

      // Verify Phone 1 Category Pills
      expect(find.text('Reel'), findsOneWidget);
      expect(find.text('Post'), findsOneWidget);
      expect(find.text('Vintage'), findsOneWidget);
      expect(find.text('Classic'), findsOneWidget);

      // Verify Main Showcase Card
      expect(find.text('Year in\nReview'), findsOneWidget);
      expect(find.text('(06)'), findsOneWidget);
      expect(find.text('by Gijack.en'), findsOneWidget);
      expect(find.byType(AeviqueAmberFab), findsOneWidget);

      // Verify Floating Bottom Dock
      expect(find.byType(AeviqueFloatingDock), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

      // Tap Presets dock item (index 2: tune_rounded)
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pump();

      // Verify PresetsScreen is displayed
      expect(find.byType(PresetsScreen), findsOneWidget);
    },
  );
}
