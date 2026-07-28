import 'package:flutter_test/flutter_test.dart';

import 'package:prime_flutter/app/prime_app.dart';

void main() {
  testWidgets('Login screen loads in Arabic', (WidgetTester tester) async {
    await tester.pumpWidget(const PrimeApp());
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump();

    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();

    expect(find.text('مرحباً بك مجدداً'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('الكويت'), findsOneWidget);
  });
}
