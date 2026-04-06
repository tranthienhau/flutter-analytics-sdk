import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_analytics_sdk/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AnalyticsApp());
    expect(find.text('Analytics Dashboard'), findsOneWidget);
  });
}
