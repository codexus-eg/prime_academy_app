import 'package:flutter_test/flutter_test.dart';

import 'package:prime_flutter/core/utils/json_bool.dart';
import 'package:prime_flutter/data/quizzes/essay_answer_validation.dart';
import 'package:prime_flutter/data/quizzes/unit_quiz_question.dart';

void main() {
  group('parseApiBool', () {
    test('accepts bool, int, and string forms', () {
      expect(parseApiBool(true), isTrue);
      expect(parseApiBool(false), isFalse);
      expect(parseApiBool(1), isTrue);
      expect(parseApiBool(0), isFalse);
      expect(parseApiBool('true'), isTrue);
      expect(parseApiBool('1'), isTrue);
      expect(parseApiBool('false'), isFalse);
      expect(parseApiBool('0'), isFalse);
      expect(parseApiBool(null), isFalse);
      expect(parseApiBool(null, fallback: true), isTrue);
    });
  });

  group('EssayAnswerValidation (word-match rules)', () {
    const longTitle = 'Both Ahmed and Sara are hungry';

    test('3+ words: two matching words is correct', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: [longTitle],
          studentAnswer: 'both Ahmed and Sara',
        ),
        isTrue,
      );
    });

    test('3+ words: one matching word is incorrect', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: [longTitle],
          studentAnswer: 'both',
        ),
        isFalse,
      );
    });

    test('3+ words: full sentence is correct', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: [longTitle],
          studentAnswer: 'both Ahmed and Sara are hungry',
        ),
        isTrue,
      );
    });

    test('2 words: one matching word is correct', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: const ['good students'],
          studentAnswer: 'good',
        ),
        isTrue,
      );
    });

    test('2 words: no matching word is incorrect', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: const ['good students'],
          studentAnswer: 'bad teachers',
        ),
        isFalse,
      );
    });

    test('1 word: exact match is correct', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: const ['Apple'],
          studentAnswer: 'apple',
        ),
        isTrue,
      );
    });

    test('1 word: partial or extra text is incorrect', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: const ['Apple'],
          studentAnswer: 'apple pie',
        ),
        isFalse,
      );
    });

    test('case differences are ignored', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: const ['Both ahmed and Sara are good students'],
          studentAnswer: 'Ahmed both sara',
        ),
        isTrue,
      );
    });

    test('mark_all_answers_correct accepts any non-empty answer', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: true,
          correctTitles: [longTitle],
          studentAnswer: 'anything',
        ),
        isTrue,
      );
    });

    test('any listed correct title matches (OR)', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: const ['Answer A', 'Answer B'],
          studentAnswer: 'answer',
        ),
        isTrue,
      );
    });

    test('HTML in correct title is stripped before compare', () {
      expect(
        EssayAnswerValidation.isCorrect(
          markAllAnswersCorrect: false,
          correctTitles: const ['<p>Both ahmed and Sara are good students</p>'],
          studentAnswer: 'Ahmed both sara',
        ),
        isTrue,
      );
    });
  });

  group('UnitEssayQuestion mark_all parsing', () {
    test('reads MySQL TINYINT 1 as true', () {
      final q = UnitEssayQuestion.fromJson({
        'id': 'e1',
        'title': 'Q',
        'points': 1,
        'mark_all_answers_correct': 1,
        'correct_answers': [
          {'id': 1, 'title': 'Both Ahmed and Sara are hungry'},
        ],
      });
      expect(q.markAllAnswersCorrect, isTrue);
    });
  });
}
