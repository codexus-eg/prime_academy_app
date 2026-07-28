import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/quizzes/student_quiz_attempt_models.dart';
import '../../../data/quizzes/unit_quiz_api.dart';
import '../../reports/student_quiz_review_page.dart';
import '../models/report_attempt.dart';
import '../student_profile_scope.dart';
import '../widgets/report_filter_dropdown.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/reports_empty_state.dart';
import '../widgets/reports_results_count.dart';
import '../widgets/reports_section_header.dart';

class HomeReportsTab extends StatefulWidget {
  const HomeReportsTab({super.key});

  @override
  State<HomeReportsTab> createState() => _HomeReportsTabState();
}

class _HomeReportsTabState extends State<HomeReportsTab> {
  static const _allModules = 'جميع الوحدات';

  int? _selectedCourseId;
  var _selectedModule = _allModules;

  var _loading = false;
  var _hasError = false;
  List<StudentQuizAttempt> _attempts = const [];

  List<String> get _moduleNames =>
      _attempts.map((a) => a.moduleName).toSet().toList();

  List<ReportAttempt> get _filteredAttempts {
    final mapped = _attempts
        .map(
          (a) => ReportAttempt(
            quizId: a.quizId,
            moduleName: a.moduleName,
            quizName: a.quizName?.trim() ?? '',
            grade: a.gradePercent,
            attemptId: a.attemptId,
          ),
        )
        .toList();

    if (_selectedModule == _allModules) return mapped;
    return mapped.where((a) => a.moduleName == _selectedModule).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureCourseSelected();
  }

  void _ensureCourseSelected() {
    final courses = StudentProfileScope.maybeOf(context)?.profile?.courses;
    if (courses == null || courses.isEmpty) return;

    if (_selectedCourseId == null ||
        courses.every((c) => c.id != _selectedCourseId)) {
      _selectedCourseId = courses.first.id;
      _loadAttempts();
    }
  }

