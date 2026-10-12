import '../models/app_notification.dart';
import '../models/marketplace.dart';
import '../models/user_profile.dart';
import 'mock_images.dart';

export 'mock_categories.dart';
export 'mock_marketplaces.dart';
export 'mock_products.dart';

/// Seed data for user-specific state (profile, saved list, cart, alerts...).
abstract final class MockData {
  static const UserProfile profile = UserProfile(
    id: 'user-001',
    name: 'Nguyễn Văn A',
    email: 'nguyenvana@gmail.com',
    avatarUrl: MockImages.avatar,
    searchCount: 28,
  );

  static const List<String> savedProductIds = [
    'galaxy-s25-ultra',
    'apple-watch-s10',
    'sony-wh-1000xm6',
    'hp-victus-16',
    'airpods-pro-2',
    'logitech-mx-master-3s',
  ];

  static const List<({String productId, MarketplaceCode marketplace})> cartItems = [
    (productId: 'macbook-air-m3', marketplace: MarketplaceCode.shopee),
    (productId: 'sony-wh-1000xm6', marketplace: MarketplaceCode.shopee),
    (productId: 'iphone-16-256', marketplace: MarketplaceCode.shopee),
  ];

  static const List<({String productId, int targetPrice, bool enabled})> priceAlerts = [
    (productId: 'macbook-air-m3', targetPrice: 22990000, enabled: true),
    (productId: 'iphone-16-256', targetPrice: 19990000, enabled: true),
    (productId: 'sony-wh-1000xm6', targetPrice: 8000000, enabled: true),
    (productId: 'asus-tuf-a15', targetPrice: 20000000, enabled: false),
    (productId: 'logitech-mx-master-3s', targetPrice: 1500000, enabled: true),
  ];

  static const List<AppNotification> notifications = [
    AppNotification(
      id: 'n1',
      type: NotificationType.priceDrop,
      title: 'Giá đã giảm',
      message: 'Sony WH-1000XM6 giảm 800.000đ còn 8.990.000đ trên Shopee.',
      timeLabel: '6 phút trước',
      productId: 'sony-wh-1000xm6',
    ),
    AppNotification(
      id: 'n2',
      type: NotificationType.deal,
      title: 'Deal hời hôm nay',
      message: 'Có 5 sản phẩm laptop dưới 25 triệu đang rất đáng mua.',
      timeLabel: '2 giờ trước',
    ),
    AppNotification(
      id: 'n3',
      type: NotificationType.restock,
      title: 'Sản phẩm quay lại hàng',
      message: 'iPhone 16 256GB đã có hàng trở lại tại Shopee.',
      timeLabel: '5 giờ trước',
      productId: 'iphone-16-256',
    ),
    AppNotification(
      id: 'n4',
      type: NotificationType.system,
      title: 'Cập nhật tính năng mới',
      message: 'Chốt Hời AI giờ đã có thể phân tích đánh giá sản phẩm cho bạn.',
      timeLabel: '1 ngày trước',
      isRead: true,
    ),
  ];

  static const List<String> searchHistory = [
    'laptop dưới 25 triệu',
    'Sony WH-1000XM6',
    'iPhone 16 256GB',
    'bàn phím cơ',
  ];

  static const List<String> aiSuggestions = [
    'Tìm laptop dưới 25 triệu để code, ưu tiên ASUS hoặc Lenovo',
    'Tai nghe chống ồn tốt nhất dưới 10 triệu',
    'Điện thoại chụp ảnh đẹp dưới 30 triệu',
    'Chuột không dây cho dân văn phòng',
  ];

  static const List<String> worthBuyingCategoryIds = ['laptop', 'phone', 'headphone', 'home'];
}
