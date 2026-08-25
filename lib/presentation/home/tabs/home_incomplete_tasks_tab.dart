import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/students/student_incomplete_progress.dart';
import '../../../data/students/student_profile.dart';
import '../../../data/students/students_api.dart';
import '../models/incomplete_task.dart';
import '../models/incomplete_task_mapper.dart';
import '../student_profile_scope.dart';
import '../widgets/incomplete_task_card.dart';
import '../widgets/incomplete_tasks_all_complete.dart';
import '../widgets/incomplete_tasks_category_bar.dart';
import '../widgets/incomplete_tasks_content_transition.dart';
import '../widgets/incomplete_tasks_course_header.dart';
import '../../common/anchored_select_menu.dart';

class HomeIncompleteTasksTab extends StatefulWidget {
  const HomeIncompleteTasksTab({super.key});

  @override
  State<HomeIncompleteTasksTab> createState() => _HomeIncompleteTasksTabState();
}

class _HomeIncompleteTasksTabState extends State<HomeIncompleteTasksTab> {
  int? _selectedCourseId;
  IncompleteTaskCategory? _selectedCategory;

  var _loading = false;
  var _hasError = false;
  StudentIncompleteProgressReport? _report;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureCourseSelected();
  }

  void _ensureCourseSelected() {
    final courses = StudentProfileScope.maybeOf(context)?.profile?.courses;
    if (courses == null || courses.isEmpty) return;

    if (_selectedCourseId == null ||
        courses.every((course) => course.id != _selectedCourseId)) {
      _selectedCourseId = courses.first.id;
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final courseId = _selectedCourseId;
    if (courseId == null) return;

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final report = await StudentsApi.fetchIncompleteProgressDetails(courseId);
      if (!mounted) return;

      final visible = visibleIncompleteCategories(report);
      setState(() {
        _report = report;
        _loading = false;
        _selectedCategory = visible.isEmpty
            ? null
            : visible.contains(_selectedCategory)
                ? _selectedCategory
                : visible.first;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _report = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _report = null;
      });
    }
  }

  void _onCourseChanged(int courseId) {
    setState(() {
      _selectedCourseId = courseId;
      _selectedCategory = null;
    });
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final scope = StudentProfileScope.maybeOf(context);
    final courses = scope?.profile?.courses ?? const [];

    if (courses.isEmpty) {
      return Padding(
        padding: AppSpacing.profileTabContentPadding,
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: AppColors.tabInactive, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد دورات',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppColors.tabInactive),
            ),
          ],
        ),
      );
    }

    final selectedCourse = courses.firstWhere(
      (course) => course.id == _selectedCourseId,
      orElse: () => courses.first,
    );

    if (_hasError && _report == null) {
      return Padding(
        padding: AppSpacing.profileTabContentPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.tabInactive, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: AppTypography.bodyLg.copyWith(color: AppColors.tabInactive),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: _loadProgress, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final report = _report ?? const StudentIncompleteProgressReport();
    final counts = incompleteTaskCounts(report);
    final totalTasks = report.totalCount;
    final visibleCategories = visibleIncompleteCategories(report);
    final selectedCategory = _selectedCategory ?? visibleCategories.firstOrNull;
    final tasks = selectedCategory == null
        ? const <IncompleteTask>[]
        : incompleteTasksForCategory(report, selectedCategory);

    return Padding(
      padding: AppSpacing.profileTabContentPadding,
      child: Column(
        children: [
          IncompleteTasksCourseHeader(
            courseLabel: selectedCourse.title,
            taskCount: totalTasks,
            onCourseTap: (trigger) => _pickCourse(
              trigger,
              courses,
              selectedCourse.id,
            ),
          ),
          if (report.isEmpty && !_loading)
            const IncompleteTasksAllComplete()
          else if (report.isEmpty && _loading)
            const SizedBox(height: AppSpacing.xl)
          else ...[
            const SizedBox(height: AppSpacing.xl),
            IncompleteTasksCategoryBar(
              selected: selectedCategory ?? IncompleteTaskCategory.exams,
              counts: counts,
              onSelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            IncompleteTasksContentTransition(
              category: selectedCategory ?? IncompleteTaskCategory.exams,
              child: Column(
                children: [
                  for (var i = 0; i < tasks.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.base),
                    IncompleteTaskItemEnter(
                      child: IncompleteTaskCard(
                        key: ValueKey(
                          '${tasks[i].category.name}-${tasks[i].courseId}-${tasks[i].moduleId}-${tasks[i].itemId}-${tasks[i].quizId ?? tasks[i].classificationQuizId ?? tasks[i].knowledgeQuizId ?? 0}',
                        ),
                        task: tasks[i],
                        onTap: () => context.push(
                          incompleteTaskNavigationPath(tasks[i]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickCourse(
    BuildContext triggerContext,
    List<StudentCourse> courses,
    int currentId,
  ) async {
    final chosen = await showAnchoredSelectMenu<int>(
      triggerContext: triggerContext,
      selected: currentId,
      options: [
        for (final course in courses)
          AnchoredSelectOption(value: course.id, label: course.title),
      ],
    );

    if (chosen != null && chosen != _selectedCourseId) {
      _onCourseChanged(chosen);
    }
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
