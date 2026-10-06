import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/time/kuwait_time.dart';
import '../../../data/meeting_schedules/meeting_session.dart';
import '../../../data/meeting_schedules/meeting_sessions_cache.dart';
import '../../../data/meeting_schedules/meeting_sessions_local_scheduler.dart';
import '../../../data/meeting_schedules/meeting_sessions_sync.dart';

/// TEMP — debug-only panel for local session alarms. Remove after verification.
Future<void> showLocalSessionsDebugPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.primaryBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const _LocalSessionsDebugPanel(),
  );
}

class _LocalSessionsDebugPanel extends StatefulWidget {
  const _LocalSessionsDebugPanel();

  @override
  State<_LocalSessionsDebugPanel> createState() =>
      _LocalSessionsDebugPanelState();
}

class _LocalSessionsDebugPanelState extends State<_LocalSessionsDebugPanel> {
  var _loading = true;
  String? _error;
  DateTime? _syncedAt;
  List<_Row> _rows = const [];

  @override
  void initState() {
    super.initState();
    _reload(forceSync: true);
  }

  Future<void> _reload({required bool forceSync}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (forceSync) {
        MeetingSessionsSync.instance.attach();
        await MeetingSessionsSync.instance.sync();
      }

      final sessions = await MeetingSessionsCache.load();
      final scheduledIds = await MeetingSessionsCache.loadScheduledIds();
      final pendingIds =
          await MeetingSessionsLocalScheduler.loadPendingSessionIds();
      final syncedAt = await MeetingSessionsCache.syncedAt();

      final rows = sessions.map((session) {
        final inCacheSchedule = scheduledIds.contains(session.id);
        final inOsPending = pendingIds.contains(session.id);
        return _Row(
          session: session,
          cachedAsScheduled: inCacheSchedule,
          osPending: inOsPending,
        );
      }).toList()
        ..sort((a, b) => a.session.startTime.compareTo(b.session.startTime));

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _syncedAt = syncedAt;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  String _formatWhen(DateTime utc) {
    final kuwait = KuwaitTime.toKuwait(utc);
    final date = DateFormat('yyyy/MM/dd', 'en_US').format(kuwait);
    final time = DateFormat('hh:mm a', 'en_US').format(kuwait);
    return '$date · $time (${KuwaitTime.timeZoneLabel})';
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onDark.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'حصص مجدولة محليًا (تجربة)',
                      style: TextStyle(
                        fontFamily: AppFonts.bahij,
                        fontSize: 16,
                        fontWeight: AppFonts.bold,
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'تحديث وجدولة',
                    onPressed: _loading
                        ? null
                        : () => _reload(forceSync: true),
                    icon: const Icon(Icons.refresh, color: AppColors.onDark),
                  ),
                ],
              ),
            ),
            if (_syncedAt != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'آخر مزامنة: ${_formatWhen(_syncedAt!)}',
                  style: TextStyle(
                    fontFamily: AppFonts.bahij,
                    fontSize: 12,
                    color: AppColors.onDark.withValues(alpha: 0.65),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFonts.bahij,
                                color: AppColors.onDark,
                              ),
                            ),
                          ),
                        )
                      : _rows.isEmpty
                          ? Center(
                              child: Text(
                                'لا توجد حصص في الكاش المحلي',
                                style: TextStyle(
                                  fontFamily: AppFonts.bahij,
                                  color: AppColors.onDark.withValues(alpha: 0.7),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _rows.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final row = _rows[index];
                                final session = row.session;
                                final title = session.title.trim().isNotEmpty
                                    ? session.title.trim()
                                    : (session.courseName?.trim().isNotEmpty ==
                                            true
                                        ? session.courseName!.trim()
                                        : 'حصة #${session.id}');
                                final alarmOk =
                                    row.cachedAsScheduled && row.osPending;
                                final alarmLabel = alarmOk
                                    ? 'إشعار مجدول ✓'
                                    : row.cachedAsScheduled
                                        ? 'مجدول بالكاش — غير موجود في النظام'
                                        : 'غير مجدول';

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.overlayWhite4,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontFamily: AppFonts.bahij,
                                          fontSize: 14,
                                          fontWeight: AppFonts.medium,
                                          color: AppColors.onDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatWhen(session.startTime),
                                        style: TextStyle(
                                          fontFamily: AppFonts.bahij,
                                          fontSize: 12,
                                          color: AppColors.onDark
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${session.status.apiValue} · $alarmLabel',
                                        style: TextStyle(
                                          fontFamily: AppFonts.bahij,
                                          fontSize: 12,
                                          color: alarmOk
                                              ? const Color(0xFF4ADE80)
                                              : AppColors.onDark
                                                  .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  const _Row({
    required this.session,
    required this.cachedAsScheduled,
    required this.osPending,
  });

  final MeetingSession session;
  final bool cachedAsScheduled;
  final bool osPending;
}
