import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ai_insight_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../models/deal_cart_item.dart';
import '../../models/marketplace.dart';
import 'providers/deal_cart_provider.dart';
import 'widgets/deal_cart_item_card.dart';

class DealCartScreen extends ConsumerWidget {
  const DealCartScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa toàn bộ Giỏ hời?'),
        content: const Text('Các sản phẩm trong giỏ sẽ bị xóa. Bạn có thể thêm lại bất cứ lúc nào.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Xóa hết'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await ref.read(dealCartProvider.notifier).clear();
  }

  void _remove(BuildContext context, WidgetRef ref, DealCartItem item) {
    final notifier = ref.read(dealCartProvider.notifier);
    notifier.removeFromCart(item.id);
    AppSnackbar.show(
      context,
      'Đã xóa ${item.product.name} khỏi Giỏ hời',
      icon: Icons.delete_outline_rounded,
      actionLabel: 'Hoàn tác',
      onAction: () => notifier.addToCart(item.product, offer: item.offer),
    );
  }

  void _buy(BuildContext context, DealCartItem item) {
    AppSnackbar.show(
      context,
      'Bản demo: chuyển tới ${item.offer.marketplace.name} để mua ${item.product.name}',
      icon: Icons.open_in_new_rounded,
    );
  }

  Future<void> _checkout(BuildContext context, List<DealCartItem> items) {
    final byMarketplace = <Marketplace, List<DealCartItem>>{};
    for (final item in items) {
      byMarketplace.putIfAbsent(item.offer.marketplace, () => []).add(item);
    }
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chốt deal theo từng sàn', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(
                'Bản demo: đơn hàng được đặt trực tiếp trên từng sàn thương mại điện tử.',
                style: AppTextStyles.small,
              ),
              AppSpacing.gapLg,
              for (final entry in byMarketplace.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                  title: Text(entry.key.name),
                  subtitle: Text('${entry.value.length} sản phẩm'),
                  trailing: Text(
                    Formatters.price(entry.value.fold(0, (sum, i) => sum + i.subtotal)),
                    style: AppTextStyles.title.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                  ),
                ),
              AppSpacing.gapMd,
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đã hiểu')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(dealCartProvider);
    final summary = ref.watch(dealCartSummaryProvider);
    final items = cart.value ?? const <DealCartItem>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'Giỏ Hời (${items.length})',
              onBack: () => context.go(AppRoutes.home),
              actions: [
                if (items.isNotEmpty)
                  IconButton(
                    tooltip: 'Xóa tất cả',
                    onPressed: () => _confirmClear(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.text),
                  ),
              ],
            ),
            Expanded(
              child: cart.when(
                skipLoadingOnRefresh: true,
                loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.screen), child: ProductListSkeleton()),
                error: (error, _) =>
                    ErrorState(message: error.toString(), onRetry: () => ref.invalidate(dealCartProvider)),
                data: (items) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: ref.read(dealCartProvider.notifier).refresh,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 420,
                              child: EmptyState(
                                icon: Icons.shopping_cart_outlined,
                                title: 'Giỏ hời đang trống',
                                message: 'Thêm sản phẩm từ trang chi tiết để so sánh và chốt deal.',
                                actionLabel: 'Khám phá deal',
                                onAction: () => context.go(AppRoutes.home),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.xs,
                            AppSpacing.screen,
                            AppSpacing.lg,
                          ),
                          children: [
                            for (final item in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: DealCartItemCard(
                                  item: item,
                                  onQuantityChanged: (q) =>
                                      ref.read(dealCartProvider.notifier).updateQuantity(item.id, q),
                                  onRemove: () => _remove(context, ref, item),
                                  onBuy: () => _buy(context, item),
                                ),
                              ),
                            if (summary.aiSaving > 0)
                              AiInsightCard(
                                title: '${AppStrings.aiName} gợi ý',
                                icon: Icons.lightbulb_outline_rounded,
                                trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                child: Text.rich(
                                  TextSpan(
                                    style: AppTextStyles.body,
                                    children: [
                                      const TextSpan(text: 'Bạn có thể tiết kiệm khoảng '),
                                      TextSpan(
                                        text: Formatters.price(summary.aiSaving),
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                                      ),
                                      const TextSpan(text: ' nếu mua theo đề xuất này so với sàn đắt nhất.'),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            if (items.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.md, AppSpacing.screen, AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.card, boxShadow: AppShadows.bottomBar),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tổng tạm tính (${summary.itemCount} sản phẩm)', style: AppTextStyles.small),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Formatters.price(summary.total), style: AppTextStyles.display),
                    ),
                    if (summary.savedVsOriginal > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Đã tiết kiệm: ${Formatters.price(summary.savedVsOriginal)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    AppSpacing.gapMd,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _checkout(context, items),
                        child: const Text('🔥 Chốt deal ngay'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
