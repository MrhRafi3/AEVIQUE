import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/screens/editor_screen.dart';
import 'package:lumaforge/screens/export_screen.dart';
import 'package:lumaforge/theme/luma_theme.dart';
import 'package:lumaforge/widgets/tool_panels/tune_panel.dart';

void main() {
  late Uint8List sampleBytes;

  setUp(() {
    final image = img.Image(width: 40, height: 30);
    img.fill(image, color: img.ColorRgb8(120, 140, 160));
    sampleBytes = Uint8List.fromList(img.encodeJpg(image));
  });

  testWidgets(
    'EditorScreen displays preview, tools, and supports opening tools and undo',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: EditorScreen(
            initialImageBytes: sampleBytes,
            imageName: 'Test Image',
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Refine'), findsOneWidget);
      expect(find.text('Tune Image'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Curves'), findsOneWidget);

      // Open Tune Image tool
      await tester.tap(find.text('Tune Image'));
      await tester.pump();

      // TunePanel should now be visible with its sliders and Apply/Cancel
      expect(find.byType(TunePanel), findsOneWidget);
      expect(find.byTooltip('Apply'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);

      // Tap Auto Tune button to change values
      await tester.tap(find.text('Auto Tune'));
      await tester.pump();

      // Tap Apply
      await tester.tap(find.byTooltip('Apply'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // TunePanel should be closed and Undo button enabled
      expect(find.byType(TunePanel), findsNothing);
      final undoFinder = find.byTooltip('Undo');
      expect(undoFinder, findsOneWidget);

      // Tap Undo
      await tester.tap(undoFinder);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // Tap Export button to open ExportScreen
      await tester.tap(find.text('Export'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.byType(ExportScreen), findsOneWidget);
      expect(find.text('Export Photo'), findsOneWidget);
    },
  );
}
