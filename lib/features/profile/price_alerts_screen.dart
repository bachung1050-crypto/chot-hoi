import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../mock/mock_categories.dart';
import '../../models/price_alert.dart';
import '../auth/auth_guard.dart';
import '../auth/providers/auth_providers.dart';
import 'providers/profile_providers.dart';
import 'widgets/price_alert_sheet.dart';

class PriceAlertsScreen extends ConsumerWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(priceAlertsProvider);
    final items = alerts.value ?? const <PriceAlert>[];
    final signedIn = ref.watch(isSignedInProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Cảnh báo giá (${items.length})'),
            Expanded(
              child: !signedIn
                  ? const LoginRequiredState(
                      icon: Icons.notifications_off_outlined,
                      title: 'Đăng nhập để theo dõi giá',
                      message: 'Cảnh báo giá được lưu theo tài khoản của bạn.',
                    )
                  : alerts.when(
                      skipLoadingOnRefresh: true,
                      loading: () => const Padding(padding: AppSpacing.screenPadding, child: ProductListSkeleton()),
                      error: (error, _) =>
                          ErrorState(message: error.toString(), onRetry: () => ref.invalidate(priceAlertsProvider)),
                      data: (items) => items.isEmpty
                          ? const EmptyState(
                              icon: Icons.notifications_off_outlined,
                              title: 'Chưa có cảnh báo giá',
                              message: 'Đặt giá mục tiêu để được báo khi sản phẩm giảm giá.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screen,
                                AppSpacing.xs,
                                AppSpacing.screen,
                                AppSpacing.lg,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, _) => AppSpacing.gapMd,
                              itemBuilder: (context, index) => _AlertTile(
                                alert: items[index],
                                onTap: () =>
                                    showPriceAlertSheet(context, ref, items[index].product, showProductLink: true),
                                onChanged: (enabled) => runUserAction(
                                  context,
                                  ref,
                                  () => ref
                                      .read(priceAlertsProvider.notifier)
                                      .setEnabled(items[index].id, enabled: enabled),
                                ),
                              ),
                            ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => AppSnackbar.show(
                    context,
                    'Mở một sản phẩm và bấm 🔔 để đặt giá mục tiêu',
                    icon: Icons.add_alert_outlined,
                    actionLabel: 'Tìm sản phẩm',
                    onAction: () => context.go(AppRoutes.search),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm cảnh báo giá'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onTap, required this.onChanged});

  final PriceAlert alert;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final product = alert.product;
    final icon = AppIcons.category(MockCategories.byId(product.categoryId).iconKey);

    return InkWell(
      borderRadius: AppRadius.brLg,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 64,
              child: Hero(
                tag: 'alert-${product.id}',
                child: AppNetworkImage(
                  url: product.imageUrl,
                  fallbackIcon: icon,
                  iconSize: 24,
                  borderRadius: AppRadius.brMd,
                ),
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.small,
                      children: [
                        const TextSpan(text: 'Mục tiêu: '),
                        TextSpan(
                          text: Formatters.price(alert.targetPrice),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Hiện tại: ${Formatters.price(alert.currentPrice)}'
                    '${alert.offer == null ? '' : ' · ${alert.offer!.marketplace.name}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                  if (!alert.enabled) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Đã tạm dừng theo dõi',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w700),
                    ),
                  ] else if (alert.isReached) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Đã đạt giá mục tiêu 🎉',
                      style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            Switch(value: alert.enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
