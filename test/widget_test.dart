import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumafix/main.dart';
import 'package:lumafix/screens/home_screen.dart';
import 'package:lumafix/services/image_repository.dart';

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

  testWidgets('LumaFixApp launches and displays minimal Home Screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      LumaFixApp(home: HomeScreen(imageRepository: MockImageRepository())),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('LUMAFIX'), findsOneWidget);
    expect(find.text('Start Editing'), findsOneWidget);
    expect(find.text('Open Camera'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
