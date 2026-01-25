import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  List<NotificationItem> _notifications = [];

  // Initialize with dummy notifications
  NotificationService._internal() {
    _notifications = _generateDummyNotifications();
  }

  List<NotificationItem> _generateDummyNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: 'notif-1',
        type: NotificationType.ad,
        title: 'New Ad Available',
        message: 'A new ad has been added. Check it out now.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        relatedId: 'ad-1',
      ),
      NotificationItem(
        id: 'notif-2',
        type: NotificationType.activity,
        title: 'New Follower',
        message: 'Alice Smith started following you',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationItem(
        id: 'notif-3',
        type: NotificationType.ad,
        title: 'New Ad Available',
        message: 'Special offer - 50% off on selected products',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: true,
        relatedId: 'ad-2',
      ),
      NotificationItem(
        id: 'notif-4',
        type: NotificationType.activity,
        title: 'Like on Your Post',
        message: 'Bob Johnson liked your post',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: false,
      ),
      NotificationItem(
        id: 'notif-5',
        type: NotificationType.system,
        title: 'System Update',
        message: 'New features available in the latest update',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationItem(
        id: 'notif-6',
        type: NotificationType.ad,
        title: 'New Ad Available',
        message: 'Discover amazing deals on premium products',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: false,
        relatedId: 'ad-3',
      ),
      NotificationItem(
        id: 'notif-7',
        type: NotificationType.activity,
        title: 'Comment on Your Post',
        message: 'Emma Wilson commented on your post',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  // Get all notifications (latest first)
  List<NotificationItem> getNotifications() {
    return List.from(_notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get unread count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  // Mark all as read
  void markAllAsRead() {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
  }

  // Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  // Add new notification (for new ads, etc.)
  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
  }

  // Simulate receiving a new ad notification
  void addNewAdNotification(String adId, String adTitle) {
    final notification = NotificationItem(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.ad,
      title: 'New Ad Available',
      message: adTitle.isNotEmpty
          ? '$adTitle - Check it out now!'
          : 'A new ad has been added. Check it out now.',
      timestamp: DateTime.now(),
      isRead: false,
      relatedId: adId,
    );
    addNotification(notification);
  }

  // Get notification by ID
  NotificationItem? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get notifications stream (for real-time updates)
  Stream<List<NotificationItem>> getNotificationsStream() {
    return Stream.value(getNotifications());
  }
}
