import 'package:chot_hoi/app/app.dart';
import 'package:chot_hoi/core/widgets/product_horizontal_card.dart';
import 'package:chot_hoi/features/cart/deal_cart_screen.dart';
import 'package:chot_hoi/features/home/home_screen.dart';
import 'package:chot_hoi/features/image_search/image_deal_screen.dart';
import 'package:chot_hoi/features/product/product_detail_screen.dart';
import 'package:chot_hoi/features/search/ai_search_screen.dart';
import 'package:chot_hoi/mock/mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_overrides.dart';

const _screenSizes = <String, Size>{'360x800': Size(360, 800), '390x844': Size(390, 844), '412x915': Size(412, 915)};

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

Future<void> _startApp(WidgetTester tester, Size size, {bool signedIn = true}) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: mockRepositoryOverrides(signedIn: signedIn),
      child: const ChotHoiApp(),
    ),
  );
  await _pumpFor(tester, const Duration(seconds: 1));
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _pumpFor(tester, const Duration(seconds: 3));
}

Finder _navLabel(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder _horizontalCard(String name) => find.widgetWithText(ProductHorizontalCard, name);

Future<void> _openProduct(WidgetTester tester, String name) async {
  final card = _horizontalCard(name);
  await tester.scrollUntilVisible(
    card,
    300,
    scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first,
  );
  await tester.ensureVisible(card);
  await tester.pump();
  await tester.tap(card);
  await _pumpFor(tester, const Duration(seconds: 2));
}

void main() {
  testWidgets('signed out: user tabs ask to log in and actions prompt login', (tester) async {
    await _startApp(tester, const Size(390, 844), signedIn: false);

    await tester.tap(_navLabel('Đã lưu'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Đăng nhập để xem sản phẩm đã lưu'), findsOneWidget);

    await tester.tap(_navLabel('Giỏ hời'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Đăng nhập để dùng Giỏ hời'), findsOneWidget);

    await tester.tap(_navLabel('Cá nhân'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);

    await tester.tap(find.text('Đăng nhập'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), MockData.profile.email);
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await _pumpFor(tester, const Duration(seconds: 2));
    expect(find.text('Nguyễn Văn A'), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('signed out: saving a product shows the login prompt', (tester) async {
    await _startApp(tester, const Size(390, 844), signedIn: false);
    await _openProduct(tester, 'Lenovo LOQ 15');

    await tester.tap(find.text('Lưu'));
    await _pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.text('Đăng nhập để sử dụng tính năng này'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('product -> price alert sheet -> alerts screen -> toggle -> delete', (tester) async {
    await _startApp(tester, const Size(390, 844));
    await _openProduct(tester, 'Lenovo LOQ 15');

    await tester.tap(find.byTooltip('Báo khi giảm giá'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Báo tôi khi giảm giá'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '19990000');
    await tester.tap(find.text('Tạo cảnh báo'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.textContaining('Sẽ báo bạn khi giá ≤'), findsOneWidget);
    await _pumpFor(tester, const Duration(seconds: 5));

    await tester.tap(find.byTooltip('Quay lại'));
    await _pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(_navLabel('Cá nhân'));
    await _pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Cảnh báo giá').last);
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Cảnh báo giá (6)'), findsOneWidget);

    final tile = find.ancestor(of: find.text('Lenovo LOQ 15'), matching: find.byType(InkWell)).first;
    final toggle = find.descendant(of: tile, matching: find.byType(Switch));
    await tester.tap(toggle);
    await _pumpFor(tester, const Duration(milliseconds: 500));
    final paused = find.descendant(of: tile, matching: find.text('Đã tạm dừng theo dõi'));
    expect(paused, findsOneWidget);
    await tester.tap(toggle);
    await _pumpFor(tester, const Duration(milliseconds: 500));
    expect(paused, findsNothing);

    await tester.tap(find.text('Lenovo LOQ 15'));
    await _pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Xóa cảnh báo'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Cảnh báo giá (5)'), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('search history chip searches again and history can be cleared', (tester) async {
    await _startApp(tester, const Size(390, 844));
    await tester.tap(_navLabel('Tìm kiếm'));
    await _pumpFor(tester, const Duration(seconds: 1));

    final idle = find.descendant(of: find.byType(AiSearchScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Tìm kiếm gần đây'), 200, scrollable: idle);
    await tester.scrollUntilVisible(find.text('Nhấn giữ một mục để xóa khỏi lịch sử'), 100, scrollable: idle);
    await tester.ensureVisible(find.text('bàn phím cơ'));
    await tester.pump();
    await tester.tap(find.text('bàn phím cơ'));
    await _pumpFor(tester, const Duration(seconds: 3));
    expect(find.textContaining('Tìm thấy'), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await _pumpFor(tester, const Duration(seconds: 1));
    await tester.scrollUntilVisible(find.text('Xóa tất cả'), 200, scrollable: idle);
    await tester.tap(find.text('Xóa tất cả'));
    await _pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.text('Xóa hết'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Tìm kiếm gần đây'), findsNothing);

    await _finish(tester);
  });

  testWidgets('notification tap marks it read and clears the badge with mark-all', (tester) async {
    await _startApp(tester, const Size(390, 844));
    await tester.tap(find.byTooltip('Thông báo'));
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byTooltip('Đánh dấu tất cả đã đọc'), findsOneWidget);
    await tester.tap(find.text('Deal hời hôm nay'));
    await _pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Đánh dấu tất cả đã đọc'));
    await _pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.byTooltip('Đánh dấu tất cả đã đọc'), findsNothing);

    await _finish(tester);
  });

  testWidgets('profile edit sheet updates the display name', (tester) async {
    await _startApp(tester, const Size(390, 844));
    await tester.tap(_navLabel('Cá nhân'));
    await _pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.byTooltip('Cài đặt'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Trần Thị B');
    await tester.tap(find.text('English'));
    await tester.tap(find.text('Lưu thay đổi'));
    await _pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Đã cập nhật hồ sơ'), findsOneWidget);
    expect(find.text('Trần Thị B'), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('login screen sends a password reset email', (tester) async {
    await _startApp(tester, const Size(390, 844), signedIn: false);
    await tester.tap(_navLabel('Cá nhân'));
    await _pumpFor(tester, const Duration(seconds: 1));
    await tester.tap(find.text('Đăng nhập'));
    await _pumpFor(tester, const Duration(seconds: 1));

    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pump();
    expect(find.textContaining('Nhập email của bạn'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'demo@chothoi.vn');
    await tester.tap(find.text('Quên mật khẩu?'));
    await _pumpFor(tester, const Duration(milliseconds: 500));
    expect(find.text('Đã gửi liên kết đặt lại mật khẩu tới demo@chothoi.vn'), findsOneWidget);

    await _finish(tester);
  });

  for (final entry in _screenSizes.entries) {
    group('screen ${entry.key}', () {
      testWidgets('home renders and bottom navigation reaches every tab', (tester) async {
        await _startApp(tester, entry.value);

        expect(find.text('Xin chào 👋'), findsOneWidget);
        final homeScrollable = find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(find.text('Deal hời hôm nay'), 200, scrollable: homeScrollable);
        await tester.drag(homeScrollable, const Offset(0, 3000));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Xin chào 👋'), findsOneWidget);

        await tester.tap(_navLabel('Tìm kiếm'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Tìm kiếm AI'), findsOneWidget);

        await tester.tap(_navLabel('Giỏ hời'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Giỏ Hời (3)'), findsOneWidget);
        expect(find.text('🔥 Chốt deal ngay'), findsOneWidget);

        await tester.tap(_navLabel('Đã lưu'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Sản phẩm đã lưu (6)'), findsOneWidget);

        await tester.tap(_navLabel('Cá nhân'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Nguyễn Văn A'), findsOneWidget);

        await tester.tap(find.text('Cảnh báo giá').last);
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Cảnh báo giá (5)'), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại'));
        await _pumpFor(tester, const Duration(seconds: 1));

        await tester.tap(_navLabel('Trang chủ'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Xin chào 👋'), findsOneWidget);

        await tester.tap(find.byTooltip('Thông báo'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Giá đã giảm'), findsOneWidget);

        await _finish(tester);
      });

      testWidgets('home -> search -> product -> add to Deal Cart -> cart', (tester) async {
        await _startApp(tester, entry.value);

        await tester.tap(_navLabel('Tìm kiếm'));
        await _pumpFor(tester, const Duration(seconds: 1));

        await tester.enterText(find.byType(TextField), 'Tìm laptop dưới 25 triệu để code, ưu tiên ASUS hoặc Lenovo');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await _pumpFor(tester, const Duration(seconds: 3));

        expect(find.textContaining('Tìm thấy'), findsOneWidget);
        expect(find.textContaining('Chốt Hời AI'), findsWidgets);

        // Vertical results ListView (not the horizontal filter chip scroller).
        final resultsList = find
            .descendant(
              of: find.descendant(of: find.byType(AiSearchScreen), matching: find.byType(ListView)),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(find.text('Đề xuất tốt nhất'), 300, scrollable: resultsList);
        expect(find.text('Dưới 25 triệu'), findsOneWidget);

        final asus = _horizontalCard('ASUS TUF Gaming A15');
        await tester.scrollUntilVisible(asus, 400, scrollable: resultsList);
        await tester.ensureVisible(asus);
        await tester.pump();
        await tester.tap(asus);
        await _pumpFor(tester, const Duration(seconds: 2));

        expect(find.text('Mua trên Shopee'), findsOneWidget);
        final detailList = find
            .descendant(of: find.byType(ProductDetailScreen), matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(find.textContaining('Chốt Hời AI phân tích đánh giá'), 200, scrollable: detailList);
        await tester.scrollUntilVisible(find.text('So sánh giá giữa các sàn'), 200, scrollable: detailList);
        await tester.scrollUntilVisible(find.textContaining('Lịch sử giá'), 200, scrollable: detailList);

        await tester.tap(find.text('Thêm vào giỏ hời'));
        await _pumpFor(tester, const Duration(milliseconds: 500));
        expect(find.text('Đã thêm vào Giỏ hời (Shopee)'), findsOneWidget);

        await tester.tap(find.text('Xem giỏ'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Giỏ Hời (4)'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('ASUS TUF Gaming A15'),
          200,
          scrollable: find.descendant(of: find.byType(DealCartScreen), matching: find.byType(Scrollable)).first,
        );
        expect(find.text('ASUS TUF Gaming A15'), findsOneWidget);

        await _finish(tester);
      });

      testWidgets('home -> product -> save -> saved tab', (tester) async {
        await _startApp(tester, entry.value);

        final loq = _horizontalCard('Lenovo LOQ 15');
        await tester.scrollUntilVisible(
          loq,
          300,
          scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first,
        );
        await tester.ensureVisible(loq);
        await tester.pump();
        await tester.tap(loq);
        await _pumpFor(tester, const Duration(seconds: 2));

        await tester.tap(find.text('Lưu'));
        await _pumpFor(tester, const Duration(milliseconds: 500));
        expect(find.text('Đã lưu sản phẩm'), findsOneWidget);

        await tester.tap(find.byTooltip('Quay lại'));
        await _pumpFor(tester, const Duration(seconds: 1));

        await tester.tap(_navLabel('Đã lưu'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Sản phẩm đã lưu (7)'), findsOneWidget);
        expect(find.text('Lenovo LOQ 15'), findsOneWidget);

        await _finish(tester);
      });

      testWidgets('category grid -> filter screen -> apply', (tester) async {
        await _startApp(tester, entry.value);

        await tester.tap(find.text('Laptop').first);
        await _pumpFor(tester, const Duration(seconds: 2));
        expect(find.text('Tìm thấy 12 sản phẩm'), findsOneWidget);

        await tester.tap(find.text('Bộ lọc'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Khoảng giá'), findsOneWidget);

        await tester.tap(find.text('Lenovo'));
        await tester.pump();
        await tester.tap(find.textContaining('Áp dụng ('));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Tìm thấy 4 sản phẩm'), findsOneWidget);
        expect(find.text('Bộ lọc (1)'), findsOneWidget);

        await _finish(tester);
      });

      testWidgets('home image search -> request -> analysis -> result -> deal -> product', (tester) async {
        await _startApp(tester, entry.value);

        expect(find.text('TÌM BẰNG HÌNH ẢNH'), findsOneWidget);
        await tester.tap(find.text('Chụp ngay'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Tìm bằng hình ảnh'), findsOneWidget);

        await tester.tap(find.text('Chụp ảnh'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('Ảnh đã chọn'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'màu trắng');
        await tester.tap(find.text('Chính hãng'));
        await tester.pump();
        await tester.tap(find.text('Phân tích bằng AI'));
        await _pumpFor(tester, const Duration(milliseconds: 600));
        expect(find.text('Nhận diện sản phẩm'), findsOneWidget);

        await _pumpFor(tester, const Duration(seconds: 4));
        expect(find.text('Kết quả tìm kiếm'), findsOneWidget);
        expect(find.text('Sony WH-1000XM6'), findsOneWidget);
        expect(find.text('Độ chính xác: 96%'), findsOneWidget);

        await tester.tap(find.text('Xem đánh giá deal'));
        await _pumpFor(tester, const Duration(seconds: 1));
        expect(find.text('ĐÁNG MUA'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('màu trắng, Chính hãng'),
          200,
          scrollable: find.descendant(of: find.byType(ImageDealScreen), matching: find.byType(Scrollable)).first,
        );

        await tester.tap(find.text('Theo dõi giá'));
        await _pumpFor(tester, const Duration(milliseconds: 500));
        expect(find.textContaining('Sẽ báo khi giá về'), findsOneWidget);
        await _pumpFor(tester, const Duration(seconds: 5));

        await tester.tap(find.text('Xem chi tiết sản phẩm'));
        await _pumpFor(tester, const Duration(seconds: 2));
        expect(find.text('Mua trên Shopee'), findsOneWidget);

        await _finish(tester);
      });

      testWidgets('search error state shows retry', (tester) async {
        await _startApp(tester, entry.value);

        await tester.tap(_navLabel('Tìm kiếm'));
        await _pumpFor(tester, const Duration(seconds: 1));
        await tester.enterText(find.byType(TextField), 'lỗi');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await _pumpFor(tester, const Duration(seconds: 3));

        expect(find.text('Thử lại'), findsOneWidget);

        await _finish(tester);
      });
    });
  }
}
