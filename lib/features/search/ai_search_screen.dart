import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ai_search_bar.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/chot_hoi_mascot.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_horizontal_card.dart';
import '../../models/product_filter.dart';
import '../profile/providers/profile_providers.dart';
import 'filter_screen.dart';
import 'providers/ai_search_controller.dart';
import 'widgets/filter_chips.dart';
import 'widgets/result_summary_card.dart';
import 'widgets/search_steps.dart';

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key, this.initialQuery});

  /// Optional `?q=` query that starts a search when the screen opens.
  final String? initialQuery;

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty && initial != ref.read(aiSearchProvider).query) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(initial));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    _focusNode.unfocus();
    _controller.clear();
    ref.read(aiSearchProvider.notifier).searchProducts(query);
  }

  Future<void> _openFilter(AiSearchState state) async {
    final result = await context.push<ProductFilter>(
      AppRoutes.filter,
      extra: FilterScreenArgs(products: state.allProducts, initial: state.filter),
    );
    if (result != null) ref.read(aiSearchProvider.notifier).applyFilter(result);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSearchProvider);
    final isIdle = state.status == AiSearchStatus.idle;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0, -0.2),
            colors: [AppColors.aiLight, AppColors.background],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppHeader(
                title: 'Tìm kiếm AI',
                onBack: () => isIdle ? context.go(AppRoutes.home) : ref.read(aiSearchProvider.notifier).reset(),
                actions: [
                  PopupMenuButton<_SearchMenuAction>(
                    tooltip: 'Tuỳ chọn',
                    icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textTertiary),
                    onSelected: (action) => switch (action) {
                      _SearchMenuAction.grid => context.push(
                        '${AppRoutes.results}?q=${Uri.encodeQueryComponent(state.query)}',
                      ),
                      _SearchMenuAction.reset => ref.read(aiSearchProvider.notifier).reset(),
                    },
                    itemBuilder: (_) => [
                      if (state.status == AiSearchStatus.success)
                        const PopupMenuItem(value: _SearchMenuAction.grid, child: Text('Xem dạng lưới')),
                      const PopupMenuItem(value: _SearchMenuAction.reset, child: Text('Tìm kiếm mới')),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isIdle
                      ? _IdleView(key: const ValueKey('idle'), onSearch: _search)
                      : _ConversationView(
                          key: ValueKey(state.query),
                          state: state,
                          onOpenFilter: () => _openFilter(state),
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
                color: AppColors.background,
                child: AiSearchBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: AppStrings.aiSearchHint,
                  onSubmitted: _search,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SearchMenuAction { grid, reset }

class _IdleView extends ConsumerWidget {
  const _IdleView({super.key, required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(aiSuggestionsProvider).value ?? const [];
    final history = ref.watch(searchHistoryProvider).value ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xl),
      children: [
        Center(child: const ChotHoiMascot(size: 92)),
        AppSpacing.gapMd,
        Text('Bạn cần tìm gì hôm nay?', textAlign: TextAlign.center, style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(
          '${AppStrings.aiName} sẽ so giá nhiều sàn, đọc đánh giá và chọn ra sản phẩm đáng mua nhất.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySecondary,
        ),
        AppSpacing.gapXl,
        Text('Gợi ý cho bạn', style: AppTextStyles.h3),
        AppSpacing.gapSm,
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: AppColors.card,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brMd,
                side: BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.ai, size: 20),
                title: Text(suggestion, style: AppTextStyles.body),
                trailing: const Icon(Icons.north_west_rounded, size: 16, color: AppColors.textTertiary),
                onTap: () => onSearch(suggestion),
              ),
            ),
          ),
        if (history.isNotEmpty) ...[
          AppSpacing.gapLg,
          Text('Tìm kiếm gần đây', style: AppTextStyles.h3),
          AppSpacing.gapSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in history)
                QuickFilterChip(label: item, icon: Icons.history_rounded, selected: false, onTap: () => onSearch(item)),
            ],
          ),
        ],
      ],
    );
  }
}

class _ConversationView extends ConsumerWidget {
  const _ConversationView({super.key, required this.state, required this.onOpenFilter});

  final AiSearchState state;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(aiSearchProvider.notifier);
    final result = state.result;
    final products = state.visibleProducts;

    final header = <Widget>[
      UserQueryBubble(query: state.query),
      AppSpacing.gapLg,
      SearchSteps(completedSteps: state.completedSteps, isLoading: state.status == AiSearchStatus.loading),
    ];

    if (state.status == AiSearchStatus.loading) {
      return ListView(padding: AppSpacing.screenPadding, children: header);
    }

    if (state.status == AiSearchStatus.error) {
      return ListView(
        padding: AppSpacing.screenPadding,
        children: [
          ...header,
          AppSpacing.gapLg,
          ErrorState(message: state.errorMessage ?? 'Đã có lỗi xảy ra.', onRetry: controller.retry),
        ],
      );
    }

    if (result == null || state.status == AiSearchStatus.empty) {
      return ListView(
        padding: AppSpacing.screenPadding,
        children: [
          ...header,
          AppSpacing.gapLg,
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Chưa tìm thấy sản phẩm phù hợp',
            message: 'Thử mô tả khác, ví dụ: "tai nghe chống ồn dưới 10 triệu".',
          ),
        ],
      );
    }

    final intent = result.intent;
    final budget = intent.maxPrice;
    final purpose = intent.purpose;
    final brandChips = intent.brands.isNotEmpty
        ? intent.brands
        : state.allProducts.map((p) => p.brand).toSet().take(2).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
      children: [
        ...header,
        AppSpacing.gapSm,
        ResultSummaryCard(intent: intent, count: state.allProducts.length),
        AppSpacing.gapMd,
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (budget != null) ...[
                      QuickFilterChip(
                        label: 'Dưới ${Formatters.millions(budget)}',
                        selectedFill: AppColors.ai,
                        selected: state.filter.maxPrice != null,
                        onTap: controller.toggleBudget,
                      ),
                      AppSpacing.gapSm,
                    ],
                    for (final brand in brandChips) ...[
                      QuickFilterChip(
                        label: brand,
                        selectedFill: AppColors.ai,
                        selected: state.filter.brands.contains(brand),
                        onTap: () => controller.toggleBrand(brand),
                      ),
                      AppSpacing.gapSm,
                    ],
                    if (purpose != null)
                      QuickFilterChip(
                        label: AppStrings.purposeLabels[purpose] ?? purpose,
                        selectedFill: AppColors.ai,
                        selected: state.filter.purpose == purpose,
                        onTap: () => controller.togglePurpose(purpose),
                      ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapSm,
            FilterIconButton(activeCount: state.filter.activeCount, onTap: onOpenFilter),
          ],
        ),
        AppSpacing.gapMd,
        SortTabs(selected: state.filter.sort, onChanged: controller.setSort),
        AppSpacing.gapLg,
        if (products.isEmpty)
          EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'Không còn sản phẩm nào',
            message: 'Bộ lọc hiện tại quá chặt, hãy bỏ bớt điều kiện.',
            actionLabel: 'Bỏ lọc',
            onAction: () => controller.applyFilter(ProductFilter(sort: state.filter.sort)),
          )
        else
          for (var i = 0; i < products.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ProductHorizontalCard(
                product: products[i],
                heroTag: 'ai-${products[i].id}',
                elevated: true,
                rank: state.filter.sort == ProductSort.recommended && i < 3 ? i + 1 : null,
              ),
            ),
      ],
    );
  }
}
