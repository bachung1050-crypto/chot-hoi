import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/chot_hoi_mascot.dart';
import '../../core/widgets/empty_state.dart';
import 'providers/image_search_controller.dart';
import 'widgets/image_search_widgets.dart';

/// Step 3: animated progress while Chốt Hời AI "analyses" the photo.
class ImageAnalyzingScreen extends ConsumerWidget {
  const ImageAnalyzingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(imageSearchProvider.select((s) => s.status), (previous, next) {
      if (next == ImageSearchStatus.success) context.pushReplacement(AppRoutes.imageResult);
    });
    final state = ref.watch(imageSearchProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.aiBubble, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(title: '${AppStrings.aiName} đang phân tích...'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
                  children: [
                    const _AnalyzingHero(),
                    AppSpacing.gapLg,
                    if (state.status == ImageSearchStatus.error)
                      ErrorState(
                        message: state.errorMessage ?? 'Không thể phân tích hình ảnh.',
                        onRetry: ref.read(imageSearchProvider.notifier).analyze,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: AppRadius.brLg,
                          boxShadow: AppShadows.card,
                        ),
                        child: AnalysisStepList(steps: AppStrings.imageSearchSteps, completed: state.completedSteps),
                      ),
                    AppSpacing.gapLg,
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.brLg,
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 28),
                          AppSpacing.gapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mẹo nhỏ',
                                  style: AppTextStyles.title.copyWith(color: AppColors.ai, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStrings.imageSearchTip,
                                  style: AppTextStyles.small.copyWith(color: AppColors.text),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Mascot with floating product illustrations and a magnifier.
class _AnalyzingHero extends StatelessWidget {
  const _AnalyzingHero();

  @override
  Widget build(BuildContext context) {
    Widget bubble(String iconKey) => Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.85),
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.card,
      ),
      child: CategoryIcon(iconKey: iconKey, size: 42),
    );

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.ai.withValues(alpha: 0.18), Colors.transparent]),
            ),
          ),
          const ChotHoiMascot(size: 170),
          Positioned(top: 8, left: 24, child: bubble('headphones')),
          Positioned(top: 20, right: 20, child: bubble('laptop')),
          Positioned(bottom: 30, right: 12, child: bubble('fashion')),
          const Positioned(bottom: 36, right: 92, child: Icon(Icons.search_rounded, color: AppColors.ai, size: 54)),
          const Positioned(
            top: 70,
            left: 8,
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.warning, size: 22),
          ),
          const Positioned(top: 4, right: 110, child: Icon(Icons.auto_awesome_rounded, color: AppColors.ai, size: 18)),
        ],
      ),
    );
  }
}
