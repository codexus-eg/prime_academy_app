import 'package:flutter/material.dart';

import '../../../core/config/cdn_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/courses/course_rank.dart';
import '../../../data/courses/courses_api.dart';
import '../../../data/students/student_profile.dart';
import '../models/ranking_student.dart';
import '../student_profile_scope.dart';
import '../widgets/ranking_empty_state.dart';
import '../widgets/ranking_leaderboard_card.dart';
import '../widgets/ranking_search_field.dart';
import '../widgets/ranking_student_count_header.dart';
import '../widgets/report_filter_dropdown.dart';

class HomeRankingTab extends StatefulWidget {
  const HomeRankingTab({super.key});

  @override
  State<HomeRankingTab> createState() => _HomeRankingTabState();
}

class _HomeRankingTabState extends State<HomeRankingTab> {
  static const _studentsPerPage = 25;

  final _searchController = TextEditingController();

  int? _selectedCourseId;
  var _currentPage = 1;
  var _searchQuery = '';
  var _sortField = 'rank';
  var _sortAscending = true;
  var _loading = false;
  var _hasError = false;
  List<CourseRankEntry> _rankings = const [];

  int? get _currentStudentId =>
      StudentProfileScope.maybeOf(context)?.profile?.id;

  List<RankingStudent> get _allStudents {
    final currentId = _currentStudentId;
    return _rankings
        .map(
          (entry) => RankingStudent(
            rank: entry.rank,
            name: entry.fullName,
            points: entry.points,
            avatarUrl: CdnConfig.mediaUrl(entry.imageUrl),
            isCurrentStudent: currentId != null && entry.id == currentId,
          ),
        )
        .toList();
  }

  List<RankingStudent> get _filteredStudents {
    var list = _searchQuery.isEmpty
        ? _allStudents
        : _allStudents
            .where((s) => s.name.toLowerCase().contains(_searchQuery))
            .toList();

    list = [...list]..sort((a, b) {
        var cmp = 0;
        if (_sortField == 'rank') {
          cmp = a.rank.compareTo(b.rank);
        } else {
          cmp = a.name.compareTo(b.name);
        }
        return _sortAscending ? cmp : -cmp;
      });
    return list;
  }

  List<RankingStudent> get _pageStudents {
    final list = _filteredStudents;
    final start = (_currentPage - 1) * _studentsPerPage;
    if (start >= list.length) return [];
    final end = (start + _studentsPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _effectiveTotalPages {
    final count = _filteredStudents.length;
    if (count == 0) return 1;
    return (count / _studentsPerPage).ceil();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _currentPage = 1;
      });
    });
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
      _loadRankings();
    }
  }

  Future<void> _loadRankings() async {
    final courseId = _selectedCourseId;
    if (courseId == null) return;

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final rankings = await CoursesApi.fetchRanksByCourse(courseId);
      if (!mounted) return;

      var page = 1;
      final studentId = _currentStudentId;
      if (studentId != null && _searchQuery.isEmpty) {
        final index = rankings.indexWhere((r) => r.id == studentId);
        if (index != -1) {
          page = (index / _studentsPerPage).floor() + 1;
        }
      }

      setState(() {
        _rankings = rankings;
        _loading = false;
        _currentPage = page;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
        _rankings = const [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loading = false;
        _rankings = const [];
      });
    }
  }

  void _onCourseChanged(int courseId) {
    setState(() {
      _selectedCourseId = courseId;
      _currentPage = 1;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadRankings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = StudentProfileScope.maybeOf(context);
    final courses = scope?.profile?.courses ?? const [];

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
              RankingStudentCountHeader(
                isLoading: _loading,
                studentCount: _rankings.length,
              ),
              const SizedBox(height: AppSpacing.profileSectionGap),
              ReportFilterDropdown(
                label: selectedCourse.title,
                onTap: () => _pickCourse(courses, selectedCourse),
              ),
              const SizedBox(height: AppSpacing.profileSectionGap),
              RankingSearchField(controller: _searchController),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.profileSectionGap),
                Text(
                  _filteredStudents.isEmpty
                      ? 'لم يتم العثور على نتائج'
                      : 'تم العثور على ${_filteredStudents.length} طالب',
                  style: AppTypography.bodyMd.copyWith(
                    color: _filteredStudents.isEmpty
                        ? AppColors.error
                        : AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.profileSectionGap),
            ],
          ),
        ),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

    if (_hasError) {
      return ListView(
        padding: AppSpacing.profileTabContentPadding.copyWith(top: 0),
        children: [
          Text(
            'حدث خطأ أثناء تحميل البيانات',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.base),
          TextButton(
            onPressed: _loadRankings,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      );
    }

    final emptyMessage = _searchQuery.isEmpty
        ? 'لا يوجد طلاب'
        : 'لم يتم العثور على طلاب بهذا الاسم';

    return ListView(
      padding: AppSpacing.profileTabContentPadding.copyWith(top: 0),
      children: [
        RankingLeaderboardCard(
          students: _pageStudents,
          currentPage: _currentPage.clamp(1, _effectiveTotalPages),
          totalPages: _effectiveTotalPages,
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSort: (field) {
            setState(() {
              if (_sortField == field) {
                _sortAscending = !_sortAscending;
              } else {
                _sortField = field;
                _sortAscending = true;
              }
            });
          },
          onPrevious: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
          onNext: _currentPage < _effectiveTotalPages
              ? () => setState(() => _currentPage++)
              : null,
          emptyState: _filteredStudents.isEmpty
              ? RankingEmptyState(
                  message: emptyMessage,
                  onClearSearch: _searchQuery.isEmpty
                      ? null
                      : () => _searchController.clear(),
                )
              : null,
        ),
      ],
    );
  }

  Future<void> _pickCourse(
    List<StudentCourse> courses,
    StudentCourse current,
  ) async {
    final options = courses.map((c) => c.title).toList();
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
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.overlayWhite6,
              ),
              itemBuilder: (context, index) {
                final title = options[index];
                final isSelected = title == current.title;
                return ListTile(
                  title: Text(
                    title,
                    style: AppTypography.filterLabel.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.onDark)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, title),
                );
              },
            ),
          ),
        );
      },
    );

    if (chosen == null) return;
    final course = courses.firstWhere((c) => c.title == chosen);
    if (course.id != _selectedCourseId) {
      _onCourseChanged(course.id);
    }
  }
}
