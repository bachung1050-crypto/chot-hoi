import '../models/app_notification.dart';

/// `notifications` of the signed-in user. Rows are created by the backend only.
abstract interface class NotificationRepository {
  /// Newest first.
  Future<List<AppNotification>> getNotifications({int limit = 50});

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();
}
