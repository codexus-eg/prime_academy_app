import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/courses/module_material.dart';

class LessonHandoutsPanel extends StatelessWidget {
  const LessonHandoutsPanel({
    super.key,
    required this.materials,
    required this.isEnrolled,
    this.onClose,
  });

  final List<ModuleMaterial> materials;
  final bool isEnrolled;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.coursePageBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GradientHeader(onClose: onClose),
          Expanded(
            child: materials.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد ملازم متاحة',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    itemCount: materials.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final file = materials[index];
                      final hasAccess =
                          isEnrolled || file.accessWithoutEnrollment;
                      return _HandoutTile(
                        material: file,
                        hasAccess: hasAccess,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HandoutTile extends StatelessWidget {
  const _HandoutTile({required this.material, required this.hasAccess});

  final ModuleMaterial material;
  final bool hasAccess;

  Future<void> _open(BuildContext context) async {
    if (!hasAccess || material.url.isEmpty) return;
    final uri = Uri.tryParse(material.url);
    if (uri == null) return;
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الملف')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = material.createdAt;
    final dateLabel = created != null
        ? '${created.year}/${created.month.toString().padLeft(2, '0')}'
            '/${created.day.toString().padLeft(2, '0')}'
        : null;

    return Opacity(
      opacity: hasAccess ? 1 : 0.5,
      child: Material(
        color: AppColors.mainBg3,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: hasAccess ? () => _open(context) : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.transparent, width: 2),
            ),
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Icon(
                  hasAccess
                      ? Icons.description_outlined
                      : Icons.lock_outline_rounded,
                  color: AppColors.blue,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onDark,
                          fontWeight: AppFonts.medium,
                        ),
                      ),
                      if (dateLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: AppTypography.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasAccess) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.download_rounded,
                    color: AppColors.blue,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFF12161F), Color(0xFF091C40)],
              ),
            ),
            child: SizedBox.expand(),
          ),
          Center(
            child: Text(
              'الملازم الالكترونية',
              style: AppTypography.size24.copyWith(
                color: AppColors.onDark,
                fontWeight: AppFonts.semibold,
              ),
            ),
          ),
          if (onClose != null)
            PositionedDirectional(
              top: AppSpacing.sm,
              start: AppSpacing.sm,
              child: IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                tooltip: 'إغلاق',
              ),
            ),
        ],
      ),
    );
  }
}
