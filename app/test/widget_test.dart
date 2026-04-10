import 'package:flutter_test/flutter_test.dart';
import 'package:urban_analytics_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UrbanAnalyticsApp());
    expect(find.text('Mapa — em desenvolvimento'), findsOneWidget);
  });
}
