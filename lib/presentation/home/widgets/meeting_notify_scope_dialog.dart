import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/meeting_schedules/meeting_schedule_notify_prefs.dart';

Future<MeetingScheduleNotifyScope?> showMeetingNotifyScopeDialog(
  BuildContext context, {
  required MeetingScheduleNotifyScope current,
}) {
  return showDialog<MeetingScheduleNotifyScope>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => _MeetingNotifyScopeDialog(current: current),
  );
}

class _MeetingNotifyScopeDialog extends StatefulWidget {
  const _MeetingNotifyScopeDialog({required this.current});

  final MeetingScheduleNotifyScope current;

  @override
  State<_MeetingNotifyScopeDialog> createState() =>
      _MeetingNotifyScopeDialogState();
}

class _MeetingNotifyScopeDialogState extends State<_MeetingNotifyScopeDialog> {
  late MeetingScheduleNotifyScope _selected = widget.current;

  void _select(MeetingScheduleNotifyScope scope) {
    setState(() => _selected = scope);
  }

  void _confirm() {
    Navigator.of(context, rootNavigator: true).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.mainBg2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
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
                      'إشعارات الحصص',
                      style: AppTypography.headingDialog.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.onDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'اختر من تصلهم إشعارات الحصص على هذا الجهاز',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              _ScopeTile(
                label: 'جميع المشتركين',
                subtitle: 'كل الحسابات على نفس رقم الهاتف',
                icon: Icons.groups_outlined,
                selected: _selected == MeetingScheduleNotifyScope.family,
                onTap: () => _select(MeetingScheduleNotifyScope.family),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ScopeTile(
                label: 'أنا فقط',
                subtitle: 'حصص الحساب الحالي فقط',
                icon: Icons.person_outline,
                selected: _selected == MeetingScheduleNotifyScope.personal,
                onTap: () => _select(MeetingScheduleNotifyScope.personal),
              ),
              const SizedBox(height: AppSpacing.base),
              FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: AppColors.onDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                ),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeTile extends StatelessWidget {
  const _ScopeTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.blue.withValues(alpha: 0.18)
          : AppColors.overlayWhite4,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: selected
                  ? AppColors.blue.withValues(alpha: 0.55)
                  : AppColors.overlayWhite10,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.onDark, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.blue : AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
