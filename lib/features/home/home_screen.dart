import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/chot_hoi_logo.dart';
import '../../core/widgets/ai_search_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/product_horizontal_card.dart';
import '../../core/widgets/section_header.dart';
import '../../models/category.dart';
import '../product/providers/product_providers.dart';
import '../profile/providers/profile_providers.dart';
import 'widgets/ai_banner.dart';
import 'widgets/category_shortcuts.dart';
import 'widgets/deal_card.dart';
import 'widgets/image_search_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const int _shortcutCount = 5;
  static const int _dealsPerScreen = 3;
  static const double _dealGap = 10;

  void _openCategory(BuildContext context, ProductCategory category) {
    context.push('${AppRoutes.results}?category=${category.id}');
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(categoriesProvider)
      ..invalidate(productsProvider)
      ..invalidate(todayDealsProvider)
      ..invalidate(recommendedProductsProvider);
    await Future.wait([ref.read(todayDealsProvider.future), ref.read(recommendedProductsProvider.future)]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final deals = ref.watch(todayDealsProvider);
    final worthBuying = ref.watch(worthBuyingCategoriesProvider);
    final recommended = ref.watch(recommendedProductsProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [AppColors.primaryLight, AppColors.background],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => _refresh(ref),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList.list(
                    children: [
                      AppSpacing.gapMd,
                      Text('Xin chào 👋', style: AppTextStyles.h1),
                      const SizedBox(height: 2),
                      Text(
                        'Hôm nay bạn muốn tìm gì?',
                        style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      AppSpacing.gapLg,
                      AiSearchBar(readOnly: true, onTap: () => context.go(AppRoutes.search)),
                      AppSpacing.gapLg,
                      ImageSearchCard(
                        onCapture: () => context.push(AppRoutes.imageSearch),
                        onPickLibrary: () => context.push(AppRoutes.imageSearchLibrary),
                      ),
                      AppSpacing.gapLg,
                      categories.when(
                        data: (items) => CategoryShortcuts(
                          categories: items.take(_shortcutCount).toList(),
                          onSelected: (c) => _openCategory(context, c),
                        ),
                        loading: () => const SkeletonBox(height: 74),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      AppSpacing.gapLg,
                      AiBanner(onTap: () => context.go(AppRoutes.search)),
                      AppSpacing.gapLg,
                      SectionHeader(
                        title: 'Deal hời hôm nay',
                        actionColor: AppColors.ai,
                        onAction: () => context.push('${AppRoutes.results}?q=deal'),
                      ),
                      AppSpacing.gapXs,
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: deals.when(
                    data: (items) => items.isEmpty
                        ? const Padding(
                            padding: AppSpacing.screenPadding,
                            child: EmptyState(
                              icon: Icons.local_offer_outlined,
                              title: 'Chưa có deal hôm nay',
                              message: 'Quay lại sau để xem deal mới nhé.',
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth =
                                  (constraints.maxWidth - AppSpacing.screen * 2 - _dealGap * (_dealsPerScreen - 1)) /
                                  _dealsPerScreen;
                              return SizedBox(
                                height: cardWidth / 1.2 + 92,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 4, AppSpacing.screen, 8),
                                  itemCount: items.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: _dealGap),
                                  itemBuilder: (context, index) => DealCard(
                                    product: items[index],
                                    heroTag: 'home-deal-${items[index].id}',
                                    width: cardWidth,
                                  ),
                                ),
                              );
                            },
                          ),
                    loading: () => const CarouselSkeleton(height: 170),
                    error: (error, _) => Padding(
                      padding: AppSpacing.screenPadding,
                      child: ErrorState(message: error.toString(), onRetry: () => ref.invalidate(todayDealsProvider)),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList.list(
                    children: [
                      AppSpacing.gapSm,
                      SectionHeader(
                        title: 'Đang đáng mua',
                        leading: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.local_fire_department_rounded, color: AppColors.onDark, size: 18),
                        ),
                      ),
                      AppSpacing.gapSm,
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: worthBuying.when(
                    data: (items) => WorthBuyingChips(categories: items, onSelected: (c) => _openCategory(context, c)),
                    loading: () => const SizedBox(height: 42),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                SliverPadding(
                  padding: AppSpacing.screenPadding,
                  sliver: SliverList.list(
                    children: [
                      AppSpacing.gapXl,
                      const SectionHeader(
                        title: 'Gợi ý cho bạn',
                        subtitle: 'Chốt Hời AI chấm điểm cao nhất',
                        leading: Icon(Icons.auto_awesome_rounded, color: AppColors.ai, size: 24),
                      ),
                      AppSpacing.gapMd,
                      recommended.when(
                        data: (items) => Column(
                          children: [
                            for (final product in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: ProductHorizontalCard(
                                  product: product,
                                  heroTag: 'home-rec-${product.id}',
                                  showScore: true,
                                  showMarketplaces: false,
                                ),
                              ),
                          ],
                        ),
                        loading: () => const ProductListSkeleton(),
                        error: (error, _) => ErrorState(
                          message: error.toString(),
                          onRetry: () => ref.invalidate(recommendedProductsProvider),
                        ),
                      ),
                      AppSpacing.gapLg,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.sm, 0),
      child: Row(
        children: [
          const ChotHoiLogo(),
          const Spacer(),
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.danger,
              smallSize: 9,
              child: const Icon(Icons.notifications_rounded, color: AppColors.text, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}
