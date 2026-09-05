import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/core/widgets/quiz_html_text.dart';
import 'package:prime_flutter/data/quizzes/answered_question_display.dart';
import 'package:prime_flutter/data/quizzes/answered_question_models.dart';

void main() {
  group('re-order student_answer parsing', () {
    test('shows student order when API stores a number array like the web', () {
      final question = AnsweredQuizQuestion.fromJson({
        'id': 'ro-1',
        'type': 're-order',
        'title': 'رتب منطقيا Re-order',
        'is_correct': true,
        'awarded_points': 1,
        'points': 1,
        'answers': [
          {'id': 1, 'title': 'People'},
          {'id': 2, 'title': 'used to'},
          {'id': 3, 'title': 'barter goods'},
          {'id': 4, 'title': 'before'},
          {'id': 5, 'title': 'the invention'},
          {'id': 6, 'title': 'of money'},
        ],
        'correct_answers': [
          {'answer_id': 1, 'order': 0},
          {'answer_id': 2, 'order': 1},
          {'answer_id': 3, 'order': 2},
          {'answer_id': 4, 'order': 3},
          {'answer_id': 5, 'order': 4},
          {'answer_id': 6, 'order': 5},
        ],
        'student_answer': [1, 2, 3, 4, 5, 6],
      });

      expect(question.notAnswered, isFalse);
      expect(question.studentAnswerLines, [
        'People',
        'used to',
        'barter goods',
        'before',
        'the invention',
        'of money',
      ]);
      expect(question.correctAnswerLines, question.studentAnswerLines);
    });

    test('shows student order when API stores a position map', () {
      final question = AnsweredQuizQuestion.fromJson({
        'id': 'ro-2',
        'type': 're-order',
        'title': 'Reorder',
        'is_correct': true,
        'awarded_points': 1,
        'points': 1,
        'answers': [
          {'id': 10, 'title': 'A'},
          {'id': 11, 'title': 'B'},
        ],
        'correct_answers': [
          {'answer_id': 10, 'order': 0},
          {'answer_id': 11, 'order': 1},
        ],
        'student_answer': {'0': 10, '1': 11},
      });

      expect(question.notAnswered, isFalse);
      expect(question.studentAnswerLines, ['A', 'B']);
    });
  });

  group('matching student_answer mapping', () {
    Map<String, dynamic> matchingJson(Object studentAnswer) => {
          'id': 'm-1',
          'type': 'match',
          'title': 'Match the following',
          'is_correct': false,
          'awarded_points': 0,
          'points': 1,
          'prompts': [
            {
              'id': 1,
              'title': 'current',
              'response': {'id': 10, 'title': 'تيار الهواء او الماء', 'prompt_id': 1},
            },
            {
              'id': 2,
              'title': 'unreliable',
              'response': {'id': 11, 'title': 'لا يُعتمد عليه', 'prompt_id': 2},
            },
          ],
          'student_answer': studentAnswer,
        };

    test('resolves submit format {responseId: promptId}', () {
      final question = AnsweredQuizQuestion.fromJson(
        matchingJson({'10': 1, '11': 2}),
      );
      expect(question.notAnswered, isFalse);
      expect(question.studentAnswerLines.length, 2);
      expect(
        QuizHtmlText.plainText(question.studentAnswerLines.first),
        contains('current'),
      );
      expect(
        QuizHtmlText.plainText(question.studentAnswerLines.first),
        contains('تيار الهواء او الماء'),
      );
    });

    test('resolves review format {promptId: responseId}', () {
      final question = AnsweredQuizQuestion.fromJson(
        matchingJson({'1': 10, '2': 11}),
      );
      expect(question.studentAnswerLines.length, 2);
      expect(
        QuizHtmlText.plainText(question.studentAnswerLines[1]),
        contains('unreliable'),
      );
    });
  });

  group('mixed script direction', () {
    test('arabic-first mixed prompt stays rtl', () {
      expect(
        QuizHtmlText.detectTextDirection(
          'كلمه كل وصل Match the following بمعناها',
        ),
        TextDirection.rtl,
      );
    });

    test('english-first mixed prompt stays ltr', () {
      expect(
        QuizHtmlText.detectTextDirection('current تيار الهواء او الماء'),
        TextDirection.ltr,
      );
    });

    test('bidi isolate does not change first-strong direction of inner text', () {
      final isolated = QuizHtmlText.bidiIsolate('تيار الهواء او الماء');
      expect(QuizHtmlText.detectTextDirection(isolated), TextDirection.rtl);
    });
  });
}
