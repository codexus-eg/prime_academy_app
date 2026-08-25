import 'package:flutter/foundation.dart';

import 'notification_models.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore({
    List<AppNotification> notifications = const [],
    List<GroupedNotification> groupedNotifications = const [],
    this.newNotification = false,
  })  : _notifications = List.of(notifications),
        _groupedNotifications = List.of(groupedNotifications),
        _orderedNotifications = _buildOrderedList(
          notifications,
          groupedNotifications,
        );

  static final NotificationStore instance = NotificationStore();

  List<AppNotification> _notifications;
  List<GroupedNotification> _groupedNotifications;
  List<NotificationListItem> _orderedNotifications;
  bool newNotification;

  List<NotificationListItem> get orderedNotifications =>
      List.unmodifiable(_orderedNotifications);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// True while any notification (or chat group) is unread.
  bool get hasUnread =>
      _hasUnread(_notifications, _groupedNotifications);

  void setNotifications(List<AppNotification> newNotifs) {
    final individual = <AppNotification>[];
    final groupsMap = <String, GroupedNotification>{};

    for (final notif in newNotifs) {
      if (notif.type == NotificationType.chat && notif.data.chatId != null) {
        final groupId = notif.data.chatId!;
        final key = '${notif.type.apiValue}-$groupId';
        final existing = groupsMap[key];

        if (existing != null) {
          groupsMap[key] = GroupedNotification(
            groupType: NotificationType.chat,
            groupId: groupId,
            title: notif.data.title,
            link: notif.data.link,
            courseId: notif.data.courseId ?? existing.courseId,
            moduleId: notif.data.moduleId ?? existing.moduleId,
            itemId: notif.data.itemId ?? existing.itemId,
            notificationIds: [...existing.notificationIds, notif.id],
            unreadCount: existing.unreadCount + (notif.isRead ? 0 : 1),
            latestTimestamp: notif.createdAt.isAfter(existing.latestTimestamp)
                ? notif.createdAt
                : existing.latestTimestamp,
            isRead: existing.isRead && notif.isRead,
          );
        } else {
          groupsMap[key] = GroupedNotification(
            groupType: NotificationType.chat,
            groupId: groupId,
            title: notif.data.title,
            link: notif.data.link,
            courseId: notif.data.courseId,
            moduleId: notif.data.moduleId,
            itemId: notif.data.itemId,
            notificationIds: [notif.id],
            unreadCount: notif.isRead ? 0 : 1,
            latestTimestamp: notif.createdAt,
            isRead: notif.isRead,
          );
        }
      } else {
        individual.add(notif);
      }
    }

    _notifications = newNotifs;
    _groupedNotifications = groupsMap.values.toList();
    _orderedNotifications =
        _buildOrderedList(_notifications, _groupedNotifications);
    newNotification = _hasUnread(_notifications, _groupedNotifications);
    notifyListeners();
  }

  void addIncoming(AppNotification notif) {
    if (_notifications.any((existing) => existing.id == notif.id)) return;
    if (notif.type == NotificationType.chat) {
      addGroupedNotification(notif);
      return;
    }
    addNotification(notif);
  }

  void addNotification(AppNotification notif) {
    _notifications = [notif, ..._notifications];
    _orderedNotifications =
        _buildOrderedList(_notifications, _groupedNotifications);
    if (!notif.isRead) newNotification = true;
    notifyListeners();
  }

  void addGroupedNotification(AppNotification notif) {
    if (notif.type != NotificationType.chat || notif.data.chatId == null) {
      addNotification(notif);
      return;
    }

    final groupId = notif.data.chatId!;
    _notifications = [notif, ..._notifications];
    final existingIndex = _groupedNotifications.indexWhere(
      (group) =>
          group.groupType == NotificationType.chat && group.groupId == groupId,
    );

    if (existingIndex >= 0) {
      final existing = _groupedNotifications[existingIndex];
      final updated = List<GroupedNotification>.from(_groupedNotifications);
      updated[existingIndex] = GroupedNotification(
        groupType: existing.groupType,
        groupId: existing.groupId,
        title: notif.data.title,
        link: notif.data.link,
        courseId: notif.data.courseId ?? existing.courseId,
        moduleId: notif.data.moduleId ?? existing.moduleId,
        itemId: notif.data.itemId ?? existing.itemId,
        notificationIds: [...existing.notificationIds, notif.id],
        unreadCount: existing.unreadCount + (notif.isRead ? 0 : 1),
        latestTimestamp: notif.createdAt,
        isRead: existing.isRead && notif.isRead,
      );
      _groupedNotifications = updated;
    } else {
      _groupedNotifications = [
        GroupedNotification(
          groupType: NotificationType.chat,
          groupId: groupId,
          title: notif.data.title,
          link: notif.data.link,
          courseId: notif.data.courseId,
          moduleId: notif.data.moduleId,
          itemId: notif.data.itemId,
          notificationIds: [notif.id],
          unreadCount: notif.isRead ? 0 : 1,
          latestTimestamp: notif.createdAt,
          isRead: notif.isRead,
        ),
        ..._groupedNotifications,
      ];
    }

    _orderedNotifications =
        _buildOrderedList(_notifications, _groupedNotifications);
    if (!notif.isRead) newNotification = true;
    notifyListeners();
  }

  void markAsRead(List<int> ids) {
    if (ids.isEmpty) return;

    _notifications = _notifications
        .map(
          (notification) => ids.contains(notification.id)
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList();

    _groupedNotifications = _groupedNotifications.map((group) {
      final markedIds =
          ids.where((id) => group.notificationIds.contains(id)).length;
      if (markedIds == 0) return group;

      final newUnreadCount =
          (group.unreadCount - markedIds).clamp(0, group.unreadCount);
      return GroupedNotification(
        groupType: group.groupType,
        groupId: group.groupId,
        title: group.title,
        link: group.link,
        courseId: group.courseId,
        moduleId: group.moduleId,
        itemId: group.itemId,
        notificationIds: group.notificationIds,
        unreadCount: newUnreadCount,
        latestTimestamp: group.latestTimestamp,
        isRead: newUnreadCount == 0,
      );
    }).toList();

    _orderedNotifications =
        _buildOrderedList(_notifications, _groupedNotifications);
    newNotification = _hasUnread(_notifications, _groupedNotifications);
    notifyListeners();
  }

  void markGroupAsRead(NotificationType groupType, int groupId) {
    if (groupType != NotificationType.chat) return;

    final unreadIds = getUnreadGroupNotificationIds(groupType, groupId);
    if (unreadIds.isEmpty) return;
    markAsRead(unreadIds);
  }

  List<int> getUnreadGroupNotificationIds(
    NotificationType groupType,
    int groupId,
  ) {
    if (groupType != NotificationType.chat) return [];

    GroupedNotification? group;
    for (final entry in _groupedNotifications) {
      if (entry.groupType == groupType && entry.groupId == groupId) {
        group = entry;
        break;
      }
    }
    if (group == null) return [];

    return group.notificationIds.where((id) {
      for (final notif in _notifications) {
        if (notif.id == id) return !notif.isRead;
      }
      return false;
    }).toList();
  }

  void clearNewNotificationFlag() {
    newNotification = false;
    notifyListeners();
  }

  static List<NotificationListItem> _buildOrderedList(
    List<AppNotification> notifications,
    List<GroupedNotification> groupedNotifications,
  ) {
    final individual = notifications
        .where((notification) => notification.type != NotificationType.chat)
        .map(IndividualNotificationItem.new);

    final grouped =
        groupedNotifications.map(GroupNotificationItem.new);

    final items = [...individual, ...grouped].toList()
      ..sort((a, b) {
        final aTime = switch (a) {
          IndividualNotificationItem(:final notification) =>
            notification.createdAt,
          GroupNotificationItem(:final group) => group.latestTimestamp,
        };
        final bTime = switch (b) {
          IndividualNotificationItem(:final notification) =>
            notification.createdAt,
          GroupNotificationItem(:final group) => group.latestTimestamp,
        };
        return bTime.compareTo(aTime);
      });

    return items;
  }

  static bool _hasUnread(
    List<AppNotification> notifications,
    List<GroupedNotification> groupedNotifications,
  ) {
    final individualUnread = notifications.any(
      (notification) =>
          notification.type != NotificationType.chat && !notification.isRead,
    );
    final groupUnread =
        groupedNotifications.any((group) => group.unreadCount > 0);
    return individualUnread || groupUnread;
  }
}
