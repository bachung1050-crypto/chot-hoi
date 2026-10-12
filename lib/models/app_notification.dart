enum NotificationType {
  priceDrop('Cảnh báo giá'),
  deal('Cập nhật deal'),
  restock('Cập nhật deal'),
  system('Hệ thống');

  const NotificationType(this.groupLabel);

  final String groupLabel;
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

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final String? productId;
  final bool isRead;
}
