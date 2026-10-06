import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/courses/course_material.dart';
import '../../data/courses/courses_api.dart';
import '../home/widgets/app_nav_scaffold.dart';
import 'material_file_download.dart';
import 'material_view_page.dart';
import 'widgets/lesson_action_icons.dart';

class CourseMaterialsPage extends StatefulWidget {
  const CourseMaterialsPage({
    super.key,
    required this.courseId,
    required this.solved,
  });

  final String courseId;
  final bool solved;

  static const String routePath = '/course-materials/:courseId';
  static const String routeName = 'course-materials';

  static String pathFor(String courseId, {required bool solved}) =>
      '/course-materials/$courseId?solved=$solved';

  @override
  State<CourseMaterialsPage> createState() => _CourseMaterialsPageState();
}

class _CourseMaterialsPageState extends State<CourseMaterialsPage> {
  late Future<CourseMaterialsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant CourseMaterialsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId ||
        oldWidget.solved != widget.solved) {
      _future = _load();
    }
  }

  Future<CourseMaterialsResponse> _load() {
    final id = int.tryParse(widget.courseId);
    if (id == null) {
      return Future.error(ApiException('المادة غير موجودة'));
    }
    return CoursesApi.fetchCourseMaterials(courseId: id, solved: widget.solved);
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      backgroundColor: AppColors.mainBg,
      topBarBackground: AppColors.mainBg,
      body: FutureBuilder<CourseMaterialsResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MaterialsError(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'تعذّر تحميل المذكرات',
              onRetry: _retry,
            );
          }
          final data = snapshot.data!;
          return _MaterialsBody(
            courseId: widget.courseId,
            courseName: data.courseName,
            solved: widget.solved,
            files: data.files,
          );
        },
      ),
    );
  }
}

class _MaterialsBody extends StatelessWidget {
  const _MaterialsBody({
    required this.courseId,
    required this.courseName,
    required this.solved,
    required this.files,
  });

