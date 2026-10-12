abstract final class AppStrings {
  static const String appName = 'CHỐT HỜI';
  static const String tagline = 'So giá. Hiểu hàng. Chốt khôn.';
  static const String aiName = 'Chốt Hời AI';
  static const String version = '1.0.0';

  static const String homeSearchHint = 'Hỏi Chốt Hời AI...';
  static const String aiSearchHint = 'Mô tả món bạn cần, ví dụ: laptop dưới 25 triệu để code';
  static const String seeAll = 'Xem tất cả';

  static const List<String> searchSteps = [
    'Đang phân tích yêu cầu...',
    'Đang tìm sản phẩm phù hợp...',
    'Đang so sánh giá nhiều sàn...',
    'Đang phân tích đánh giá...',
    'Đang tổng hợp kết quả...',
  ];

  static const String imageSearchTitle = 'TÌM BẰNG HÌNH ẢNH';
  static const String imageSearchSubtitle = 'Chụp hoặc tải ảnh sản phẩm';
  static const List<String> imageSearchFlow = ['AI sẽ nhận diện', 'tìm sản phẩm', 'so sánh giá', 'đánh giá deal'];
  static const String imageRequestHint = 'Ví dụ: Tìm bản chính hãng, giá dưới 10 triệu, ưu tiên Shopee, màu trắng...';
  static const String imageSearchTip = 'Bạn có thể thêm yêu cầu chi tiết để kết quả chính xác hơn!';
  static const int imageRequestMaxLength = 200;

  static const List<String> imageSearchStages = ['Chụp ảnh', 'Thêm yêu cầu', 'Phân tích'];

  static const List<String> imageSearchSteps = [
    'Nhận diện sản phẩm',
    'Phân tích hình ảnh',
    'Hiểu yêu cầu của bạn',
    'Tìm sản phẩm tương tự',
    'So sánh giá trên các sàn TMĐT',
    'Đánh giá deal bằng AI',
  ];

  static const Map<String, String> purposeLabels = {
    'code': 'Để code',
    'gaming': 'Chơi game',
    'office': 'Văn phòng',
    'design': 'Đồ họa',
  };
}
