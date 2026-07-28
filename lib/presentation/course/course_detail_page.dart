import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/courses/courses_api.dart';
import '../home/widgets/home_top_bar.dart';
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

  late Future<CourseDetail> _courseFuture;

  @override
  void initState() {
    super.initState();
    _courseFuture = _loadCourse();
  }

  Future<CourseDetail> _loadCourse() async {
    final id = int.tryParse(widget.courseId);
    if (id == null) {
      throw ApiException('الدورة غير موجودة');
    }
    final course = await CoursesApi.fetchCourseForUser(id);
    return CourseDetailMapper.fromUserCourse(course);
  }

  void _retry() {
    setState(() {
      _expandedUnitIndex = null;
      _courseFuture = _loadCourse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.mainBg,
                border: Border(
                  bottom: BorderSide(
                    width: AppSpacing.hairline,
                    color: AppColors.headerBorder,
                  ),
                ),
              ),
              child: const HomeTopBar(),
            ),
            Expanded(
              child: FutureBuilder<CourseDetail>(
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
            ),
          ],
        ),
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
            onTap: () {
              setState(() {
                _expandedUnitIndex = _expandedUnitIndex == i ? null : i;
              });
            },
          ),
        ],
      ],
    );
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
