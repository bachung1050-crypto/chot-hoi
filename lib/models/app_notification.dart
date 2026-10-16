import '../core/utils/formatters.dart';
import 'db/json_read.dart';

enum NotificationType {
  priceDrop('Cảnh báo giá'),
  deal('Cập nhật deal'),
  restock('Cập nhật deal'),
  system('Hệ thống');

  const NotificationType(this.groupLabel);

  final String groupLabel;

  /// `notifications.type` is free text; unknown values fall back to [system].
  static NotificationType fromDb(String? value) {
    final type = (value ?? '').toLowerCase();
    if (type.contains('price') || type.contains('alert')) return priceDrop;
    if (type.contains('stock')) return restock;
    if (type.contains('deal')) return deal;
    return system;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.productId,
    this.isRead = false,
  });

  /// Row of `public.notifications` (`data.product_id` links to a product).
  factory AppNotification.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final data = JsonRead.map(json['data']) ?? const {};
    final createdAt = JsonRead.toDate(json['created_at']);
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.fromDb(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      timeLabel: createdAt == null ? '' : Formatters.timeAgo(createdAt, now: now),
      productId: data['product_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final String? productId;
  final bool isRead;

  AppNotification markRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    timeLabel: timeLabel,
    productId: productId,
    isRead: true,
  );
}