  final String courseId;
  final String courseName;
  final bool solved;
  final List<CourseMaterial> files;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minSheetHeight =
            (constraints.maxHeight -
                    AppSpacing.courseSectionTop -
                    AppSpacing.courseTitleModuleGap -
                    72)
                .clamp(320.0, double.infinity);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.courseSectionTop,
                ),
                child: _TitleBar(title: courseName),
              ),
              const SizedBox(height: AppSpacing.courseTitleModuleGap),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minSheetHeight),
                child: ClipRRect(
                  borderRadius: AppRadius.borderCoursePageTop,
                  child: ColoredBox(
                    color: AppColors.mainBg,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.courseModulesHorizontal,
                        vertical: AppSpacing.xl,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 896),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.courseModuleSurface,
                              borderRadius: AppRadius.borderCard,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.base,
                                    vertical: AppSpacing.base,
                                  ),
                                  child: Text(
                                    solved
                                        ? 'المذكره المحلولة'
                                        : 'المذكره الغير محلولة',
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    style: AppTypography.headingDialog.copyWith(
                                      color: AppColors.onDark,
                                      fontWeight: AppFonts.semibold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    0,
                                    AppSpacing.md,
                                    AppSpacing.base,
                                  ),
                                  child: files.isEmpty
                                      ? _EmptyState(solved: solved)
                                      : Column(
                                          children: [
                                            for (
                                              var i = 0;
                                              i < files.length;
                                              i++
                                            ) ...[
                                              if (i > 0)
                                                const SizedBox(
                                                  height: AppSpacing.md,
                                                ),
                                              _MaterialCard(
                                                material: files[i],
                                                courseId: courseId,
                                                solved: solved,
                                              ),
                                            ],
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const inset = AppSpacing.courseTitleScreenInset;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: inset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final overlayWidth = barWidth * 0.8;

          return ClipRRect(
            borderRadius: AppRadius.borderCard,
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
                        fontWeight: AppFonts.semibold,
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

class _MaterialCard extends StatefulWidget {
  const _MaterialCard({
    required this.material,
    required this.courseId,
    required this.solved,
  });

  final CourseMaterial material;
  final String courseId;
  final bool solved;

  @override
  State<_MaterialCard> createState() => _MaterialCardState();
}

class _MaterialCardState extends State<_MaterialCard> {
  var _hovered = false;
  var _navigating = false;
  var _downloading = false;

  String get _filename => widget.material.fileData.filename.isEmpty
      ? 'مذكرة #${widget.material.id}'
      : widget.material.fileData.filename;

  String get _sizeLabel => formatFileSize(widget.material.fileData.size);

  Future<void> _openView() async {
    final hasUrl = widget.material.fileData.url.isNotEmpty;
    if (!hasUrl || _navigating) return;
    setState(() => _navigating = true);
    try {
      await context.push(
        MaterialViewPage.pathFor(
          courseId: widget.courseId,
          materialId: '${widget.material.id}',
          solved: widget.solved,
        ),
        extra: MaterialViewArgs(material: widget.material),
      );
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _download() async {
    final url = widget.material.fileData.url;
    if (url.isEmpty || _downloading) return;
    setState(() => _downloading = true);
    try {
      final result = await downloadMaterialFile(url: url, fileName: _filename);
      if (!mounted) return;
      showMaterialDownloadSuccessSnackBar(context, result);
    } catch (e) {
      if (!mounted) return;
      final message = e is MaterialDownloadException
          ? e.message
          : 'تعذّر تحميل الملف';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.material.fileData.url.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasUrl && !_navigating ? _openView : null,
          borderRadius: AppRadius.borderRankingCard,
          child: Opacity(
            opacity: hasUrl ? 1 : 0.6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: AppColors.mainBg3,
                borderRadius: AppRadius.borderRankingCard,
                border: Border.all(
                  color: _hovered
                      ? AppColors.accentBg30
                      : AppColors.onDark.withValues(alpha: 0.03),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.blue.withValues(alpha: 0.7),
                            AppColors.blueLight.withValues(alpha: 0.7),
                            AppColors.blue.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.borderCard,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accentGradientFrom10,
                                AppColors.blue.withValues(alpha: 0.1),
                              ],
                            ),
                            border: Border.all(color: AppColors.accentBg15),
                          ),
                          alignment: Alignment.center,
                          child: _navigating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentSoft,
                                  ),
                                )
                              : LessonActionIcons.svg(
                                  LessonActionIcons.fileText,
                                  size: 20,
                                  color: AppColors.accentSoft,
                                ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _filename,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onDark,
                                  fontWeight: AppFonts.medium,
                                ),
                              ),
                              if (_sizeLabel.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _sizeLabel,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: AppTypography.size11.copyWith(
                                    color: AppColors.onDark.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Semantics(
                          button: true,
                          label: 'تحميل الملف',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: hasUrl && !_downloading ? _download : null,
                              borderRadius: AppRadius.borderCard,
                              hoverColor: AppColors.accentBg.withValues(
                                alpha: 0.1,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                child: _downloading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : LessonActionIcons.svg(
                                        LessonActionIcons.download,
                                        size: 16,
                                        color: _hovered
                                            ? AppColors.accentSoft
                                            : AppColors.onDark.withValues(
                                                alpha: 0.4,
                                              ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.solved});

  final bool solved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.onDark.withValues(alpha: 0.05),
              borderRadius: AppRadius.borderRankingCard,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.4,
              child: LessonActionIcons.svg(
                LessonActionIcons.fileText,
                size: 24,
                color: AppColors.onDark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            solved ? 'لا توجد مذكرات محلولة' : 'لا توجد مذكرات غير محلولة',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onDark.withValues(alpha: 0.6),
              fontWeight: AppFonts.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialsError extends StatelessWidget {
  const _MaterialsError({required this.message, required this.onRetry});

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
            TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

String formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final decimals = unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
}
