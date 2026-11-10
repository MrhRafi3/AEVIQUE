import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumafix/core/models/edit_state.dart';
import 'package:lumafix/theme/luma_theme.dart';
import 'package:lumafix/widgets/curve_editor_widget.dart';
import 'package:lumafix/widgets/tool_panels/curves_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurveEditorWidget Interaction & Zero Overflow', () {
    testWidgets('Renders on narrow screen (320px width) without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      FlutterErrorDetails? overflowError;
      final prevHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          overflowError = details;
        }
        prevHandler?.call(details);
      };

      ToneCurves current = const ToneCurves();

      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CurvesPanel(
                    curves: current,
                    onChanged: (c) => setState(() => current = c),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      FlutterError.onError = prevHandler;
      expect(overflowError, isNull, reason: overflowError?.toString());
      expect(find.byType(CurveEditorWidget), findsOneWidget);
    });

    testWidgets('Tap on curve adds a new control point and enables dragging', (tester) async {
      ToneCurves current = const ToneCurves();

      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 380,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return CurveEditorWidget(
                      curves: current,
                      onCurvesChanged: (c) => setState(() => current = c),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(current.rgb.length, 2); // Initial 2 endpoints

      // Find the canvas gesture detector and tap in the middle to add a point
      final gestureFinder = find.descendant(
        of: find.byType(CurveEditorWidget),
        matching: find.byType(GestureDetector),
      ).last;
      final centerTap = tester.getCenter(gestureFinder);

      // Tap to add control point
      await tester.tapAt(centerTap);
      await tester.pumpAndSettle();

      expect(current.rgb.length, 3);
      expect((current.rgb[1].x - 0.5).abs(), lessThan(0.08));

      // Drag the added point upward
      await tester.dragFrom(centerTap, const Offset(0, -60));
      await tester.pumpAndSettle();

      expect(current.rgb[1].y, greaterThan(0.55));
    });

    testWidgets('Channel switching preserves each channel independent curve', (tester) async {
      ToneCurves current = const ToneCurves();

      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 380,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return CurveEditorWidget(
                      curves: current,
                      onCurvesChanged: (c) => setState(() => current = c),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Select 'Red' tab
      await tester.tap(find.text('Red'));
      await tester.pumpAndSettle();

      // Add a point to Red channel
      final gestureFinder = find.descendant(
        of: find.byType(CurveEditorWidget),
        matching: find.byType(GestureDetector),
      ).last;
      final redTap = tester.getCenter(gestureFinder);
      await tester.tapAt(redTap);
      await tester.pumpAndSettle();

      expect(current.red.length, 3);
      expect(current.rgb.length, 2); // Master RGB channel remained identity!

      // Switch back to RGB tab
      await tester.tap(find.text('RGB'));
      await tester.pumpAndSettle();

      // Switch back to Red tab
      await tester.tap(find.text('Red'));
      await tester.pumpAndSettle();

      // Red channel modifications must still be preserved
      expect(current.red.length, 3);
    });

    testWidgets('Reset channel resets only current channel, Reset All resets all', (tester) async {
      ToneCurves current = ToneCurves(
        rgb: const [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.8), CurvePoint(1.0, 1.0)],
        red: const [CurvePoint(0.0, 0.0), CurvePoint(0.5, 0.7), CurvePoint(1.0, 1.0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: LumaTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 380,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return CurveEditorWidget(
                      curves: current,
                      onCurvesChanged: (c) => setState(() => current = c),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Reset RGB channel
      final resetCurrentBtn = find.byTooltip('Reset Channel');
      expect(resetCurrentBtn, findsOneWidget);
      await tester.tap(resetCurrentBtn);
      await tester.pumpAndSettle();

      expect(current.rgb.length, 2); // RGB reset to identity
      expect(current.red.length, 3); // Red still modified

      // Reset All Channels
      final resetAllBtn = find.byTooltip('Reset All Channels');
      expect(resetAllBtn, findsOneWidget);
      await tester.tap(resetAllBtn);
      await tester.pumpAndSettle();

      expect(current.rgb.length, 2);
      expect(current.red.length, 2);
      expect(current.isIdentity, isTrue);
    });
  });
}
