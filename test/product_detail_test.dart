import 'dart:async';

import 'package:chot_hoi/core/services/supabase_service.dart';
import 'package:chot_hoi/core/widgets/empty_state.dart';
import 'package:chot_hoi/core/widgets/marketplace_price_card.dart';
import 'package:chot_hoi/features/product/product_detail_screen.dart';
import 'package:chot_hoi/models/category.dart';
import 'package:chot_hoi/models/db/product_record.dart';
import 'package:chot_hoi/models/product.dart';
import 'package:chot_hoi/models/search_result.dart';
import 'package:chot_hoi/repositories/product_repository.dart';
import 'package:chot_hoi/repositories/supabase/product_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_overrides.dart';
import 'product_mapper_test.dart' show supabaseProductRow;

/// Only [getProductById] matters for the detail screen.
class _DetailRepository implements ProductRepository {
  _DetailRepository(this._load);

  final Future<Product?> Function() _load;

  @override
  Future<Product?> getProductById(String id) => _load();

  @override
  Future<List<Product>> getProducts() async => const [];
  @override
  Future<List<ProductCategory>> getCategories() async => const [];
  @override
  Future<List<Product>> getTodayDeals() async => const [];
  @override
  Future<List<Product>> getRecommendations() async => const [];
  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async => const [];
  @override
  Future<SearchResult> searchProducts(String query) async => SearchResult(
    intent: SearchIntent(query: query),
    products: const [],
  );
  @override
  Future<List<String>> getAiSuggestions() async => const [];
}

Future<void> _pump(WidgetTester tester, _DetailRepository repository) async {
  tester.view
    ..physicalSize = const Size(360, 800) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: mockRepositoryOverrides(products: repository),
      child: const MaterialApp(home: ProductDetailScreen(productId: 'p-1')),
    ),
  );
}

Finder _scrollable() => find.descendant(of: find.byType(ProductDetailScreen), matching: find.byType(Scrollable)).first;

void main() {
  final product = ProductMapper.toProduct(ProductRecord.fromJson(supabaseProductRow))!;

  testWidgets('shows 4 marketplaces sorted by price with the cheapest flagged', (tester) async {
    await _pump(tester, _DetailRepository(() async => product));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('So sánh giá giữa các sàn'), 200, scrollable: _scrollable());
    await tester.scrollUntilVisible(find.text('Tiki'), 100, scrollable: _scrollable());

    final cards = tester.widgetList<MarketplacePriceCard>(find.byType(MarketplacePriceCard)).toList();
    expect(cards.map((c) => c.offer.marketplace.name), ['Shopee', 'TikTok Shop', 'Lazada', 'Tiki']);
    expect(find.text('🔥 Rẻ nhất'), findsOneWidget);
    expect(find.text('-13%'), findsOneWidget);
    expect(find.text('Còn hàng'), findsNWidgets(4));
    expect(find.text('29.090.300đ'), findsWidgets);
  });

  testWidgets('price history shows stats and switches marketplace', (tester) async {
    await _pump(tester, _DetailRepository(() async => product));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Thấp nhất'), 200, scrollable: _scrollable());
    expect(find.text('Cao nhất'), findsOneWidget);
    expect(find.text('31.090.300đ'), findsOneWidget);
    expect(find.textContaining('Đang giảm'), findsOneWidget);

    await tester.drag(_scrollable(), const Offset(0, -300));
    await tester.pumpAndSettle();
    final tikiTab = find.descendant(of: find.byType(SingleChildScrollView), matching: find.text('Tiki'));
    await tester.ensureVisible(tikiTab);
    await tester.pumpAndSettle();
    await tester.tap(tikiTab);
    await tester.pump();
    expect(find.text('32.739.750đ'), findsOneWidget);
  });

  testWidgets('loading then error state with working retry', (tester) async {
    final pending = Completer<Product?>();
    var fail = true;
    final repository = _DetailRepository(() {
      if (!pending.isCompleted) return pending.future;
      if (fail) throw const DataFailure('Không tải được dữ liệu. Vui lòng thử lại.');
      return Future.value(product);
    });

    await _pump(tester, repository);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(const DataFailure('Không tải được dữ liệu. Vui lòng thử lại.'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Không tải được dữ liệu. Vui lòng thử lại.'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Samsung Galaxy S25 Ultra'), findsOneWidget);
  });

  testWidgets('empty state when product does not exist', (tester) async {
    await _pump(tester, _DetailRepository(() async => null));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
  });
}
