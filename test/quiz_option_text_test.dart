import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/core/widgets/quiz_option_text.dart';

void main() {
  group('QuizOptionText.scaleOptionStyle', () {
    const base = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );

    test('shrinks font so a long English word fits a narrow cell', () {
      const word = 'philanthropic';
      final scaled = QuizOptionText.scaleOptionStyle(
        sample: word,
        style: base,
        maxWidth: 100,
        maxHeight: 120,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      expect(scaled.fontSize!, lessThan(16));

      final painter = TextPainter(
        text: TextSpan(text: word, style: scaled),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      expect(painter.width, lessThanOrEqualTo(100 * 0.99 + 0.5));
      expect(painter.didExceedMaxLines, isFalse);
    });

    test('shrinks complimentary for typical phone answer cell width', () {
      const word = 'complimentary';
      // ~150px cell minus ~16px padding each side ≈ 118
      final scaled = QuizOptionText.scaleOptionStyle(
        sample: word,
        style: base,
        maxWidth: 118,
        maxHeight: 118,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      final painter = TextPainter(
        text: TextSpan(text: word, style: scaled),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      expect(painter.width, lessThanOrEqualTo(118));
    });

    test('keeps short words near the base size', () {
      final scaled = QuizOptionText.scaleOptionStyle(
        sample: 'evil',
        style: base,
        maxWidth: 140,
        maxHeight: 140,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      expect(scaled.fontSize!, closeTo(16, 0.2));
    });

    test('uses longest token when scaling multi-word Arabic+English', () {
      const sample = 'الإجابة philanthropic صحيحة';
      final scaled = QuizOptionText.scaleOptionStyle(
        sample: sample,
        style: base,
        maxWidth: 110,
        maxHeight: 140,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      );

      final longestPainter = TextPainter(
        text: TextSpan(text: 'philanthropic', style: scaled),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 110);
      expect(longestPainter.width, lessThanOrEqualTo(110));
    });

    test('shrinks very long unbroken English strings for phone cells', () {
      const word = 'testtesttesttesttest';
      final scaled = QuizOptionText.scaleOptionStyle(
        sample: word,
        style: base,
        maxWidth: 118,
        maxHeight: 118,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      final painter = TextPainter(
        text: TextSpan(text: word, style: scaled),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 118);
      expect(painter.width, lessThanOrEqualTo(118));
    });
  });

  group('QuizOptionText widget', () {
    testWidgets('single long word uses one line and scales to fit cell', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 118,
                height: 118,
                child: QuizOptionText(
                  html: 'testtesttesttesttest',
                  baseStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.softWrap, isFalse);
      expect(text.maxLines, 1);
      expect(text.data, 'testtesttesttesttest');
    });
  });
}
