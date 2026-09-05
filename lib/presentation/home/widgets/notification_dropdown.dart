import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/notification_styles.dart';
import '../../../core/widgets/buttons/notification_bell_button.dart';
import '../../../data/auth/auth_session.dart';
import '../../../data/notifications/notification_models.dart';
import '../../../data/notifications/notification_store.dart';
import '../../../data/notifications/notifications_api.dart';
import 'notification_icons.dart';
import 'notification_link.dart';
import 'notification_navigator.dart';

class NotificationDropdown extends StatefulWidget {
  const NotificationDropdown({super.key});

  static const int pageSize = 25;

  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown>
    with WidgetsBindingObserver {
  final _store = NotificationStore.instance;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  bool _open = false;
  bool _loading = false;
  bool _enabled = false;
  int _visibleCount = NotificationDropdown.pageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store.addListener(_onStoreChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_onStoreChanged);
    _removeOverlay();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _enabled) {
      unawaited(_fetchNotifications());
    }
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {});
    _overlayEntry?.markNeedsBuild();
  }

  Future<void> _bootstrap() async {
    final user = await AuthSession.load();
    final enabled = user != null && user.id > 0 && user.role != 0;
    if (!mounted) return;

    setState(() => _enabled = enabled);
    if (!enabled) return;

    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    try {
      final notifications = await NotificationsApi.fetchAll();
      if (!mounted) return;
      setState(() {
        _store.setNotifications(notifications);
        _loading = false;
      });
      _overlayEntry?.markNeedsBuild();
    } on ApiException {
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _toggle() {
    if (!_enabled) return;

    if (!_open) {
      _store.clearNewNotificationFlag();
      _visibleCount = NotificationDropdown.pageSize;
      _showOverlay();
      setState(() => _open = true);
      _fetchNotifications();
      return;
    }

    _close();
  }

  void _close() {
    _removeOverlay();
    setState(() {
      _open = false;
      _visibleCount = NotificationDropdown.pageSize;
    });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        layerLink: _layerLink,
        onDismiss: _close,
        child: _NotificationPanel(
          store: _store,
          loading: _loading,
          visibleCount: _visibleCount,
          onMarkRead: _markAsRead,
          onOpenItem: _openItem,
          onLoadMore: () {
            setState(() {
              _visibleCount += NotificationDropdown.pageSize;
            });
            _overlayEntry?.markNeedsBuild();
          },
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _markAsRead(List<int> ids) async {
    if (ids.isEmpty) return;
    // Optimistic update so the unread→read fade is visible (web transition-all).
    if (!mounted) return;
    setState(() => _store.markAsRead(ids));
    _overlayEntry?.markNeedsBuild();
    try {
      await NotificationsApi.markRead(ids);
    } on ApiException {
      return;
    }
  }

  Future<void> _handleGroupTap(
    NotificationType groupType,
    int groupId,
  ) async {
    final unreadIds = _store.getUnreadGroupNotificationIds(groupType, groupId);
    if (unreadIds.isNotEmpty) await _markAsRead(unreadIds);
  }

  Future<void> _handleItemTap(AppNotification notification) async {
    if (!notification.isRead) {
      await _markAsRead([notification.id]);
    }
  }

  bool _itemWasUnread(NotificationListItem item) {
    return switch (item) {
      IndividualNotificationItem(:final notification) => !notification.isRead,
      GroupNotificationItem(:final group) => group.unreadCount > 0,
    };
  }

  Future<void> _openItem(NotificationListItem item) async {
    final target = NotificationLink.forItem(item);
    final showFade = _itemWasUnread(item);
    switch (item) {
      case GroupNotificationItem(:final group):
        await _handleGroupTap(group.groupType, group.groupId);
      case IndividualNotificationItem(:final notification):
        await _handleItemTap(notification);
    }
    if (!mounted) return;
    // Let border/icon color fade (300ms) before leaving, matching web.
    if (showFade) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
    _close();
    await NotificationNavigator.open(context, target);
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return const SizedBox.shrink();
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: NotificationBellButton(
        onTap: _toggle,
        showDot: _store.hasUnread,
      ),
    );
  }
}

class _NotificationOverlay extends StatelessWidget {
  const _NotificationOverlay({
    required this.layerLink,
    required this.onDismiss,
    required this.child,
  });

  final LayerLink layerLink;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: layerLink,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, AppSpacing.sm),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _NotificationPanel extends StatefulWidget {
  const _NotificationPanel({
    required this.store,
    required this.loading,
    required this.visibleCount,
    required this.onMarkRead,
    required this.onOpenItem,
    required this.onLoadMore,
  });

  final NotificationStore store;
  final bool loading;
  final int visibleCount;
  final Future<void> Function(List<int> ids) onMarkRead;
  final Future<void> Function(NotificationListItem item) onOpenItem;
  final VoidCallback onLoadMore;

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 80) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.store.orderedNotifications;
    final visible = items.take(widget.visibleCount).toList();
    final hasMore = widget.visibleCount < items.length;
    final unreadIds = _collectUnreadIds(items);

    return ClipRRect(
      borderRadius: NotificationStyles.itemRadius,
      child: Container(
        width: AppSpacing.notificationPanelWidth,
        height: AppSpacing.notificationPanelHeight,
        decoration: BoxDecoration(
          color: NotificationStyles.panelBackground,
          boxShadow: AppShadows.xl,
        ),
        child: widget.loading && items.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NotificationStyles.accentUnread,
                ),
              )
            : ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.base),
                children: [
                  Text(
                    'الإشعارات',
                    style: NotificationStyles.headerTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: NotificationStyles.headerDivider,
                  ),
                  if (unreadIds.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => widget.onMarkRead(unreadIds),
                        style: TextButton.styleFrom(
                          foregroundColor: NotificationStyles.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'تحديد الكل كمقروء',
                          style: NotificationStyles.markAllRead,
                        ),
                      ),
                    ),
                  ],
                  if (items.isEmpty) ...[
                    const SizedBox(height: AppSpacing.huge),
                    Text(
                      'لا توجد إشعارات جديدة',
                      textAlign: TextAlign.center,
                      style: NotificationStyles.emptyState,
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _NotificationTile(
                        item: visible[i],
                        onOpen: widget.onOpenItem,
                      ),
                    ],
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          'يتم التحميل...',
                          textAlign: TextAlign.center,
                          style: NotificationStyles.loadingFooter,
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  List<int> _collectUnreadIds(List<NotificationListItem> items) {
    return items.expand((item) {
      return switch (item) {
        IndividualNotificationItem(:final notification) =>
          notification.isRead ? <int>[] : [notification.id],
        GroupNotificationItem(:final group) => group.unreadCount > 0
            ? widget.store.getUnreadGroupNotificationIds(
                group.groupType,
                group.groupId,
              )
            : <int>[],
      };
    }).toList();
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onOpen,
  });

  final NotificationListItem item;
  final Future<void> Function(NotificationListItem item) onOpen;

  NotificationType get _type => switch (item) {
        IndividualNotificationItem(:final notification) => notification.type,
        GroupNotificationItem(:final group) => group.groupType,
      };

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      GroupNotificationItem(:final group) => _buildTile(
          isUnread: group.unreadCount > 0,
          isMasteryCard: false,
          isGroup: true,
          title: group.title,
          subtitle: group.unreadCount > 0
              ? '${group.unreadCount} غير مقروءة'
              : null,
          subtitleIsAccent: true,
          onTap: () => onOpen(item),
        ),
      IndividualNotificationItem(:final notification) => _buildTile(
          isUnread: !notification.isRead,
          isMasteryCard:
              notification.type == NotificationType.newKnowledgeQuizPoints,
          isGroup: false,
          title: NotificationIcons.titles[notification.type] ??
              notification.data.title,
          subtitle: notification.data.title,
          subtitleIsAccent: false,
          onTap: () => onOpen(item),
        ),
    };
  }

  Widget _buildTile({
    required bool isUnread,
    required bool isMasteryCard,
    required bool isGroup,
    required String title,
    required String? subtitle,
    required bool subtitleIsAccent,
    required Future<void> Function() onTap,
  }) {
    final unreadColor = NotificationStyles.accentUnread;
    final readColor = NotificationStyles.iconRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: NotificationStyles.itemRadius,
        hoverColor: NotificationStyles.itemBackgroundHover,
        splashColor: NotificationStyles.itemBackgroundHover,
        highlightColor: NotificationStyles.itemBackgroundHover,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: NotificationStyles.itemBackground,
            borderRadius: NotificationStyles.itemRadius,
            border: Border(
              right: BorderSide(
                width: 4,
                color: isUnread
                    ? NotificationStyles.accentUnread
                    : NotificationStyles.borderRead,
              ),
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            opacity: isMasteryCard && !isUnread ? 0.6 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TweenAnimationBuilder<Color?>(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    tween: ColorTween(
                      end: isUnread ? unreadColor : readColor,
                    ),
                    builder: (context, color, _) {
                      return NotificationIcons.forType(
                        _type,
                        isUnread: isUnread,
                        color: color,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: isGroup ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: isGroup
                            ? NotificationStyles.groupTitle
                            : NotificationStyles.itemTitle,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        SizedBox(
                          height: isGroup ? AppSpacing.xs : AppSpacing.xxs,
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleIsAccent
                              ? NotificationStyles.groupUnreadCount
                              : NotificationStyles.itemBody,
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
    );
  }
}
