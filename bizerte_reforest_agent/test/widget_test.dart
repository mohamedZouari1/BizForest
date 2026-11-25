import 'package:flutter_test/flutter_test.dart';
import 'package:bizerte_reforest_agent/main.dart';

void main() {
  testWidgets('App launches on onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const BizForestApp());
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(BizForestApp), findsOneWidget);
  });
}
