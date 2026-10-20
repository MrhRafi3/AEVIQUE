import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumaforge/screens/home_screen.dart';
import 'package:lumaforge/services/image_repository.dart';
import 'package:lumaforge/theme/luma_theme.dart';

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
  testWidgets('HomeScreen displays app branding and open actions', (
    tester,
  ) async {
    final mockRepo = MockImageRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: LumaTheme.darkTheme,
        home: HomeScreen(imageRepository: mockRepo),
      ),
    );

    expect(find.text('LUMA FORGE'), findsOneWidget);
    expect(find.text('Open Photo'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Sunset Landscape'), findsOneWidget);
    expect(find.text('Studio Portrait'), findsOneWidget);
  });
}
