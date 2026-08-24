import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/app.dart';

void main() {
  testWidgets('OrmanApp renders base app text', (WidgetTester tester) async {
    await tester.pumpWidget(const OrmanApp());
    expect(find.text('ORMAN Base App'), findsOneWidget);
  });
}
