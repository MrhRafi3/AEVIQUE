import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumaforge/screens/home_screen.dart';
import 'package:lumaforge/services/image_repository.dart';
import 'package:lumaforge/theme/aevique_theme.dart';

class _MockImageRepo implements ImageRepository {
  final Uint8List bytes;
  _MockImageRepo(this.bytes);

  @override
  Future<Uint8List?> pickImageFromGallery() async => bytes;

  @override
  Future<Uint8List?> pickImageFromCamera() async => bytes;

  @override
  Future<Uint8List?> loadSampleAsset(String path) async => bytes;

  @override
  List<SampleImageItem> getSampleImages() => [
    const SampleImageItem(
      title: 'Studio Portrait',
      assetPath: 'assets/images/sample_portrait.jpg',
      description: 'Warm lighting and clean skin tones',
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Capture test screenshot of HomeScreen', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AeviqueTheme.darkTheme,
          home: HomeScreen(imageRepository: _MockImageRepo(Uint8List(0))),
        ),
      ),
    );
    await tester.pump();

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final dir = Directory('review_screenshots');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          final file = File('review_screenshots/test_home.png');
          file.writeAsBytesSync(byteData.buffer.asUint8List());
        }
      });
    }
  });
}
