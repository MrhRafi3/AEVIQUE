import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:lumaforge/screens/editor_screen.dart';
import 'package:lumaforge/screens/export_screen.dart';
import 'package:lumaforge/theme/aevique_theme.dart';
import 'package:lumaforge/theme/luma_theme.dart';
import 'package:lumaforge/widgets/tool_panels/tune_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late Uint8List sampleBytes;

  setUp(() {
    final image = img.Image(width: 40, height: 30);
    img.fill(image, color: img.ColorRgb8(120, 140, 160));
    sampleBytes = Uint8List.fromList(img.encodeJpg(image));
  });

  testWidgets(
    'EditorScreen displays preview, neutral pill, and supports tools and undo',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AeviqueTheme.darkTheme,
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

      // Check initial neutral state pill and AEVIQUE brand
      expect(find.text('AEVIQUE'), findsOneWidget);
      expect(find.text('Original • No Filter'), findsOneWidget);

      expect(find.text('Export'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Portrait'), findsOneWidget);
      expect(find.text('Crop'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Light Adjustments'), findsOneWidget);
      expect(find.text('Curves'), findsOneWidget);

      // Open Light Adjustments tool
      await tester.tap(find.text('Light Adjustments'));
      await tester.pump();

      // TunePanel should now be visible with its sliders and Apply/Cancel
      expect(find.byType(TunePanel), findsOneWidget);
      expect(find.byTooltip('Apply'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);

      // Tap Auto button to change values
      await tester.tap(find.text('Auto'));
      await tester.pump();

      // Tap Apply
      await tester.tap(find.byTooltip('Apply'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // TunePanel should be closed and Undo button enabled
      expect(find.byType(TunePanel), findsNothing);
      expect(find.text('Custom Edits'), findsOneWidget);

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
      expect(find.text('EXPORT PHOTO'), findsOneWidget);
    },
  );

  testWidgets(
    'Safe Back Navigation shows confirmation dialog when unsaved edits exist',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditorScreen(
                        initialImageBytes: sampleBytes,
                        imageName: 'Test Image',
                      ),
                    ),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      );

      // Tap to open editor
      await tester.tap(find.text('Open Editor'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // Apply an edit
      await tester.tap(find.text('Light Adjustments'));
      await tester.pump();
      await tester.tap(find.text('Auto'));
      await tester.pump();
      await tester.tap(find.byTooltip('Apply'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // Tap Back button
      await tester.tap(find.byTooltip('Back to Gallery'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Unsaved Edits Dialog should appear
      expect(find.text('Unsaved Edits'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Save / Export'), findsOneWidget);

      // Tap Keep Editing
      await tester.tap(find.text('Keep Editing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Unsaved Edits'), findsNothing);
      expect(find.byType(EditorScreen), findsOneWidget);

      // Tap Back again and Discard
      await tester.tap(find.byTooltip('Back to Gallery'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Discard'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Should have returned to parent screen
      expect(find.text('Open Editor'), findsOneWidget);
      expect(find.byType(EditorScreen), findsNothing);
    },
  );
}
