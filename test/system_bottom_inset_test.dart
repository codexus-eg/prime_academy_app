import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prime_flutter/core/widgets/system_bottom_inset.dart';

void main() {
  testWidgets('SystemBottomInset uses viewPadding.bottom', (tester) async {
    late double inset;
    late double clearance;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(bottom: 0),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        child: Builder(
          builder: (context) {
            inset = SystemBottomInset.of(context);
            clearance = SystemBottomInset.contentClearanceOf(
              context,
              barContentHeight: 128,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(inset, 48);
    expect(clearance, 176);
  });

  testWidgets('BottomDockedSafeArea pads child by system inset', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(390, 844),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: BottomDockedSafeArea(
            backgroundColor: Color(0xFF112233),
            child: SizedBox(height: 64, width: double.infinity),
          ),
        ),
      ),
    );

    final padding = tester.widget<Padding>(find.byType(Padding).first);
    expect(padding.padding, const EdgeInsets.only(bottom: 48));
  });

  testWidgets('BottomDockedSafeArea skips padding when inset is 0', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(390, 844),
          viewPadding: EdgeInsets.zero,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: BottomDockedSafeArea(
            child: SizedBox(key: Key('bare'), height: 64),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('bare')), findsOneWidget);
    expect(find.byType(Padding), findsNothing);
  });
}
