import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/courses/course_material.dart';
import '../../data/courses/courses_api.dart';
import '../home/widgets/app_nav_scaffold.dart';
import 'material_file_download.dart';
import 'widgets/lesson_action_icons.dart';

class MaterialViewArgs {
  const MaterialViewArgs({this.material});

  final CourseMaterial? material;
}

/// Web `MaterialViewPage.tsx` — in-app PDF viewer with page/zoom/download.
class MaterialViewPage extends StatefulWidget {
  const MaterialViewPage({
    super.key,
    required this.courseId,
    required this.materialId,
    required this.solved,
    this.initialMaterial,
  });

  final String courseId;
  final String materialId;
  final bool solved;
  final CourseMaterial? initialMaterial;

  static const String routePath = '/course-materials/:courseId/:materialId';
  static const String routeName = 'course-material-view';

  static String pathFor({
    required String courseId,
    required String materialId,
    required bool solved,
  }) =>
      '/course-materials/$courseId/$materialId?solved=$solved';

  @override
  State<MaterialViewPage> createState() => _MaterialViewPageState();
}

class _MaterialViewPageState extends State<MaterialViewPage> {
  static const _minScale = 0.6;
  static const _maxScale = 2.5;
  static const _scaleStep = 0.2;
  static const _initialScale = 1.2;

  final _controller = PdfViewerController();

