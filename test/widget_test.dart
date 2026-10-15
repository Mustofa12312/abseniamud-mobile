import 'package:flutter_test/flutter_test.dart';
import 'package:iaimu_mobile/main.dart';

void main() {
  testWidgets('IAIMU App initializes without error', (WidgetTester tester) async {
    await tester.pumpWidget(const IaimuAttendanceApp());
    expect(find.byType(IaimuAttendanceApp), findsOneWidget);
  });
}
