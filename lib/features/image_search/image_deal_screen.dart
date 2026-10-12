import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/tap_scale.dart';
import '../../models/image_search_result.dart';
import '../cart/providers/deal_cart_provider.dart';
import '../profile/providers/profile_providers.dart';
import 'providers/image_search_controller.dart';
import 'widgets/image_search_widgets.dart';

/// Step 5: AI verdict, reasons and a summary of the image search.
class ImageDealScreen extends ConsumerWidget {
  const ImageDealScreen({super.key});

  Future<void> _addToCart(BuildContext context, WidgetRef ref, ImageSearchResult result) async {
    final added = await ref.read(dealCartProvider.notifier).addToCart(result.product);
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      added ? 'Đã thêm vào Giỏ hời' : 'Sản phẩm đã có trong Giỏ hời',
      icon: Icons.shopping_cart_checkout_rounded,
      actionLabel: 'Xem giỏ',
      onAction: () => context.go(AppRoutes.cart),
    );
  }

  Future<void> _trackPrice(BuildContext context, WidgetRef ref, ImageSearchResult result) async {
    final alert = await ref.read(priceAlertsProvider.notifier).trackPrice(result.product);
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      'Sẽ báo khi giá về ${Formatters.price(alert.targetPrice)}',
      icon: Icons.notifications_active_rounded,
      actionLabel: 'Xem',
      onAction: () => context.push(AppRoutes.alerts),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(imageSearchProvider).result;

    if (result == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'Đánh giá deal'),
              Expanded(
                child: EmptyState(
                  icon: Icons.image_search_rounded,
                  title: 'Chưa có kết quả',
                  message: 'Hãy chụp hoặc chọn một ảnh sản phẩm để bắt đầu.',
                  actionLabel: 'Tìm bằng hình ảnh',
                  onAction: () => context.pushReplacement(AppRoutes.imageSearch),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final product = result.product;
    final request = result.request.isEmpty ? 'Không có yêu cầu thêm' : result.request;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Đánh giá deal'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.lg),
                children: [
                  _VerdictCard(result: result),
                  AppSpacing.gapXl,
                  Text('Lý do AI đánh giá', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
                  AppSpacing.gapSm,
                  for (final reason in result.reasons)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          AppSpacing.gapSm,
                          Expanded(child: Text(reason, style: AppTextStyles.body.copyWith(height: 1.35))),
                        ],
                      ),
                    ),
                  AppSpacing.gapXl,
                  Text('Tóm tắt kết quả', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
                  AppSpacing.gapSm,
                  _SummaryRow(icon: Icons.headphones_rounded, label: 'Sản phẩm nhận diện', value: product.name),
                  _SummaryRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Số sản phẩm tìm thấy',
                    value: '${result.resultCount} sản phẩm',
                  ),
                  _SummaryRow(
                    icon: Icons.payments_outlined,
                    label: 'Khoảng giá',
                    value:
                        '${Formatters.price(result.lowestOfferPrice)} - ${Formatters.price(result.highestOfferPrice)}',
                  ),
                  _SummaryRow(icon: Icons.chat_bubble_outline_rounded, label: 'Yêu cầu của bạn', value: request),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
              child: Column(
                children: [
                  GradientActionButton(
                    label: 'Xem chi tiết sản phẩm',
                    icon: Icons.open_in_new_rounded,
                    showChevron: true,
                    onPressed: () => context.push(AppRoutes.product(product.id), extra: 'image-deal-${product.id}'),
                  ),
                  AppSpacing.gapSm,
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineAction(
                          icon: Icons.add_shopping_cart_rounded,
                          label: 'Thêm vào Deal Cart',
                          onTap: () => _addToCart(context, ref, result),
                        ),
                      ),
                      AppSpacing.gapSm,
                      Expanded(
                        child: _OutlineAction(
                          icon: Icons.notifications_none_rounded,
                          label: 'Theo dõi giá',
                          onTap: () => _trackPrice(context, ref, result),
                        ),
                      ),
                    ],
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

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.result});

  final ImageSearchResult result;

  @override
  Widget build(BuildContext context) {
    final product = result.product;
    final emphasis = AppTextStyles.body.copyWith(color: AppColors.success, fontWeight: FontWeight.w800);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.successLight, AppColors.card],
        ),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 40),
              AppSpacing.gapSm,
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    product.verdict.label.toUpperCase(),
                    style: AppTextStyles.h1.copyWith(color: AppColors.success, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              AppSpacing.gapSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.brMd,
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  children: [
                    Text('Chốt Hời Score', style: AppTextStyles.caption.copyWith(color: AppColors.text)),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${product.chotHoiScore}', style: AppTextStyles.h1.copyWith(height: 1.1)),
                          TextSpan(
                            text: '/100',
                            style: AppTextStyles.label.copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          _InsightRow(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            text: TextSpan(
              children: [
                const TextSpan(text: 'Giá hiện tại đang '),
                TextSpan(text: 'thấp hơn', style: emphasis),
                const TextSpan(text: ' khoảng '),
                TextSpan(text: '${result.betterThanAveragePercent}%', style: emphasis),
                const TextSpan(text: ' so với mức giá trung bình 90 ngày.'),
              ],
            ),
          ),
          if (product.saving > 0) ...[
            AppSpacing.gapSm,
            _InsightRow(
              icon: Icons.savings_rounded,
              iconColor: AppColors.warning,
              text: TextSpan(
                children: [
                  const TextSpan(text: 'Bạn có thể tiết kiệm khoảng '),
                  TextSpan(text: Formatters.price(product.saving), style: emphasis),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.icon, required this.iconColor, required this.text});

  final IconData icon;
  final Color iconColor;
  final TextSpan text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 26),
        AppSpacing.gapMd,
        Expanded(child: Text.rich(text, style: AppTextStyles.body.copyWith(height: 1.4))),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          AppSpacing.gapSm,
          Expanded(
            flex: 5,
            child: Text(label, style: AppTextStyles.small.copyWith(color: AppColors.text)),
          ),
          AppSpacing.gapSm,
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.small.copyWith(color: AppColors.text, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.ai.withValues(alpha: 0.35)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.aiDeep, size: 20),
              const SizedBox(width: 6),
              Text(label, maxLines: 1, style: AppTextStyles.label.copyWith(color: AppColors.aiDeep)),
            ],
          ),
        ),
      ),
    );
  }
}
