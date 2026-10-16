import '../../core/services/supabase_service.dart';
import '../../models/app_notification.dart';
import '../notification_repository.dart';

/// Reads and marks the signed-in user's `notifications`. Never inserts.
class SupabaseNotificationRepository implements NotificationRepository {
  const SupabaseNotificationRepository(this._db);

  final SupabaseService _db;

  @override
  Future<List<AppNotification>> getNotifications({int limit = 50}) {
    final userId = _db.requireUserId();
    return _db.run((client) async {
      final rows = await client
          .from(DbTables.notifications)
          .select('id,type,title,body,data,is_read,created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      final now = DateTime.now();
      return [for (final row in rows) AppNotification.fromJson(row, now: now)];
    });
  }

  @override
  Future<void> markAsRead(String id) {
    final userId = _db.requireUserId();
    return _db.run((client) async {
      final updated = await client
          .from(DbTables.notifications)
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', userId)
          .select('id');
      if (updated.isEmpty) throw const DataFailure('Không thể cập nhật thông báo này.');
    });
  }

  @override
  Future<void> markAllAsRead() {
    final userId = _db.requireUserId();
    return _db.run(
      (client) =>
          client.from(DbTables.notifications).update({'is_read': true}).eq('user_id', userId).eq('is_read', false),
    );
  }
}
