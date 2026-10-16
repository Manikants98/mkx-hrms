/// Smoke test for MKXMusicApp.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:test_app/main.dart';

void main() {
  testWidgets('MKXMusicApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MKXMusicApp());
    expect(find.byType(MKXMusicApp), findsOneWidget);
  });
}
