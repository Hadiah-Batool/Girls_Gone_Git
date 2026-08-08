// Basic smoke test for the Rehnumai app.
//
// Verifies that the app boots, the bottom navigation bar is present,
// and the Darsgah heatmap screen renders without errors.

import 'package:flutter_test/flutter_test.dart';
import 'package:rehnumai/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    // Build the app and trigger the first frame.
    await tester.pumpWidget(const RehnumaiApp());
    await tester.pump();

    // The bottom navigation bar should be visible.
    expect(find.text('Darsgah'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.text('Nazar'), findsOneWidget);
    expect(find.text('Amal'), findsOneWidget);

    // The Darsgah screen's section title should be on screen.
    expect(find.text('Class Status'), findsOneWidget);
  });
}
