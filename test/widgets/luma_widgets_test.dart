import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumaforge/theme/luma_theme.dart';
import 'package:lumaforge/widgets/before_after_viewer.dart';
import 'package:lumaforge/widgets/luma_slider.dart';

void main() {
  testWidgets('LumaSlider displays title, value, and triggers onChanged', (tester) async {
    double currentValue = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: LumaTheme.darkTheme,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LumaSlider(
              title: 'Brightness',
              value: currentValue,
              min: -100.0,
              max: 100.0,
              onChanged: (val) {
                setState(() => currentValue = val);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Brightness'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Drag slider to the right
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();

    expect(currentValue, greaterThan(0.0));
  });

  testWidgets('BeforeAfterViewer toggles original on press-and-hold', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LumaTheme.darkTheme,
        home: Scaffold(
          body: BeforeAfterViewer(
            originalChild: const Text('ORIGINAL_VIEW'),
            editedChild: const Text('EDITED_VIEW'),
          ),
        ),
      ),
    );

    // Initially edited view is visible
    expect(find.text('EDITED_VIEW'), findsOneWidget);
    expect(find.text('ORIGINAL_VIEW'), findsNothing);

    // Press and hold
    final gesture = await tester.press(find.byType(BeforeAfterViewer));
    await tester.pump();

    expect(find.text('ORIGINAL_VIEW'), findsOneWidget);
    expect(find.text('EDITED_VIEW'), findsNothing);

    // Release
    await gesture.up();
    await tester.pump();

    expect(find.text('EDITED_VIEW'), findsOneWidget);
    expect(find.text('ORIGINAL_VIEW'), findsNothing);
  });
}
