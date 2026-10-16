import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/chot_hoi_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../models/user_profile.dart';
import '../../repositories/repository_providers.dart';
import '../auth/auth_guard.dart';
import '../cart/providers/deal_cart_provider.dart';
import '../saved/providers/saved_products_provider.dart';
import '../search/providers/search_history_provider.dart';
import 'providers/profile_providers.dart';
import 'widgets/profile_edit_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _comingSoon(BuildContext context, String feature) {
    AppSnackbar.show(context, '$feature sẽ có trong phiên bản tiếp theo', icon: Icons.info_outline_rounded);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) AppSnackbar.show(context, 'Đã đăng xuất', icon: Icons.logout_rounded);
    } on DataFailure catch (e) {
      if (context.mounted) AppSnackbar.show(context, e.message, icon: Icons.error_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final alertCount = ref.watch(priceAlertsProvider).value?.length ?? 0;
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              title: 'Cá nhân',
              onBack: () => context.go(AppRoutes.home),
              actions: [
                IconButton(
                  tooltip: 'Cài đặt',
                  onPressed: () {
                    final user = profile.value;
                    user == null ? showLoginPrompt(context) : showProfileEditSheet(context, user);
                  },
                  icon: const Icon(Icons.settings_outlined, color: AppColors.text),
                ),
              ],
            ),
            Expanded(
              child: profile.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    ErrorState(message: error.toString(), onRetry: () => ref.invalidate(profileProvider)),
                data: (user) => user == null
                    ? const LoginRequiredState(
                        icon: Icons.person_outline_rounded,
                        title: 'Bạn chưa đăng nhập',
                        message: 'Đăng nhập để xem sản phẩm đã lưu, giỏ hời và cảnh báo giá của bạn.',
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.sm,
                          AppSpacing.screen,
                          AppSpacing.xl,
                        ),
                        children: [
                          _ProfileHeader(user: user, onTap: () => showProfileEditSheet(context, user)),
                          AppSpacing.gapLg,
                          _StatsRow(
                            stats: [
                              (
                                label: 'Đã lưu',
                                value: ref.watch(savedCountProvider),
                                route: AppRoutes.saved,
                                push: false,
                              ),
                              (label: 'Cảnh báo giá', value: alertCount, route: AppRoutes.alerts, push: true),
                              (
                                label: 'Tìm kiếm',
                                value: ref.watch(searchCountProvider).value ?? 0,
                                route: AppRoutes.search,
                                push: false,
                              ),
                              (
                                label: 'Giỏ hời',
                                value: ref.watch(dealCartCountProvider),
                                route: AppRoutes.cart,
                                push: false,
                              ),
                            ],
                          ),
                          AppSpacing.gapLg,
                          _PremiumCard(
                            isPremium: user.isPremium,
                            onTap: () => _comingSoon(context, 'Chốt Hời Premium'),
                          ),
                          AppSpacing.gapLg,
                          _MenuGroup(
                            items: [
                              _MenuItem(
                                Icons.favorite_border_rounded,
                                'Sản phẩm đã lưu',
                                () => context.go(AppRoutes.saved),
                              ),
                              _MenuItem(
                                Icons.notifications_active_outlined,
                                'Cảnh báo giá',
                                () => context.push(AppRoutes.alerts),
                              ),
                              _MenuItem(
                                Icons.notifications_none_rounded,
                                'Thông báo',
                                () => context.push(AppRoutes.notifications),
                                badge: unread,
                              ),
                              _MenuItem(Icons.history_rounded, 'Lịch sử tìm kiếm', () => context.go(AppRoutes.search)),
                              _MenuItem(Icons.shopping_cart_outlined, 'Giỏ hời', () => context.go(AppRoutes.cart)),
                            ],
                          ),
                          AppSpacing.gapMd,
                          _MenuGroup(
                            items: [
                              _MenuItem(
                                Icons.help_outline_rounded,
                                'Trợ giúp & phản hồi',
                                () => _comingSoon(context, 'Trợ giúp'),
                              ),
                              _MenuItem(
                                Icons.shield_outlined,
                                'Chính sách bảo mật',
                                () => _comingSoon(context, 'Chính sách'),
                              ),
                              _MenuItem(
                                Icons.info_outline_rounded,
                                'Về ${AppStrings.appName}',
                                () => showAboutDialog(
                                  context: context,
                                  applicationName: AppStrings.appName,
                                  applicationVersion: AppStrings.version,
                                  applicationIcon: const ChotHoiLogo(size: 36),
                                  children: [const Text(AppStrings.tagline)],
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.gapMd,
                          _MenuGroup(
                            items: [_MenuItem(Icons.logout_rounded, 'Đăng xuất', () => _signOut(context, ref))],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onTap});

  final UserProfile user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (user.phone case final phone? when phone.isNotEmpty) phone,
      ?languageLabel(user.language),
      if (user.isPremium) 'Premium',
    ].join(' · ');
    return InkWell(
      borderRadius: AppRadius.brLg,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
            child: ClipOval(
              child: AppNetworkImage(url: user.avatarUrl, fallbackIcon: Icons.person_rounded, iconSize: 32),
            ),
          ),
          AppSpacing.gapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.h2),
                const SizedBox(height: 2),
                Text(user.email, style: AppTextStyles.bodySecondary, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (details.isNotEmpty)
                  Text(details, style: AppTextStyles.small, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef _Stat = ({String label, int value, String route, bool push});

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final stat in stats)
            Expanded(
              child: InkWell(
                borderRadius: AppRadius.brMd,
                onTap: () => stat.push ? context.push(stat.route) : context.go(stat.route),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      Text(Formatters.count(stat.value), style: AppTextStyles.h2),
                      const SizedBox(height: 2),
                      Text(stat.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.isPremium, required this.onTap});

  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.aiLight,
      borderRadius: AppRadius.brLg,
      child: InkWell(
        borderRadius: AppRadius.brLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(gradient: AppColors.aiGradient, borderRadius: AppRadius.brMd),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 26),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chốt Hời Premium',
                      style: AppTextStyles.title.copyWith(color: AppColors.ai, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPremium
                          ? 'Bạn đang là thành viên Premium'
                          : 'Mở khóa sức mạnh của AI, cảnh báo giá không giới hạn',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ai),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap, {this.badge = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: 56),
            ListTile(
              leading: Icon(items[i].icon, size: 22),
              title: Text(items[i].label, style: AppTextStyles.body),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (items[i].badge > 0) Badge(backgroundColor: AppColors.primary, label: Text('${items[i].badge}')),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
              onTap: items[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}
