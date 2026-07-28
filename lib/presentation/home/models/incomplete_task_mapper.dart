import '../../../data/students/student_incomplete_progress.dart';
import '../../classification_quiz/classification_quiz_page.dart';
import '../../course/lesson_detail_page.dart';
import '../../course/memory_cards_page.dart';
import '../../exam/exam_page.dart';
import '../../luck_cards/luck_cards_page.dart';
import 'incomplete_task.dart';

Map<IncompleteTaskCategory, int> incompleteTaskCounts(
  StudentIncompleteProgressReport report,
) {
  return {
    IncompleteTaskCategory.exams: report.incompleteQuizzes.length,
    IncompleteTaskCategory.lessons: report.unwatchedLessons.length,
    IncompleteTaskCategory.categories: report.incompleteClassification.length,
    IncompleteTaskCategory.luckCards: report.incompleteKnowledge.length,
    IncompleteTaskCategory.memoryCards: report.incompleteLessonCards.length,
  };
}

List<IncompleteTaskCategory> visibleIncompleteCategories(
  StudentIncompleteProgressReport report,
) {
  final counts = incompleteTaskCounts(report);
  return IncompleteTaskCategory.values
      .where((category) => (counts[category] ?? 0) > 0)
      .toList();
}

List<IncompleteTask> incompleteTasksForCategory(
  StudentIncompleteProgressReport report,
  IncompleteTaskCategory category,
) {
  return switch (category) {
    IncompleteTaskCategory.exams => report.incompleteQuizzes
        .map(
          (item) => IncompleteTask(
            category: category,
            courseLabel: item.courseName,
            unitTitle: item.moduleName,
            courseId: item.courseId,
            moduleId: item.moduleId,
            itemId: item.itemId,
            quizId: item.quizId,
          ),
        )
        .toList(),
    IncompleteTaskCategory.lessons => report.unwatchedLessons
        .map(
          (item) => IncompleteTask(
            category: category,
            courseLabel: item.courseName,
            unitTitle: item.moduleName,
            subtitle: item.lessonName,
            courseId: item.courseId,
            moduleId: item.moduleId,
            itemId: item.itemId,
          ),
        )
        .toList(),
    IncompleteTaskCategory.categories => report.incompleteClassification
        .map(
          (item) => IncompleteTask(
            category: category,
            courseLabel: item.courseName,
            unitTitle: item.moduleName,
            subtitle: item.lessonName,
            courseId: item.courseId,
            moduleId: item.moduleId,
            itemId: item.itemId,
            classificationQuizId: item.classificationQuizId,
          ),
        )
        .toList(),
    IncompleteTaskCategory.luckCards => report.incompleteKnowledge
        .map(
          (item) => IncompleteTask(
            category: category,
            courseLabel: item.courseName,
            unitTitle: item.moduleName,
            subtitle: item.lessonName,
            courseId: item.courseId,
            moduleId: item.moduleId,
            itemId: item.itemId,
            knowledgeQuizId: item.knowledgeQuizId,
          ),
        )
        .toList(),
    IncompleteTaskCategory.memoryCards => report.incompleteLessonCards
        .map(
          (item) => IncompleteTask(
            category: category,
            courseLabel: item.courseName,
            unitTitle: item.moduleName,
            subtitle: item.lessonName,
            courseId: item.courseId,
            moduleId: item.moduleId,
            itemId: item.itemId,
          ),
        )
        .toList(),
  };
}

String incompleteTaskNavigationPath(IncompleteTask task) {
  final courseId = '${task.courseId}';
  final moduleId = '${task.moduleId}';
  final lessonId = '${task.itemId}';

  return switch (task.category) {
    IncompleteTaskCategory.exams => ExamPage.pathFor(
        courseId: courseId,
        unitId: moduleId,
        quizId: task.quizId ?? 0,
      ),
    IncompleteTaskCategory.lessons => LessonDetailPage.pathFor(
        courseId: courseId,
        unitId: moduleId,
        lessonId: lessonId,
      ),
    IncompleteTaskCategory.categories => ClassificationQuizPage.pathFor(
        courseId: courseId,
        unitId: moduleId,
        lessonId: lessonId,
        quizId: task.classificationQuizId ?? 0,
      ),
    IncompleteTaskCategory.luckCards => LuckCardsPage.pathFor(
        courseId: courseId,
        unitId: moduleId,
        lessonId: lessonId,
        quizId: task.knowledgeQuizId ?? 0,
      ),
    IncompleteTaskCategory.memoryCards => MemoryCardsPage.pathFor(
        courseId: courseId,
        unitId: moduleId,
        lessonId: lessonId,
      ),
  };
}
