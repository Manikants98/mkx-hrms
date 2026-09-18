import 'package:flutter_test/flutter_test.dart';
import 'package:employee_app/main.dart';

void main() {
  testWidgets('App initializes successfully smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MkxHrmsApp());
    expect(find.byType(MkxHrmsApp), findsOneWidget);
  });
}
