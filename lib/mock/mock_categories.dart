import '../models/category.dart';
import 'mock_images.dart';

abstract final class MockCategories {
  static const List<ProductCategory> all = [
    ProductCategory(
      id: 'phone',
      name: 'Điện thoại',
      iconKey: 'phone',
      imageUrl: MockImages.iphone,
      keywords: ['dien thoai', 'smartphone'],
    ),
    ProductCategory(
      id: 'laptop',
      name: 'Laptop',
      iconKey: 'laptop',
      imageUrl: MockImages.asusTuf,
      keywords: ['laptop', 'may tinh xach tay', 'notebook'],
    ),
    ProductCategory(
      id: 'headphone',
      name: 'Tai nghe',
      iconKey: 'headphones',
      imageUrl: MockImages.sonyXm6,
      keywords: ['tai nghe', 'headphone', 'earbuds'],
    ),
    ProductCategory(
      id: 'home',
      name: 'Gia dụng',
      iconKey: 'home',
      imageUrl: MockImages.robotVacuum,
      keywords: ['gia dung', 'robot hut bui', 'may hut bui'],
    ),
    ProductCategory(
      id: 'fashion',
      name: 'Thời trang',
      iconKey: 'fashion',
      imageUrl: MockImages.sneaker,
      keywords: ['thoi trang', 'giay', 'quan ao'],
    ),
    ProductCategory(
      id: 'mouse',
      name: 'Chuột',
      iconKey: 'mouse',
      imageUrl: MockImages.mxMaster,
      keywords: ['chuot', 'mouse'],
    ),
    ProductCategory(
      id: 'keyboard',
      name: 'Bàn phím',
      iconKey: 'keyboard',
      imageUrl: MockImages.keyboard,
      keywords: ['ban phim', 'keyboard'],
    ),
    ProductCategory(
      id: 'monitor',
      name: 'Màn hình',
      iconKey: 'monitor',
      imageUrl: MockImages.monitor,
      keywords: ['man hinh', 'monitor'],
    ),
    ProductCategory(
      id: 'watch',
      name: 'Smartwatch',
      iconKey: 'watch',
      imageUrl: MockImages.appleWatch,
      keywords: ['dong ho', 'smartwatch', 'dong ho thong minh'],
    ),
    ProductCategory(
      id: 'accessory',
      name: 'Phụ kiện',
      iconKey: 'accessory',
      imageUrl: MockImages.powerBank,
      keywords: ['phu kien', 'sac du phong', 'pin du phong'],
    ),
  ];

  static ProductCategory byId(String id) => all.firstWhere((c) => c.id == id, orElse: () => all.first);
}
