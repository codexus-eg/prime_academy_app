import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/buttons/custom_button.dart';
import '../../data/courses/courses_api.dart';
import '../../data/courses/module_material.dart';

class ElectronicHandoutsPage extends StatefulWidget {
  const ElectronicHandoutsPage({
    super.key,
    required this.courseId,
    required this.unitId,
    required this.lessonId,
    this.isEnrolled = false,
  });

  final String courseId;
  final String unitId;
  final String lessonId;
  final bool isEnrolled;

  static const String routePath =
      '/course/:courseId/units/:unitId/lessons/:lessonId/handouts';
  static const String routeName = 'electronic-handouts';

  static String pathFor({
    required String courseId,
    required String unitId,
    required String lessonId,
  }) =>
      '/course/$courseId/units/$unitId/lessons/$lessonId/handouts';

  @override
  State<ElectronicHandoutsPage> createState() => _ElectronicHandoutsPageState();
}

class _ElectronicHandoutsPageState extends State<ElectronicHandoutsPage> {
  late Future<List<ModuleMaterial>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ModuleMaterial>> _load() {
    final moduleId = int.tryParse(widget.unitId);
    if (moduleId == null) {
      return Future.error(ApiException('تعذّر تحميل الملازم'));
    }
    return CoursesApi.fetchModuleMaterials(moduleId);
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scrim80,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.pageContentHorizontal,
            vertical: AppSpacing.base,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.borderCard,
            child: ColoredBox(
              color: AppTheme.profileInner,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HandoutsHeader(onClose: () => context.pop()),
                  Expanded(
                    child: FutureBuilder<List<ModuleMaterial>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return _HandoutsMessage(
                            message: snapshot.error is ApiException
                                ? (snapshot.error as ApiException).message
                                : 'تعذّر تحميل الملازم',
                            onRetry: _retry,
                          );
                        }
                        final files = snapshot.data ?? const [];
                        if (files.isEmpty) {
                          return const _HandoutsMessage(
                            message: 'لا توجد ملازم لهذه الوحدة',
                          );
                        }
                        return _MaterialsList(
                          files: files,
                          isEnrolled: widget.isEnrolled,
                        );
                      },
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

class _HandoutsHeader extends StatelessWidget {
  const _HandoutsHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1.1, color: AppTheme.homeHeaderBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        child: Row(
          children: [
            CustomButton.icon(
              onPressed: onClose,
              icon: Icons.close,
              height: 40,
              width: 40,
              borderRadius: AppRadius.borderMd,
              foregroundColor: AppColors.onDark.withValues(alpha: 0.95),
              variant: CustomButtonVariant.text,
              semanticLabel: 'إغلاق',
            ),
            Expanded(
              child: Text(
                'الملازم الإلكترونية',
                textAlign: TextAlign.center,
                style: AppTypography.size20.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.bold,
                  height: 1.40,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _MaterialsList extends StatelessWidget {
  const _MaterialsList({required this.files, required this.isEnrolled});

  final List<ModuleMaterial> files;
  final bool isEnrolled;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: files.length,
      separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.base),
      itemBuilder: (context, index) {
        final file = files[index];
        final hasAccess = isEnrolled || file.accessWithoutEnrollment;
        return _MaterialTile(file: file, hasAccess: hasAccess);
      },
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.file, required this.hasAccess});

  final ModuleMaterial file;
  final bool hasAccess;

  Future<void> _open() async {
    if (!hasAccess || file.url.isEmpty) return;
    await launchUrl(Uri.parse(file.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppTheme.courseModuleSurface,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        border: Border.all(
          color: hasAccess ? Colors.transparent : Colors.transparent,
          width: 2,
        ),
      ),
      child: Opacity(
        opacity: hasAccess ? 1 : 0.5,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              hasAccess ? Icons.description_outlined : Icons.lock_outline,
              color: AppColors.blue,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                file.filename,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.medium,
                ),
              ),
            ),
            if (hasAccess) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.download_rounded, color: AppColors.blue, size: 20),
            ],
          ],
        ),
      ),
    );

    if (!hasAccess) return tile;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        child: tile,
      ),
    );
  }
}

class _HandoutsMessage extends StatelessWidget {
  const _HandoutsMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppTheme.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.base),
              TextButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
