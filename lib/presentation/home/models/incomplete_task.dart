enum IncompleteTaskCategory {
  exams('اختبارات'),
  lessons('دروس'),
  categories('تصنيفات'),
  luckCards('كروت الحظ'),
  memoryCards('كروت الحفظ');

  const IncompleteTaskCategory(this.label);

  final String label;
}

class IncompleteTask {
  const IncompleteTask({
    required this.category,
    required this.courseLabel,
    required this.unitTitle,
    required this.courseId,
    required this.moduleId,
    required this.itemId,
    this.subtitle,
    this.iconAsset,
    this.quizId,
    this.classificationQuizId,
    this.knowledgeQuizId,
  });

  final IncompleteTaskCategory category;
  final String courseLabel;
  final String unitTitle;
  final int courseId;
  final int moduleId;
  final int itemId;
  final String? subtitle;
  final String? iconAsset;
  final int? quizId;
  final int? classificationQuizId;
  final int? knowledgeQuizId;

  bool get hasSubtitle => subtitle != null;

  bool get isFlashcardStyle =>
      category == IncompleteTaskCategory.luckCards ||
      category == IncompleteTaskCategory.memoryCards;

  String get resolvedIconAsset {
    if (iconAsset != null) return iconAsset!;
    return switch (category) {
      IncompleteTaskCategory.categories =>
        'assets/images/icon_category_podium.png',
      IncompleteTaskCategory.luckCards ||
      IncompleteTaskCategory.memoryCards =>
        'assets/images/icon_luck_card.png',
      _ => 'assets/images/icon_exam_grade.png',
    };
  }
}
