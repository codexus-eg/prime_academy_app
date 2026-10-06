import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/kuwait_time.dart';
import '../../../data/live_sessions/live_session.dart';
import '../../../data/live_sessions/live_sessions_store.dart';

/// Host overlay that mirrors web `LiveSessionsDialog`.
class LiveSessionsHost extends StatelessWidget {
  const LiveSessionsHost({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiveSessionsStore.instance,
      builder: (context, _) {
        final sessions = LiveSessionsStore.instance.liveSessions;
        if (sessions.isEmpty) return const SizedBox.shrink();
        return _LiveSessionsDialog(sessions: sessions);
      },
    );
  }
}

class _LiveSessionsDialog extends StatelessWidget {
  const _LiveSessionsDialog({required this.sessions});

  final List<LiveSession> sessions;

  @override
  Widget build(BuildContext context) {
    final title = sessions.length == 1 ? 'حصة مباشرة' : 'حصص مباشرة';

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Dialog(
                backgroundColor: AppColors.secondaryBg,
                insetPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMd,
                  side: BorderSide(
                    color: AppColors.accentBg.withValues(alpha: 0.3),
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.headingDialog.copyWith(
                                  color: AppColors.onDark,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: LiveSessionsStore.instance.dismissAll,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.onDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.accentBg20,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.smPlus,
                                ),
                                border: Border.all(
                                  color: AppColors.accentBg40,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_active_rounded,
                                color: AppColors.accentBg,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'لديك ${sessions.length} '
                                    '${sessions.length == 1 ? 'حصة مباشرة' : 'حصص مباشرة'} الآن',
                                    style: AppTypography.headingDialog.copyWith(
                                      color: AppColors.onDark,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    'يمكنك الانضمام الآن أو إغلاق التنبيه',
                                    style: AppTypography.custom(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.base),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: sessions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              return _SessionCard(session: sessions[index]);
                            },
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
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final LiveSession session;

  Future<void> _join(BuildContext context) async {
    final link = session.meetingLink?.trim();
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('لا يوجد رابط متاح لهذه الحصة بعد')),
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط')),
        );
        return;
      }
      LiveSessionsStore.instance.dismissAll();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = KuwaitTime.formatTimeWithLabel(session.startTime);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBg,
        borderRadius: BorderRadius.circular(AppRadius.mdPlus),
        border: Border.all(color: AppColors.accentBg30),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(AppRadius.mdPlus),
                  bottomStart: Radius.circular(AppRadius.mdPlus),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      session.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.custom(
                        fontSize: 14,
                        color: AppColors.onDark,
                      ),
                    ),
                    if (session.courseName.isNotEmpty &&
                        session.courseName != session.title) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        session.courseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (timeLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.onDark.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              timeLabel,
                              style: AppTypography.custom(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (session.hasMeetingLink) ...[
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _join(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentBg,
                          foregroundColor: AppColors.onDark,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.smPlus,
                          ),
                        ),
                        icon: const Icon(Icons.videocam_rounded, size: 18),
                        label: const Text('انضم الآن'),
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.accentBg20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.accentBg,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'الرابط لم يُضف بعد، تواصل مع المعلم للحصول عليه',
                                style: AppTypography.custom(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
