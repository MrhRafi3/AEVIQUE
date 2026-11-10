import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumafix/core/models/edit_state.dart';
import 'package:lumafix/widgets/crop_overlay_widget.dart';
import 'package:lumafix/widgets/tool_panels/crop_panel.dart';

void main() {
  group('CropOverlayWidget', () {
    testWidgets('Renders crop handles and triggers callback on corner drag', (tester) async {
      double curL = 0.1;
      double curT = 0.1;
      double curR = 0.9;
      double curB = 0.9;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CropOverlayWidget(
                    cropLeft: curL,
                    cropTop: curT,
                    cropRight: curR,
                    cropBottom: curB,
                    imageAspectRatio: 1.0,
                    onCropChanged: (l, t, r, b) {
                      setState(() {
                        curL = l;
                        curT = t;
                        curR = r;
                        curB = b;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CropOverlayWidget), findsOneWidget);

      // Drag top-left corner (at 40, 40)
      final gesture = await tester.startGesture(const Offset(40, 40));
      await gesture.moveBy(const Offset(20, 20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(curL, greaterThan(0.1));
      expect(curT, greaterThan(0.1));
    });

    testWidgets('Allows dragging crop edges (edgeTop)', (tester) async {
      double curL = 0.1;
      double curT = 0.2;
      double curR = 0.9;
      double curB = 0.8;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CropOverlayWidget(
                    cropLeft: curL,
                    cropTop: curT,
                    cropRight: curR,
                    cropBottom: curB,
                    imageAspectRatio: 1.0,
                    onCropChanged: (l, t, r, b) {
                      setState(() {
                        curL = l;
                        curT = t;
                        curR = r;
                        curB = b;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Top edge midpoint is at (200, 80)
      final gesture = await tester.startGesture(const Offset(200, 80));
      await gesture.moveBy(const Offset(0, 40));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(curT, greaterThan(0.2));
      expect(curL, equals(0.1)); // Horizontal sides unchanged
      expect(curR, equals(0.9));
    });

    testWidgets('Maintains locked aspect ratio when aspectRatio is provided', (tester) async {
      double curL = 0.0;
      double curT = 0.0;
      double curR = 1.0;
      double curB = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return CropOverlayWidget(
                    cropLeft: curL,
                    cropTop: curT,
                    cropRight: curR,
                    cropBottom: curB,
                    imageAspectRatio: 1.0,
                    lockedAspectRatio: 1.0, // 1:1 square
                    onCropChanged: (l, t, r, b) {
                      setState(() {
                        curL = l;
                        curT = t;
                        curR = r;
                        curB = b;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Drag bottomRight from (400, 400) inward to (300, 350)
      final gesture = await tester.startGesture(const Offset(400, 400));
      await gesture.moveBy(const Offset(-100, -50));
      await gesture.up();
      await tester.pumpAndSettle();

      // Width and height in normalized coords must be equal for 1:1 on 1:1 image
      final w = curR - curL;
      final h = curB - curT;
      expect((w - h).abs(), lessThan(0.02));
    });
  });

  group('CropPanel', () {
    testWidgets('Updates rotation angle and fires onChanged callback', (tester) async {
      GeometryAdjustments current = const GeometryAdjustments();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CropPanel(
                  geometry: current,
                  onChanged: (g) {
                    setState(() => current = g);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(CropPanel), findsOneWidget);
      expect(find.text('Rotate 90°'), findsOneWidget);

      // Tap Rotate 90°
      await tester.tap(find.text('Rotate 90°'));
      await tester.pumpAndSettle();
      expect(current.rotationQuarterTurns, 1);

      // Tap Flip H
      await tester.tap(find.text('Flip H'));
      await tester.pumpAndSettle();
      expect(current.flipHorizontal, isTrue);
    });
  });
}
