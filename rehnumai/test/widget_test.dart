// Basic smoke test for the Rehnumai app.

import 'package:flutter_test/flutter_test.dart';
import 'package:rehnumai/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const RehnumaiApp());
    await tester.pump();

    // Verify key navigation items are present
    expect(find.text('Darsgah'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Nazar'), findsOneWidget);
    expect(find.text('Amal'), findsOneWidget);
  });
}
