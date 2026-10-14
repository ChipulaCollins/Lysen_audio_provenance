import 'package:flutter_test/flutter_test.dart';
import 'package:lysen/main.dart';

void main() {
  testWidgets('Lysen App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const LysenApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Lysen Studio'), findsOneWidget);
  });
}
