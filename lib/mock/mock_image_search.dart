import 'mock_images.dart';

/// Seed data for the "Tìm bằng hình ảnh" flow.
abstract final class MockImageSearch {
  /// Photos offered as camera frames / library picks in the demo.
  static const List<String> sampleImages = [
    MockImages.sonyXm6,
    MockImages.headphoneAlt1,
    MockImages.headphoneAlt2,
    MockImages.airpods,
  ];

  static const List<String> quickRequests = [
    'Dưới 10 triệu',
    'Chính hãng',
    'Có bảo hành',
    'Ưu tiên Shopee',
    'Ship nhanh',
    'Màu trắng',
  ];

  static const String recognizedProductId = 'sony-wh-1000xm6';
  static const int accuracyPercent = 96;
  static const List<String> recognizedTags = ['Tai nghe', 'Sony', 'Chống ồn', 'WH-1000XM6'];

  static const List<String> reasons = [
    'Giá hiện tại đang tốt hơn mặt bằng chung',
    'Sản phẩm chính hãng, nhiều shop uy tín',
    'Nhiều lượt mua và đánh giá tốt',
    'Phù hợp với yêu cầu của bạn',
  ];
}
