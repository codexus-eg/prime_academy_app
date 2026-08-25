import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/core/widgets/quiz_html_text.dart';

void main() {
  group('QuizHtmlText.detectTextDirection', () {
    test('uses first Arabic letter even when English is longer', () {
      const html =
          '<p><mark>ماذا تقول في الموقف التالي</mark></p>'
          '<p>Oh, I didn\'t wake up for my school at 6 o\'clock</p>';
      expect(
        QuizHtmlText.detectTextDirection(html),
        TextDirection.rtl,
      );
    });

    test('uses first English letter for English-first prompts', () {
      expect(
        QuizHtmlText.detectTextDirection('What do you say in this situation?'),
        TextDirection.ltr,
      );
    });

    test('strips HTML tags before reading the first letter', () {
      expect(
        QuizHtmlText.detectTextDirection('<p><strong>Hello</strong></p>'),
        TextDirection.ltr,
      );
      expect(
        QuizHtmlText.detectTextDirection('<p><mark>مرحبا</mark></p>'),
        TextDirection.rtl,
      );
    });

    test('defaults empty input to rtl like the web client', () {
      expect(QuizHtmlText.detectTextDirection(''), TextDirection.rtl);
    });

    test('english line with trailing question mark stays ltr', () {
      expect(
        QuizHtmlText.detectTextDirection('study or studies?'),
        TextDirection.ltr,
      );
    });
  });

  group('QuizHtmlText.splitParagraphs', () {
    test('keeps separate HTML paragraphs', () {
      const html = '<p>First paragraph about pillows.</p>'
          '<p>As time passed, people used fabric.</p>'
          '<p>Today pillows are everywhere.</p>';
      expect(QuizHtmlText.splitParagraphs(html), [
        'First paragraph about pillows.',
        'As time passed, people used fabric.',
        'Today pillows are everywhere.',
      ]);
    });

    test('splits blank lines in plain text', () {
      const html = 'First paragraph.\n\nSecond paragraph.';
      expect(QuizHtmlText.splitParagraphs(html), [
        'First paragraph.',
        'Second paragraph.',
      ]);
    });
  });
}
