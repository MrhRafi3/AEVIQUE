import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/core/models/edit_state.dart';
import 'package:lumaforge/screens/export_screen.dart';
import 'package:lumaforge/services/export_service.dart';
import 'package:lumaforge/theme/luma_theme.dart';

class MockExportService implements ExportService {
  bool saveCalled = false;
  bool shareCalled = false;

  @override
  Future<bool> saveToGallery(
    Uint8List imageBytes, {
    String name = 'lumaforge_edit',
  }) async {
    saveCalled = true;
    return true;
  }

  @override
  Future<bool> shareImage(
    Uint8List imageBytes, {
    String name = 'lumaforge_edit',
  }) async {
    shareCalled = true;
    return true;
  }
}

void main() {
  late Uint8List sampleBytes;

  setUp(() {
    final image = img.Image(width: 40, height: 30);
    img.fill(image, color: img.ColorRgb8(200, 100, 50));
    sampleBytes = Uint8List.fromList(img.encodeJpg(image));
  });

  testWidgets('ExportScreen handles format changes, saving, and sharing', (
    tester,
  ) async {
    final mockService = MockExportService();

    await tester.pumpWidget(
      MaterialApp(
        theme: LumaTheme.darkTheme,
        home: ExportScreen(
          sourceBytes: sampleBytes,
          state: EditState.identity(),
          exportService: mockService,
        ),
      ),
    );

    // Allow background compute isolate to execute
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.text('Export Photo'), findsOneWidget);
    expect(find.text('JPEG'), findsOneWidget);
    expect(find.text('PNG'), findsOneWidget);
    expect(find.text('Save to Photos'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    // Tap Save to Photos
    await tester.tap(find.text('Save to Photos'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(mockService.saveCalled, isTrue);
    expect(find.text('Photo saved to gallery successfully!'), findsOneWidget);

    // Tap Share
    await tester.tap(find.text('Share'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(mockService.shareCalled, isTrue);

    // Switch to PNG
    await tester.tap(find.text('PNG'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // JPEG Quality slider should disappear when PNG is selected
    expect(find.text('JPEG Quality'), findsNothing);
  });
}
