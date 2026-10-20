import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/screens/editor_screen.dart';
import 'package:lumaforge/theme/aevique_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List testImageBytes;

  setUp(() {
    final image = img.Image(width: 80, height: 60);
    img.fill(image, color: img.ColorRgb8(100, 120, 140));
    testImageBytes = Uint8List.fromList(img.encodeJpg(image));
  });

  testWidgets(
    'EditorScreen renders on small 320dp width screen without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      FlutterErrorDetails? caughtError;
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          caughtError = details;
        }
        prevHandler?.call(details);
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AeviqueTheme.darkTheme,
          home: EditorScreen(
            initialImageBytes: testImageBytes,
            imageName: 'Narrow Test',
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      FlutterError.onError = prevHandler;
      expect(caughtError, isNull, reason: caughtError?.toString());
    },
  );
}
