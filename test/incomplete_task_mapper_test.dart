import 'package:flutter_test/flutter_test.dart';
import 'package:prime_flutter/data/students/student_incomplete_progress.dart';
import 'package:prime_flutter/presentation/home/models/incomplete_task.dart';
import 'package:prime_flutter/presentation/home/models/incomplete_task_mapper.dart';

void main() {
  group('incomplete task mapper', () {
    test('maps all categories and counts from API report', () {
      const report = StudentIncompleteProgressReport(
        incompleteQuizzes: [
          IncompleteQuizItem(
            courseId: 10,
            courseName: 'Math',
            moduleId: 35,
            moduleName: 'Unit 6',
            itemId: 560,
            quizId: 3,
          ),
        ],
        unwatchedLessons: [
          UnwatchedLessonItem(
            courseId: 10,
            courseName: 'Math',
            moduleId: 31,
            moduleName: 'Reading',
            itemId: 132,
            lessonName: 'Lesson 1',
          ),
        ],
        incompleteClassification: [
          IncompleteClassificationItem(
            courseId: 10,
            courseName: 'Math',
            moduleId: 49,
            moduleName: 'Unit 7',
            itemId: 728,
            lessonName: 'Grammar',
            classificationQuizId: 607,
          ),
        ],
        incompleteKnowledge: [
          IncompleteKnowledgeItem(
            courseId: 10,
            courseName: 'Math',
            moduleId: 49,
            moduleName: 'Unit 7',
            itemId: 766,
            lessonName: 'Words',
            knowledgeQuizId: 1029,
          ),
        ],
        incompleteLessonCards: [
          IncompleteLessonCardItem(
            courseId: 10,
            courseName: 'Math',
            moduleId: 15,
            moduleName: 'Unit 5',
            itemId: 387,
            lessonName: 'Lesson A',
          ),
        ],
      );

      final counts = incompleteTaskCounts(report);
      expect(counts[IncompleteTaskCategory.exams], 1);
      expect(counts[IncompleteTaskCategory.lessons], 1);
      expect(counts[IncompleteTaskCategory.categories], 1);
      expect(counts[IncompleteTaskCategory.luckCards], 1);
      expect(counts[IncompleteTaskCategory.memoryCards], 1);
      expect(report.totalCount, 5);

      final exam = incompleteTasksForCategory(
        report,
        IncompleteTaskCategory.exams,
      ).single;
      expect(
        incompleteTaskNavigationPath(exam),
        '/course/10/units/35/quiz/3',
      );

      final lesson = incompleteTasksForCategory(
        report,
        IncompleteTaskCategory.lessons,
      ).single;
      expect(
        incompleteTaskNavigationPath(lesson),
        '/course/10/units/31/lessons/132',
      );

      final classification = incompleteTasksForCategory(
        report,
        IncompleteTaskCategory.categories,
      ).single;
      expect(
        incompleteTaskNavigationPath(classification),
        '/course/10/units/49/lessons/728/classification-quiz/607',
      );

      final luck = incompleteTasksForCategory(
        report,
        IncompleteTaskCategory.luckCards,
      ).single;
      expect(
        incompleteTaskNavigationPath(luck),
        '/course/10/units/49/lessons/766/knowledge-quiz/1029',
      );

      final memory = incompleteTasksForCategory(
        report,
        IncompleteTaskCategory.memoryCards,
      ).single;
      expect(
        incompleteTaskNavigationPath(memory),
        '/course/10/units/15/lessons/387/memory-cards',
      );
    });

    test('parses JSON with snake_case fields', () {
      final report = StudentIncompleteProgressReport.fromJson({
        'incompleteQuizzes': [
          {
            'course_id': 4,
            'course_name': 'English',
            'module_id': 2,
            'module_name': 'Unit 1',
            'item_id': 9,
            'quiz_id': 11,
          },
        ],
      });

      expect(report.incompleteQuizzes.single.quizId, 11);
      expect(report.incompleteQuizzes.single.courseName, 'English');
    });
  });
}
