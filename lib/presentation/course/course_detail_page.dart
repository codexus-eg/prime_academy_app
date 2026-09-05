import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/auth/auth_session.dart';
import '../../data/courses/courses_api.dart';
import '../../data/courses/lesson_page_cache.dart';
import '../home/widgets/app_nav_scaffold.dart';
import 'models/course_detail_mapper.dart';
import 'models/course_unit.dart';
import 'widgets/course_unit_tile.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  static const String routePath = '/course/:courseId';
  static const String routeName = 'course-detail';

  static String pathFor(String courseId) => '/course/$courseId';

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  int? _expandedUnitIndex;
  var _showStudentProgress = false;

  late Future<CourseDetail> _courseFuture;

  @override
  void initState() {
    super.initState();
    _courseFuture = _bootstrap();
  }

  Future<CourseDetail> _bootstrap() async {
    final user = await AuthSession.load();
    _showStudentProgress = user?.role == 1;
    return _loadCourse();
  }

  Future<CourseDetail> _loadCourse() async {
    final id = int.tryParse(widget.courseId);
    if (id == null) {
      throw ApiException('الدورة غير موجودة');
    }
    final course = await CoursesApi.fetchCourseForUser(id);
    return CourseDetailMapper.fromUserCourse(course);
  }

  Future<void> _refreshProgress() async {
    final expanded = _expandedUnitIndex;
    try {
      final course = await _loadCourse();
      if (!mounted) return;
      setState(() {
        _courseFuture = Future<CourseDetail>.value(course);
        _expandedUnitIndex = expanded;
      });
    } catch (_) {}
  }

  void _retry() {
    setState(() {
      _expandedUnitIndex = null;
      _courseFuture = _loadCourse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      backgroundColor: AppColors.mainBg,
      topBarBackground: AppColors.mainBg,
      body: FutureBuilder<CourseDetail>(
        future: _courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _CourseError(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'تعذّر تحميل تفاصيل الدورة',
              onRetry: _retry,
            );
          }
          final course = snapshot.data!;
          return _buildContent(course);
        },
      ),
    );
  }

  Widget _buildContent(CourseDetail course) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minSheetHeight = _minModulesSheetHeight(constraints.maxHeight);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.courseSectionTop),
                child: _CourseTitleBar(title: course.title),
              ),
              const SizedBox(height: AppSpacing.courseTitleModuleGap),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minSheetHeight),
                child: ClipRRect(
                  borderRadius: AppRadius.borderCoursePageTop,
                  child: ColoredBox(
                    color: AppTheme.courseModulesSheet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.courseModulesHorizontal,
                        vertical: AppSpacing.courseModulesVertical,
                      ),
                      child: _buildModulesList(course),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _minModulesSheetHeight(double viewportHeight) {
    const aboveSheet =
        AppSpacing.courseSectionTop + AppSpacing.courseTitleModuleGap + 72;
    return (viewportHeight - aboveSheet).clamp(320, double.infinity);
  }

  Widget _buildModulesList(CourseDetail course) {
    if (course.units.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.courseModulesVertical,
        ),
        child: Text(
          'لا يوجد محتوى في هذه الدورة',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLg.copyWith(color: AppColors.onDark),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < course.units.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.courseModuleGap),
          CourseUnitTile(
            courseId: widget.courseId,
            unit: course.units[i],
            isExpanded: _expandedUnitIndex == i,
            showProgressRing: course.isEnrolled && _showStudentProgress,
            onLessonClosed: _refreshProgress,
            onTap: () {
              final expanding = _expandedUnitIndex != i;
              setState(() {
                _expandedUnitIndex = _expandedUnitIndex == i ? null : i;
              });
              if (expanding) {
                _prefetchUnit(course.units[i]);
              }
            },
          ),
        ],
      ],
    );
  }

  /// Warm module + first lessons so opening a lesson paints immediately.
  void _prefetchUnit(CourseUnit unit) {
    final courseId = int.tryParse(widget.courseId);
    final moduleId = int.tryParse(unit.id);
    if (courseId == null || moduleId == null) return;

    unawaited(() async {
      try {
        final module = await LessonPageCache.loadModule(
          courseId: courseId,
          moduleId: moduleId,
          fetch: () => CoursesApi.fetchModuleItems(
            courseId: courseId,
            moduleId: moduleId,
          ),
        );
        final ids = module.items
            .map((item) => item.lesson?.id)
            .whereType<int>()
            .take(4);
        LessonPageCache.prefetchLessons(
          ids,
          fetch: CoursesApi.fetchLesson,
        );
      } catch (_) {}
    }());
  }
}

class _CourseError extends StatelessWidget {
  const _CourseError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg,
            ),
            const SizedBox(height: AppSpacing.base),
            TextButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTitleBar extends StatelessWidget {
  const _CourseTitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const inset = AppSpacing.courseTitleScreenInset;

    return Padding(
padding: EdgeInsets.symmetric(horizontal: inset),      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final overlayWidth = barWidth * 0.8;

          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(AppRadius.tailwindXl),
              bottomRight: Radius.circular(AppRadius.tailwindXl),
              topLeft: Radius.circular(AppRadius.tailwindXl),
              bottomLeft: Radius.circular(AppRadius.tailwindXl),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: AppTheme.courseModuleSurface),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: overlayWidth,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.courseTitle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.courseTitleInner),
                  child: SizedBox(
                    width: barWidth,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.headingCourse.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
