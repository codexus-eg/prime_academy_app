import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/courses/module_material.dart';
import 'lesson_aside_title_header.dart';

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
    return LessonAsideShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonAsideTitleHeader(
            title: 'الملازم الالكترونية',
            onClose: onClose,
          ),
          const SizedBox(height: AppSpacing.lessonAsideInnerGap),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.base),
              itemCount: materials.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.base),
              itemBuilder: (context, index) {
                final file = materials[index];
                final hasAccess = isEnrolled || file.accessWithoutEnrollment;
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

class _HandoutTile extends StatefulWidget {
  const _HandoutTile({required this.material, required this.hasAccess});

  final ModuleMaterial material;
  final bool hasAccess;

  @override
  State<_HandoutTile> createState() => _HandoutTileState();
}

class _HandoutTileState extends State<_HandoutTile> {
  var _hovered = false;

  Future<void> _open() async {
    if (!widget.hasAccess || widget.material.url.isEmpty) return;
    final uri = Uri.tryParse(widget.material.url);
    if (uri == null) return;
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الملف')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = widget.material.createdAt;
    final dateLabel = created == null
        ? null
        : DateFormat.yMd(Localizations.localeOf(context).toString())
            .format(created.toLocal());
    final hasAccess = widget.hasAccess;
    final showHoverBorder = hasAccess && _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: hasAccess ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: hasAccess ? _open : null,
        child: Opacity(
          opacity: hasAccess ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.mainBg3,
              borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
              border: Border.all(
                width: 2,
                color: showHoverBorder ? AppColors.blue : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasAccess ? Icons.description_outlined : Icons.lock_outline,
                  color: AppColors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.material.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onDark,
                          fontWeight: AppFonts.medium,
                        ),
                      ),
                      if (dateLabel != null)
                        Text(
                          dateLabel,
                          style: AppTypography.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasAccess) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.download,
                    color: AppColors.blue,
                    size: 14,
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
