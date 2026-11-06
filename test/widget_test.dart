import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumaforge/main.dart';
import 'package:lumaforge/screens/home_screen.dart';
import 'package:lumaforge/services/image_repository.dart';

class MockImageRepository implements ImageRepository {
  @override
  Future<Uint8List?> pickImageFromGallery() async => null;
  @override
  Future<Uint8List?> pickImageFromCamera() async => null;
  @override
  Future<Uint8List?> loadSampleAsset(String path) async => null;
  @override
  List<SampleImageItem> getSampleImages() => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('AeviqueApp launches and displays reference Home Screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      AeviqueApp(home: HomeScreen(imageRepository: MockImageRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explore templates'), findsOneWidget);
    expect(find.text('Vintage'), findsOneWidget);
    expect(find.text('Year in\nReview'), findsOneWidget);
  });
}