  CourseMaterial? _material;
  var _loading = true;
  String? _error;
  var _pageNumber = 1;
  var _pageCount = 0;
  var _scale = _initialScale;
  var _downloading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onViewerChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.removeListener(_onViewerChanged);
    super.dispose();
  }

  void _onViewerChanged() {
    if (!mounted || !_controller.isReady) return;
    final page = _controller.pageNumber ?? _pageNumber;
    final count = _controller.pageCount;
    final zoom = _controller.currentZoom;
    if (page != _pageNumber || count != _pageCount || zoom != _scale) {
      setState(() {
        _pageNumber = page;
        _pageCount = count;
        _scale = zoom;
      });
    }
  }

  Future<void> _bootstrap() async {
    final seeded = widget.initialMaterial;
    if (seeded != null && seeded.fileData.url.isNotEmpty) {
      setState(() {
        _material = seeded;
        _loading = false;
      });
      return;
    }

    final courseId = int.tryParse(widget.courseId);
    if (courseId == null) {
      setState(() {
        _loading = false;
        _error = 'المادة غير موجودة';
      });
      return;
    }

    try {
      final data = await CoursesApi.fetchCourseMaterials(
        courseId: courseId,
        solved: widget.solved,
      );
      CourseMaterial? match;
      for (final m in data.files) {
        if ('${m.id}' == widget.materialId) {
          match = m;
          break;
        }
      }
      if (!mounted) return;
      if (match == null || match.fileData.url.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'لم يتم العثور على الملف';
        });
        return;
      }
      setState(() {
        _material = match;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'تعذر تحميل الملف';
      });
    }
  }

  String get _filename {
    final material = _material;
    if (material == null) return 'مذكرة #${widget.materialId}';
    if (material.fileData.filename.isEmpty) {
      return 'مذكرة #${material.id}';
    }
    return material.fileData.filename;
  }

  Future<void> _goPrev() async {
    if (!_controller.isReady || _pageNumber <= 1) return;
    await _controller.goToPage(pageNumber: _pageNumber - 1);
  }

  Future<void> _goNext() async {
    if (!_controller.isReady || _pageNumber >= _pageCount) return;
    await _controller.goToPage(pageNumber: _pageNumber + 1);
  }

  Future<void> _zoomBy(double delta) async {
    if (!_controller.isReady) return;
    final next = (_scale + delta).clamp(_minScale, _maxScale);
    await _controller.setZoom(Offset.zero, next);
  }

  Future<void> _download() async {
    final url = _material?.fileData.url;
    if (url == null || url.isEmpty || _downloading) return;
    setState(() => _downloading = true);
    try {
      final result = await downloadMaterialFile(
        url: url,
        fileName: _filename,
      );
      if (!mounted) return;
      showMaterialDownloadSuccessSnackBar(context, result);
    } catch (e) {
      if (!mounted) return;
      final message = e is MaterialDownloadException
          ? e.message
          : 'تعذّر تحميل الملف';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      backgroundColor: AppColors.mainBg,
      topBarBackground: AppColors.mainBg,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _material == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'لم يتم العثور على الملف',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onDark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'الرجوع',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.accentIconMuted300,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fileUrl = _material!.fileData.url;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxxl),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.secondaryBg.withValues(alpha: 0.8),
                borderRadius: AppRadius.borderCard,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderBar(
                      filename: _filename,
                      onBack: () => context.pop(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ControlsBar(
                      pageNumber: _pageNumber,
                      pageCount: _pageCount,
                      scale: _scale,
                      downloading: _downloading,
                      onPrev: _goPrev,
                      onNext: _goNext,
                      onZoomOut: () => _zoomBy(-_scaleStep),
                      onZoomIn: () => _zoomBy(_scaleStep),
                      onDownload: _download,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.borderShadcnLg,
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: PdfViewer.uri(
                            Uri.parse(fileUrl),
                            controller: _controller,
                            params: PdfViewerParams(
                              backgroundColor: Colors.transparent,
                              minScale: _minScale,
                              maxScale: _maxScale,
                              calculateInitialZoom: (
                                document,
                                controller,
                                fitZoom,
                                coverZoom,
                              ) {
                                return _initialScale.clamp(
                                  _minScale,
                                  _maxScale,
                                );
                              },
                              errorBannerBuilder: (
                                context,
                                error,
                                documentRef,
                                controller,
                              ) {
                                return Center(
                                  child: Text(
                                    'تعذر تحميل الملف',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                );
                              },
                              loadingBannerBuilder: (
                                context,
                                bytesDownloaded,
                                totalBytes,
                              ) {
                                return Center(
                                  child: Text(
                                    'جاري تحميل الملف...',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onDark
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.filename, required this.onBack});

  final String filename;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onDark.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: AppColors.onDark.withValues(alpha: 0.6),
          ),
          label: Text(
            'رجوع',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onDark.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            filename,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onDark,
              fontWeight: AppFonts.medium,
            ),
          ),
        ),
        const SizedBox(width: 64),
      ],
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.pageNumber,
    required this.pageCount,
    required this.scale,
    required this.downloading,
    required this.onPrev,
    required this.onNext,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onDownload,
  });

  final int pageNumber;
  final int pageCount;
  final double scale;
  final bool downloading;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final pageLabel =
        pageCount > 0 ? '$pageNumber / $pageCount' : '$pageNumber / …';
    final zoomLabel = '${(scale * 100).round()}%';

    // Match web under RTL: download group on the LEFT, page nav on the RIGHT.
    // Inner groups stay LTR so "1 / 4" and chevrons don't reverse.
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlIconButton(
                icon: Icons.chevron_right_rounded,
                onPressed: pageNumber <= 1 ? null : onPrev,
              ),
              SizedBox(
                width: 70,
                child: Text(
                  pageLabel,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onDark.withValues(alpha: 0.7),
                  ),
                ),
              ),
              _ControlIconButton(
                icon: Icons.chevron_left_rounded,
                onPressed:
                    pageCount > 0 && pageNumber >= pageCount ? null : onNext,
              ),
            ],
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ControlIconButton(
                onPressed: downloading ? null : onDownload,
                backgroundColor: AppColors.blue.withValues(alpha: 0.15),
                hoverColor: AppColors.blue.withValues(alpha: 0.25),
                child: downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : LessonActionIcons.svg(
                        LessonActionIcons.download,
                        size: 16,
                        color: AppColors.accentIconMuted300,
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ControlIconButton(
                icon: Icons.remove_rounded,
                onPressed: onZoomOut,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  zoomLabel,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTypography.size11.copyWith(
                    color: AppColors.onDark.withValues(alpha: 0.5),
                  ),
                ),
              ),
              _ControlIconButton(
                icon: Icons.add_rounded,
                onPressed: onZoomIn,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    this.icon,
    this.child,
    this.onPressed,
    this.backgroundColor,
    this.hoverColor,
  });

  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? hoverColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: backgroundColor ?? AppColors.onDark.withValues(alpha: 0.05),
      borderRadius: AppRadius.borderShadcnLg,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.borderShadcnLg,
        hoverColor: hoverColor ?? AppColors.onDark.withValues(alpha: 0.1),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: child ??
                  Icon(
                    icon,
                    size: 16,
                    color: AppColors.onDark,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
