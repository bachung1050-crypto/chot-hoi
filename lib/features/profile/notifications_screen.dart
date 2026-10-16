import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/app_notification.dart';
import '../auth/auth_guard.dart';
import '../auth/providers/auth_providers.dart';
import '../search/widgets/filter_chips.dart';
import 'providers/profile_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _group;

  void _open(AppNotification notification) {
    if (!notification.isRead) {
      runUserAction(context, ref, () => ref.read(notificationsProvider.notifier).markAsRead(notification.id));
    }
    final productId = notification.productId;
    if (productId != null) context.push(AppRoutes.product(productId));
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final all = notifications.value ?? const <AppNotification>[];
    final groups = {for (final type in NotificationType.values) type.groupLabel}.toList();
    final visible = _group == null ? all : all.where((n) => n.type.groupLabel == _group).toList();
    final signedIn = ref.watch(isSignedInProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    if (!signedIn) {
      return const Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(title: 'Thông báo'),
              Expanded(
                child: LoginRequiredState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Đăng nhập để xem thông báo',
                  message: 'Thông báo về giá và deal được gửi theo tài khoản của bạn.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Thông báo',
              actions: [
                if (unread > 0)
                  IconButton(
                    tooltip: 'Đánh dấu tất cả đã đọc',
                    onPressed: () =>
                        runUserAction(context, ref, () => ref.read(notificationsProvider.notifier).markAllAsRead()),
                    icon: const Icon(Icons.done_all_rounded, color: AppColors.text),
                  ),
              ],
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.screenPadding,
                children: [
                  QuickFilterChip(
                    label: 'Tất cả',
                    selected: _group == null,
                    onTap: () => setState(() => _group = null),
                  ),
                  for (final group in groups) ...[
                    AppSpacing.gapSm,
                    QuickFilterChip(
                      label: group,
                      selected: _group == group,
                      onTap: () => setState(() => _group = group),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: notifications.when(
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    ErrorState(message: error.toString(), onRetry: () => ref.invalidate(notificationsProvider)),
                data: (_) => RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: ref.read(notificationsProvider.notifier).refresh,
                  child: visible.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 420,
                              child: EmptyState(
                                icon: Icons.notifications_none_rounded,
                                title: 'Không có thông báo',
                                message: 'Thông báo về giá và deal mới sẽ xuất hiện ở đây.',
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => AppSpacing.gapSm,
                          itemBuilder: (context, index) =>
                              _NotificationTile(notification: visible[index], onTap: () => _open(visible[index])),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (notification.type) {
      NotificationType.priceDrop => (Icons.local_fire_department_rounded, AppColors.primary, AppColors.primaryLight),
      NotificationType.deal => (Icons.local_offer_rounded, AppColors.warning, AppColors.warningLight),
      NotificationType.restock => (Icons.inventory_2_rounded, AppColors.success, AppColors.successLight),
      NotificationType.system => (Icons.auto_awesome_rounded, AppColors.ai, AppColors.aiLight),
    };
    return Material(
      color: notification.isRead ? AppColors.card : AppColors.primaryLight.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: background, borderRadius: AppRadius.brMd),
                child: Icon(icon, color: color),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(notification.timeLabel, style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message, style: AppTextStyles.small),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
