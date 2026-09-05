import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/cdn_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/courses/course_rank.dart';
import '../../../data/courses/courses_api.dart';
import '../models/ranking_student.dart';
import '../ranking/home_refresh_signal.dart';
import '../ranking/ranking_course_selection.dart';
import '../student_profile_scope.dart';
import '../widgets/ranking_empty_state.dart';
import '../widgets/ranking_leaderboard_card.dart';
import '../widgets/ranking_search_field.dart';
import '../widgets/ranking_student_count_header.dart';
import '../widgets/report_filter_dropdown.dart';
import '../../common/anchored_select_menu.dart';

class HomeRankingTab extends StatefulWidget {
  const HomeRankingTab({
    super.key,
    this.routeCourseId,
  });

  /// `course_id` query param — set only when the user picks a course in the
  /// dropdown (same as web RankTable writing course_id after selection).
  /// Point notifications open bare `/home/ranking` so this stays null and
  /// initialization uses `courses[0]` (web buildNotificationLink parity).
  final int? routeCourseId;

  @override
  State<HomeRankingTab> createState() => _HomeRankingTabState();
}

class _HomeRankingTabState extends State<HomeRankingTab> {
  static const _studentsPerPage = 25;

  /// Parent [HomeShell] already applies [AppSpacing.pageContentHorizontal].
  /// Keep a small extra inset without using negative padding (Flutter forbids it).
  static const EdgeInsetsDirectional _tableEdgePadding =
      EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm);

  final _searchController = TextEditingController();
  final _currentStudentKey = GlobalKey();

  int? _selectedCourseId;
  var _currentPage = 1;
  var _searchQuery = '';
  var _sortField = 'rank';
  var _sortAscending = true;
  var _loading = false;
  var _hasError = false;
  var _errorMessage = '';
  var _pendingScrollToCurrent = false;
  var _loadGeneration = 0;
  var _hasAttemptedInitialLoad = false;
  var _awaitingProfileForCourse = false;
  var _homeRefreshGeneration = HomeRefreshSignal.instance.generation;
  List<CourseRankEntry> _rankings = const [];

  String? _lastProfileKey;
  String? _lastCoursesKey;

  int? get _currentStudentId =>
      StudentProfileScope.maybeOf(context)?.profile?.id;

  int? get _courseIdFromRoute => widget.routeCourseId;

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
    if (kDebugMode) {
      debugPrint('[Ranking] Initialization started');
      debugPrint(
        '[Ranking] Existing controller/state detected → fresh mount '
        '(routeCourseId=${widget.routeCourseId})',
      );
    }
    // Notification opens bare /home/ranking (routeCourseId null) → courses[0].
    // Manual dropdown writes course_id into the URI like web RankTable.
    _selectedCourseId = widget.routeCourseId;
    if (widget.routeCourseId != null && widget.routeCourseId! > 0) {
      _loading = true;
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _currentPage = 1;
      });
    });
    HomeRefreshSignal.instance.addListener(_onHomeRefreshRequested);
    _scheduleSync(force: true);
  }

  void _onHomeRefreshRequested() {
    if (!mounted) return;
    final generation = HomeRefreshSignal.instance.generation;
    if (generation == _homeRefreshGeneration) return;
    _homeRefreshGeneration = generation;
    if (_selectedCourseId != null) {
      _loadRankings(showLoadingShell: false);
    } else {
      _scheduleSync(force: true);
    }
  }

  @override
  void didUpdateWidget(covariant HomeRankingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeCourseId != widget.routeCourseId) {
      _scheduleSync(force: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    StudentProfileScope.maybeOf(context);
    _scheduleProfileSync();
    if (_pendingScrollToCurrent && _currentStudentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goToCurrentStudent(scrollIntoView: true);
      });
    }
  }

  @override
  void dispose() {
    HomeRefreshSignal.instance.removeListener(_onHomeRefreshRequested);
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleSync({required bool force}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncCourseFromRouteOrProfile(force: force);
    });
  }

  void _scheduleProfileSync() {
    final profile = StudentProfileScope.maybeOf(context)?.profile;
    final profileKey = profile?.id.toString();
    final courses = profile?.courses ?? const [];
    final coursesKey = courses.map((course) => course.id).join(',');

    final profileBecameAvailable =
        profileKey != null && profileKey != _lastProfileKey;
    final coursesBecameAvailable =
        coursesKey.isNotEmpty && coursesKey != _lastCoursesKey;

    if (!profileBecameAvailable && !coursesBecameAvailable) {
      return;
    }

    if (profileKey != null) {
      _lastProfileKey = profileKey;
    }
    if (coursesKey.isNotEmpty) {
      _lastCoursesKey = coursesKey;
    }

    if (kDebugMode && coursesBecameAvailable) {
      debugPrint('[Ranking] Courses loaded ($coursesKey)');
    }

    final shouldForce = _rankings.isEmpty &&
        (!_hasAttemptedInitialLoad || _awaitingProfileForCourse);
    _scheduleSync(force: shouldForce || profileBecameAvailable);
  }

  void _syncCourseFromRouteOrProfile({
    bool force = false,
  }) {
    final routeCourseId = _courseIdFromRoute;
    final courses = StudentProfileScope.maybeOf(context)?.profile?.courses;
    final enrolledCourseIds = courses?.map((course) => course.id).toList();

    final preferredId = resolveRankingCourseId(
      routeCourseId: routeCourseId,
      selectedCourseId: _selectedCourseId,
      enrolledCourseIds: enrolledCourseIds,
    );

    if (preferredId == null) {
      _awaitingProfileForCourse = routeCourseId == null;
      if (mounted) setState(() {});
      return;
    }

    _awaitingProfileForCourse = false;

    if (!force &&
        preferredId == _selectedCourseId &&
        (_rankings.isNotEmpty || _loading)) {
      return;
    }

    if (preferredId != _selectedCourseId) {
      _selectedCourseId = preferredId;
      _currentPage = 1;
      _searchQuery = '';
      _searchController.clear();
      _rankings = const [];
      _hasError = false;
      _errorMessage = '';
    }

    if (kDebugMode) {
      debugPrint('[Ranking] Selected course ID $preferredId');
    }

    _loadRankings();
  }

  Future<void> _loadRankings({bool showLoadingShell = true}) async {
    final courseId = _selectedCourseId;
    if (courseId == null) return;

    final generation = ++_loadGeneration;
    _hasAttemptedInitialLoad = true;
    _awaitingProfileForCourse = false;

    if (kDebugMode) {
      debugPrint('[Ranking] API request started → /courses/ranks/$courseId');
    }

    if (showLoadingShell || _rankings.isEmpty) {
      setState(() {
        _loading = true;
        _hasError = false;
        _errorMessage = '';
      });
    }

    try {
      final rankings = await CoursesApi.fetchRanksByCourse(courseId);
      if (!mounted || generation != _loadGeneration) return;

      if (kDebugMode) {
        debugPrint(
          '[Ranking] API response received (${rankings.length} entries)',
        );
      }

      setState(() {
        _rankings = rankings;
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('[Ranking] State updated');
        debugPrint('[Ranking] UI rendered');
      }

      _goToCurrentStudent(scrollIntoView: true);
    } on ApiException catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      if (kDebugMode) {
        debugPrint(
          '[HomeRankingTab] fetchRanksByCourse($courseId) failed: ${error.message}',
        );
      }
      setState(() {
        _hasError = true;
        _loading = false;
        _rankings = const [];
        _errorMessage = error.message;
      });
    } catch (error, stackTrace) {
      if (!mounted || generation != _loadGeneration) return;
      if (kDebugMode) {
        debugPrint(
          '[HomeRankingTab] fetchRanksByCourse($courseId) unexpected error: $error\n$stackTrace',
        );
      }
      setState(() {
        _hasError = true;
        _loading = false;
        _rankings = const [];
        _errorMessage = 'حدث خطأ أثناء تحميل البيانات';
      });
    }
  }

  void _goToCurrentStudent({required bool scrollIntoView}) {
    if (_searchQuery.isNotEmpty) return;

    final index = _filteredStudents.indexWhere((s) => s.isCurrentStudent);
    if (index == -1) {
      _pendingScrollToCurrent = scrollIntoView;
      return;
    }
    _pendingScrollToCurrent = false;

    final page = (index / _studentsPerPage).floor() + 1;

    if (_currentPage != page) {
      setState(() => _currentPage = page);
    }

    if (!scrollIntoView) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        final target = _currentStudentKey.currentContext;
        if (target == null) {
          _pendingScrollToCurrent = true;
          return;
        }
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      });
    });
  }

  void _onCourseChanged(int courseId) {
    setState(() {
      _selectedCourseId = courseId;
      _currentPage = 1;
      _searchQuery = '';
      _searchController.clear();
    });
    GoRouter.of(context).go(
      Uri(
        path: '/home/ranking',
        queryParameters: {'course_id': '$courseId'},
      ).toString(),
    );
    _loadRankings();
  }

  @override
  Widget build(BuildContext context) {
    final scope = StudentProfileScope.maybeOf(context);
    final courses = scope?.profile?.courses ?? const [];
    final effectiveCourseId = _selectedCourseId ?? _courseIdFromRoute;

    // Web: RankTable renders only when courses.length > 0. Show a loader
    // instead of a blank panel while profile/courses catch up after an
    // active-session notification navigation.
    if (courses.isEmpty && effectiveCourseId == null) {
      if (scope?.profile == null && scope?.errorMessage == null) {
        return const Padding(
          padding: AppSpacing.profileTabContentPadding,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (_awaitingProfileForCourse || scope?.profile == null) {
        return const Padding(
          padding: AppSpacing.profileTabContentPadding,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return Padding(
        padding: AppSpacing.profileTabContentPadding,
        child: Text(
          'لا يوجد دورات',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLg.copyWith(color: AppColors.tabInactive),
        ),
      );
    }

    if (_awaitingProfileForCourse &&
        !_hasAttemptedInitialLoad &&
        effectiveCourseId == null) {
      return const Padding(
        padding: AppSpacing.profileTabContentPadding,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedCourse = courses.isEmpty
        ? null
        : courses.firstWhere(
            (c) => c.id == effectiveCourseId,
            orElse: () => courses.first,
          );
    final courseLabel = selectedCourse?.title ?? 'جاري التحميل...';

    // Always show Ranking chrome (never a blank void under تصنيفي). While
    // courses/ranks load, keep a non-zero body so platform-view leftovers are
    // obvious if they still cover Flutter content.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: AppSpacing.profileTabContentPadding.copyWith(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RankingStudentCountHeader(
                  isLoading: _loading && _rankings.isEmpty,
                  studentCount: _rankings.length,
                ),
                const SizedBox(height: AppSpacing.profileSectionGap),
                ReportFilterDropdown(
                  label: courseLabel,
                  onTap: courses.isEmpty
                      ? null
                      : (trigger) async {
                          final chosen = await showAnchoredSelectMenu<int>(
                            triggerContext: trigger,
                            selected: selectedCourse!.id,
                            options: [
                              for (final course in courses)
                                AnchoredSelectOption(
                                  value: course.id,
                                  label: course.title,
                                ),
                            ],
                          );
                          if (chosen != null && chosen != _selectedCourseId) {
                            _onCourseChanged(chosen);
                          }
                        },
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
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildRankingTable(Widget child) {
    return Padding(
      padding: _tableEdgePadding,
      child: child,
    );
  }

  Widget _buildBody(BuildContext context) {
    if ((_loading && _rankings.isEmpty) ||
        (!_hasAttemptedInitialLoad && !_hasError)) {
      return _buildRankingTable(const _RankingLoadingTable());
    }

    if (_hasError) {
      return Padding(
        padding: AppSpacing.profileTabContentPadding.copyWith(top: 0),
        child: Column(
          children: [
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'حدث خطأ أثناء تحميل البيانات',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.base),
            TextButton(
              onPressed: _loadRankings,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final emptyMessage = _searchQuery.isEmpty
        ? 'لا يوجد طلاب'
        : 'لم يتم العثور على طلاب بهذا الاسم';

    return _buildRankingTable(
      RankingLeaderboardCard(
        students: _pageStudents,
        currentPage: _currentPage.clamp(1, _effectiveTotalPages),
        totalPages: _effectiveTotalPages,
        sortField: _sortField,
        sortAscending: _sortAscending,
        currentStudentKey: _currentStudentKey,
        onSort: (field) {
          setState(() {
            if (_sortField == field) {
              _sortAscending = !_sortAscending;
            } else {
              _sortField = field;
              _sortAscending = true;
            }
          });
          _goToCurrentStudent(scrollIntoView: true);
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
    );
  }
}

/// Skeleton rows while rankings load (web RankTable skeleton parity).
class _RankingLoadingTable extends StatelessWidget {
  const _RankingLoadingTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.mainBg3,
        borderRadius: BorderRadius.circular(AppSpacing.base),
        border: Border.all(color: AppColors.overlayWhite3),
      ),
      child: Column(
        children: [
          for (var i = 0; i < 8; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.overlayWhite4,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
