import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumafix/core/models/mask_model.dart';
import 'package:lumafix/widgets/tool_panels/mask_panel.dart';

void main() {
  testWidgets('MaskPanel renders selection controls and local adjustment categories', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    List<SelectiveMask> currentMasks = [
      SelectiveMask(
        id: 'test_1',
        name: 'Brush 1',
        type: MaskType.brush,
        opacity: 1.0,
        adjustments: const MaskToneAdjustments(exposure: 10.0),
      ),
    ];

    bool overlayEnabled = true;
    int? activeIdx = 0;
    bool subjectSelected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: MaskPanel(
                  masks: currentMasks,
                  showMaskOverlay: overlayEnabled,
                  activeMaskIndex: activeIdx,
                  onMasksChanged: (m) => setState(() => currentMasks = m),
                  onOverlayToggled: (v) => setState(() => overlayEnabled = v),
                  onActiveMaskChanged: (i) => setState(() => activeIdx = i),
                  brushSize: 30.0,
                  brushHardness: 0.7,
                  brushOpacity: 1.0,
                  isEraseMode: false,
                  onBrushSizeChanged: (_) {},
                  onBrushHardnessChanged: (_) {},
                  onBrushOpacityChanged: (_) {},
                  onEraseModeChanged: (_) {},
                  onUndoStroke: () {},
                  canUndoStroke: true,
                  onSelectSubject: () => subjectSelected = true,
                  isSegmentingSubject: false,
                ),
              );
            },
          ),
        ),
      ),
    );

    // Verify initial controls exist
    expect(find.text('Select Subject'), findsOneWidget);
    expect(find.text('Add Mask'), findsOneWidget);
    expect(find.text('Rubylith Overlay'), findsOneWidget);
    expect(find.text('Brush 1'), findsOneWidget);

    // Tap 'Select Subject'
    await tester.tap(find.text('Select Subject'));
    await tester.pumpAndSettle();
    expect(subjectSelected, isTrue);

    // Verify adjustment sub-tabs exist: Light, Color, HSL, Effects
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('HSL'), findsOneWidget);
    expect(find.text('Effects'), findsOneWidget);

    // Tap Invert button
    final invertBtn = find.byTooltip('Invert Mask');
    expect(invertBtn, findsOneWidget);
    await tester.tap(invertBtn);
    await tester.pumpAndSettle();
    expect(currentMasks.first.inverted, isTrue);
  });

  testWidgets('MaskPanel tabs switch cleanly and sliders update adjustment models', (tester) async {
    tester.view.physicalSize = const Size(320, 900); // 320px narrow phone
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SelectiveMask testMask = SelectiveMask(
      id: 'test_m',
      name: 'Subject 1',
      type: MaskType.subject,
      adjustments: const MaskToneAdjustments(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: MaskPanel(
                  masks: [testMask],
                  showMaskOverlay: true,
                  activeMaskIndex: 0,
                  onMasksChanged: (m) => setState(() => testMask = m.first),
                  onOverlayToggled: (_) {},
                  onActiveMaskChanged: (_) {},
                  brushSize: 30.0,
                  brushHardness: 0.7,
                  brushOpacity: 1.0,
                  isEraseMode: false,
                  onBrushSizeChanged: (_) {},
                  onBrushHardnessChanged: (_) {},
                  onBrushOpacityChanged: (_) {},
                  onEraseModeChanged: (_) {},
                  onUndoStroke: () {},
                  canUndoStroke: false,
                  onSelectSubject: () {},
                  isSegmentingSubject: false,
                ),
              );
            },
          ),
        ),
      ),
    );

    // Switch to Color tab
    await tester.tap(find.text('Color'));
    await tester.pumpAndSettle();
    expect(find.text('Warmth / Temp'), findsOneWidget);
    expect(find.text('Saturation'), findsOneWidget);
    expect(find.text('Vibrance'), findsOneWidget);

    // Switch to HSL tab
    await tester.tap(find.text('HSL'));
    await tester.pumpAndSettle();
    expect(find.text('Red'), findsWidgets);
    expect(find.text('Red Hue'), findsOneWidget);
    expect(find.text('Red Saturation'), findsOneWidget);
    expect(find.text('Red Luminance'), findsOneWidget);

    // Switch to Effects tab
    await tester.ensureVisible(find.text('Effects'));
    await tester.tap(find.text('Effects'));
    await tester.pumpAndSettle();
    expect(find.text('Clarity'), findsOneWidget);
    expect(find.text('Texture'), findsOneWidget);
    expect(find.text('Dehaze'), findsOneWidget);
    expect(find.text('Sharpness'), findsOneWidget);
  });
}
