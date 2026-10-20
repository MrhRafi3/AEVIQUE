import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/screens/editor_screen.dart';
import 'package:lumaforge/screens/presets_screen.dart';
import 'package:lumaforge/services/image_repository.dart';
import 'package:lumaforge/theme/aevique_theme.dart';

class MockPresetsImageRepository implements ImageRepository {
  final Uint8List sampleBytes;

  MockPresetsImageRepository(this.sampleBytes);

  @override
  Future<Uint8List?> pickImageFromGallery() async => sampleBytes;

  @override
  Future<Uint8List?> pickImageFromCamera() async => sampleBytes;

  @override
  Future<Uint8List?> loadSampleAsset(String path) async => sampleBytes;

  @override
  List<SampleImageItem> getSampleImages() => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Uint8List testImageBytes;

  setUp(() {
    final image = img.Image(width: 40, height: 40);
    img.fill(image, color: img.ColorRgb8(180, 150, 120));
    testImageBytes = Uint8List.fromList(img.encodeJpg(image));
  });

  testWidgets(
    'PresetsScreen loads preview photograph, displays filter filmstrip, and supports selection & editing',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockPresetsImageRepository(testImageBytes);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeviqueTheme.darkTheme,
          home: PresetsScreen(imageRepository: mockRepo),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 350));
      });
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Screen Header
      expect(find.text('PRESETS & STYLES'), findsOneWidget);

      // Verify Actions: Try on My Photo & Edit Photo
      expect(find.text('Try on My Photo'), findsOneWidget);
      expect(find.text('Edit Photo'), findsOneWidget);

      // Verify Core Filters in filmstrip
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Vivid'), findsOneWidget);
      expect(find.text('Dramatic'), findsOneWidget);

      // Tap 'Vivid' filter
      await tester.tap(find.text('Vivid'));
      await tester.pump();
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump(const Duration(milliseconds: 200));

      // Intensity slider should now be visible for active filter
      expect(find.text('Intensity'), findsOneWidget);

      // Tap 'Edit Photo' button to navigate to EditorScreen
      await tester.tap(find.text('Edit Photo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // EditorScreen should now be open
      expect(find.byType(EditorScreen), findsOneWidget);
    },
  );
}