  Future<void> _loadAttempts() async {
    final courseId = _selectedCourseId;
    if (courseId == null) return;

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final attempts = await UnitQuizApi.fetchStudentAttempts(courseId);
      if (!mounted) return;
      setState(() {
        _attempts = attempts;
        _loading = false;
        _selectedModule = _allModules;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
        _attempts = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
        _attempts = const [];
      });
    }
  }

  void _onCourseChanged(int courseId) {
    setState(() {
      _selectedCourseId = courseId;
      _selectedModule = _allModules;
    });
    _loadAttempts();
  }

  @override
  Widget build(BuildContext context) {
    final scope = StudentProfileScope.maybeOf(context);
    final courses = scope?.profile?.courses ?? const [];
    final attempts = _filteredAttempts;
    final width = MediaQuery.sizeOf(context).width;
    final courseFilterWidth = width >= 640
        ? AppSpacing.profileFilterCourseWidth
        : double.infinity;
    final moduleFilterWidth = width >= 640
        ? AppSpacing.profileFilterModuleWidth
        : double.infinity;

    if (scope == null || scope.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue));
    }

    if (courses.isEmpty) {
      return Padding(
        padding: AppSpacing.profileTabContentPadding,
        child: Text(
          'لا يوجد دورات',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLg.copyWith(color: AppColors.tabInactive),
        ),
      );
    }

    final selectedCourse = courses.firstWhere(
      (c) => c.id == _selectedCourseId,
      orElse: () => courses.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.profileTabContentPadding.copyWith(bottom: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_loading && !_hasError && attempts.isNotEmpty) ...[
                ReportsSectionHeader(
                  reportCount: attempts.length,
                ),
                const SizedBox(height: AppSpacing.profileReportsSectionGap),
              ],
              Wrap(
                spacing: AppSpacing.profileFilterGap,
                runSpacing: AppSpacing.profileFilterGap,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ReportFilterDropdown(
                    label: selectedCourse.title,
                    width: courseFilterWidth,
                    onTap: () => _pickOption(
                      options: courses.map((c) => c.title).toList(),
                      current: selectedCourse.title,
                      onSelected: (title) {
                        final course =
                            courses.firstWhere((c) => c.title == title);
                        _onCourseChanged(course.id);
                      },
                    ),
                  ),
                  if (!_loading && !_hasError && _moduleNames.isNotEmpty)
                    ReportFilterDropdown(
                      label: _selectedModule,
                      width: moduleFilterWidth,
                      showFilterIcon: true,
                      onTap: () => _pickOption(
                        options: [_allModules, ..._moduleNames],
                        current: _selectedModule,
                        onSelected: (v) => setState(() => _selectedModule = v),
                      ),
                    ),
                  if (!_loading && !_hasError)
                    ReportsResultsCount(count: attempts.length),
                ],
              ),
              const SizedBox(height: AppSpacing.profileReportsSectionGap),
            ],
          ),
        ),
        Expanded(child: _buildBody(context, attempts)),
      ],
    );
  }

  Widget _buildBody(BuildContext context, List<ReportAttempt> attempts) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.blue,
          ),
        ),
      );
    }

    if (_hasError) {
      return ListView(
        padding: AppSpacing.profileTabContentPadding.copyWith(top: 0),
        children: [
          const ReportsErrorState(),
          TextButton(onPressed: _loadAttempts, child: const Text('إعادة المحاولة')),
        ],
      );
    }

    if (attempts.isEmpty) {
      return ListView(
        padding: AppSpacing.profileTabContentPadding.copyWith(top: 0),
        children: [
          ReportsEmptyState(
            title: _selectedModule == _allModules
                ? 'لا توجد تقارير حتى الآن'
                : 'لا توجد تقارير لهذه الوحدة',
            subtitle: 'قم بإجراء بعض الاختبارات لتظهر تقاريرك هنا',
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1024
            ? 3
            : constraints.maxWidth >= 768
                ? 2
                : 1;

        if (crossAxisCount == 1) {
          return ListView.separated(
            padding: AppSpacing.profileTabContentPadding.copyWith(top: 0),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              return ReportSummaryCard(
                attempt: attempt,
                isFirst: index == 0,
                onStudentReportTap: () {
                  context.push(
                    StudentQuizReviewPage.pathFor(
                      quizId: attempt.quizId,
                      attemptId: attempt.attemptId,
                    ),
                  );
                },
              );
            },
          );
        }

        return GridView.builder(
          padding: AppSpacing.profileTabContentPadding.copyWith(top: 0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisExtent: 380,
          ),
          itemCount: attempts.length,
          itemBuilder: (context, index) {
            final attempt = attempts[index];
            return ReportSummaryCard(
              attempt: attempt,
              isFirst: index == 0,
              onStudentReportTap: () {
                context.push(
                  StudentQuizReviewPage.pathFor(
                    quizId: attempt.quizId,
                    attemptId: attempt.attemptId,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickOption({
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.mainBg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.answerButton),
        ),
      ),
      builder: (sheetContext) {
        final viewPadding = MediaQuery.viewPaddingOf(sheetContext);
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.55;
        const rowHeight = 56.0;
        final contentHeight = options.length * rowHeight + viewPadding.bottom;
        final sheetHeight = contentHeight.clamp(0.0, maxHeight);

        return SafeArea(
          top: false,
          child: SizedBox(
            height: sheetHeight,
            child: ListView.separated(
              padding: EdgeInsets.only(bottom: viewPadding.bottom),
              itemCount: options.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.overlayWhite6,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == current;
                return ListTile(
                  title: Text(
                    option,
                    textAlign: TextAlign.start,
                    style: AppTypography.filterLabel.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.onDark)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, option),
                );
              },
            ),
          ),
        );
      },
    );

    if (chosen != null) {
      onSelected(chosen);
    }
  }
}
