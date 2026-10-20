import 'package:flutter_test/flutter_test.dart';
import 'package:lumaforge/main.dart';

void main() {
  testWidgets('LumaForgeApp launches and displays HomeScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LumaForgeApp());
    await tester.pumpAndSettle();

    expect(find.text('LUMA FORGE'), findsOneWidget);
    expect(find.text('Open Photo'), findsOneWidget);
    expect(find.text('Sample Studio Photos'), findsOneWidget);
  });
}
