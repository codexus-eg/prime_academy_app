import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/students/student_incomplete_progress.dart';
import '../../../data/students/student_profile.dart';
import '../../../data/students/students_api.dart';
import '../home_page_scroll.dart';
import '../models/incomplete_task.dart';
import '../models/incomplete_task_mapper.dart';
import '../student_profile_scope.dart';
import '../widgets/incomplete_task_card.dart';
import '../widgets/incomplete_tasks_all_complete.dart';
import '../widgets/incomplete_tasks_category_bar.dart';
import '../widgets/incomplete_tasks_course_header.dart';

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

    if (scope == null || scope.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

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

    if (_loading && _report == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

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

    return ListView(
      shrinkWrap: true,
      physics: HomePageScroll.scrollPhysics,
      padding: AppSpacing.profileTabContentPadding,
      children: [
        IncompleteTasksCourseHeader(
          courseLabel: selectedCourse.title,
          taskCount: totalTasks,
          onCourseTap: () => _pickCourse(courses, selectedCourse.id),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            ),
          )
        else if (report.isEmpty)
          const IncompleteTasksAllComplete()
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
          ...tasks.expand((task) sync* {
            yield IncompleteTaskCard(
              key: ValueKey(
                '${task.category.name}-${task.courseId}-${task.moduleId}-${task.itemId}-${task.quizId ?? task.classificationQuizId ?? task.knowledgeQuizId ?? 0}',
              ),
              task: task,
              onTap: () => context.push(incompleteTaskNavigationPath(task)),
            );
            yield const SizedBox(height: AppSpacing.base);
          }),
        ],
      ],
    );
  }

  Future<void> _pickCourse(List<StudentCourse> courses, int currentId) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.mainBg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.answerButton),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final course in courses)
                ListTile(
                  title: Text(
                    course.title,
                    style: AppTypography.bodyLg,
                  ),
                  trailing: course.id == currentId
                      ? const Icon(Icons.check, color: AppColors.onDark)
                      : null,
                  onTap: () => Navigator.pop(context, course.id),
                ),
            ],
          ),
        );
      },
    );

    if (chosen != null && chosen != _selectedCourseId) {
      _onCourseChanged(chosen);
    }
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
