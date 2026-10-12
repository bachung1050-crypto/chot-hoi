import 'package:chot_hoi/app/app.dart';
import 'package:chot_hoi/core/widgets/product_horizontal_card.dart';
import 'package:chot_hoi/features/cart/deal_cart_screen.dart';
import 'package:chot_hoi/features/home/home_screen.dart';
import 'package:chot_hoi/features/image_search/image_deal_screen.dart';
import 'package:chot_hoi/features/product/product_detail_screen.dart';
import 'package:chot_hoi/features/search/ai_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _screenSizes = <String, Size>{'360x800': Size(360, 800), '390x844': Size(390, 844), '412x915': Size(412, 915)};

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
    await tester.pump(step);
  }
}

Future<void> _startApp(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: ChotHoiApp()));
  await _pumpFor(tester, const Duration(seconds: 1));
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _pumpFor(tester, const Duration(seconds: 3));
}

Finder _navLabel(String label) => find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Finder _horizontalCard(String name) => find.widgetWithText(ProductHorizontalCard, name);

void main() {
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

        final resultsList = find.descendant(of: find.byType(AiSearchScreen), matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(find.text('Đề xuất tốt nhất'), 200, scrollable: resultsList);
        expect(find.text('Dưới 25 triệu'), findsOneWidget);

        final asus = _horizontalCard('ASUS TUF Gaming A15');
        await tester.scrollUntilVisible(asus, 200, scrollable: resultsList);
        await tester.ensureVisible(asus);
        await tester.pump();
        await tester.tap(asus);
        await _pumpFor(tester, const Duration(seconds: 2));

        expect(find.text('Mua trên Shopee'), findsOneWidget);
        final detailList = find
            .descendant(of: find.byType(ProductDetailScreen), matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(find.textContaining('Chốt Hời AI đánh giá'), 200, scrollable: detailList);
        await tester.scrollUntilVisible(find.text('So sánh giá giữa các sàn'), 200, scrollable: detailList);
        await tester.scrollUntilVisible(find.textContaining('Lịch sử giá'), 200, scrollable: detailList);

        await tester.tap(find.text('Thêm vào giỏ hời'));
        await _pumpFor(tester, const Duration(milliseconds: 500));
        expect(find.text('Đã thêm vào Giỏ hời'), findsOneWidget);

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
