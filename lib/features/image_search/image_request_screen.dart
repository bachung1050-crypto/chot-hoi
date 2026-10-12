import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/tap_scale.dart';
import 'providers/image_search_controller.dart';
import 'widgets/image_search_widgets.dart';

/// Step 2: optional free-text / quick-chip requirements before the AI analysis.
class ImageRequestScreen extends ConsumerStatefulWidget {
  const ImageRequestScreen({super.key});

  @override
  ConsumerState<ImageRequestScreen> createState() => _ImageRequestScreenState();
}

class _ImageRequestScreenState extends ConsumerState<ImageRequestScreen> {
  late final TextEditingController _controller = TextEditingController(text: ref.read(imageSearchProvider).note);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() {
    FocusScope.of(context).unfocus();
    ref.read(imageSearchProvider.notifier).analyze();
    context.push(AppRoutes.imageAnalyzing);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageSearchProvider);
    final controller = ref.read(imageSearchProvider.notifier);
    final quickRequests = ref.watch(imageQuickRequestsProvider).value ?? const [];
    final imageUrl = state.imageUrl;

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Thêm yêu cầu'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.lg),
                children: [
                  const ImageSearchStepper(currentIndex: 1),
                  AppSpacing.gapLg,
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 96,
                        child: imageUrl == null
                            ? const DecoratedBox(
                                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: AppRadius.brMd),
                              )
                            : AppNetworkImage(
                                url: imageUrl,
                                borderRadius: AppRadius.brMd,
                                fallbackIcon: Icons.image_outlined,
                              ),
                      ),
                      AppSpacing.gapLg,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ảnh đã chọn', style: AppTextStyles.body.copyWith(color: AppColors.text)),
                            const SizedBox(height: 4),
                            TapScale(
                              onTap: () => context.pop(),
                              child: Text(
                                'Đổi ảnh',
                                style: AppTextStyles.title.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapXl,
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.ai, size: 22),
                      AppSpacing.gapSm,
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Thêm yêu cầu cho AI ',
                                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800),
                              ),
                              TextSpan(text: '(tùy chọn)', style: AppTextStyles.small),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhập hoặc nói nhu cầu để AI tìm sản phẩm phù hợp hơn với bạn.',
                    style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
                  ),
                  AppSpacing.gapMd,
                  TextField(
                    controller: _controller,
                    onChanged: controller.setNote,
                    minLines: 3,
                    maxLines: 4,
                    maxLength: AppStrings.imageRequestMaxLength,
                    style: AppTextStyles.body,
                    cursorColor: AppColors.ai,
                    decoration: InputDecoration(
                      hintText: AppStrings.imageRequestHint,
                      hintStyle: AppTextStyles.small.copyWith(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.brMd,
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: AppRadius.brMd,
                        borderSide: BorderSide(color: AppColors.ai),
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text('Gợi ý nhanh', style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700)),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final label in quickRequests)
                        _RequestChip(
                          label: label,
                          selected: state.quickRequests.contains(label),
                          onTap: () => controller.toggleQuickRequest(label),
                        ),
                    ],
                  ),
                  AppSpacing.gapLg,
                  const _VoiceInputCard(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
              child: GradientActionButton(
                label: 'Phân tích bằng AI',
                icon: Icons.auto_awesome_rounded,
                onPressed: _analyze,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestChip extends StatelessWidget {
  const _RequestChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(color: selected ? AppColors.ai : AppColors.aiLight, borderRadius: AppRadius.brSm),
        child: Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: selected ? AppColors.onDark : AppColors.aiDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// "Nhấn giữ để nói" voice card (UI only in this phase).
class _VoiceInputCard extends StatelessWidget {
  const _VoiceInputCard();

  static const List<double> _wave = [8, 14, 22, 12, 28, 18, 10, 24, 16, 9, 20, 13];

  @override
  Widget build(BuildContext context) {
    Widget bars() => Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final h in _wave)
            Container(
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.45),
                borderRadius: AppRadius.brPill,
              ),
            ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              bars(),
              AppSpacing.gapMd,
              GestureDetector(
                onLongPress: () =>
                    AppSnackbar.show(context, 'Nhập giọng nói sẽ có ở phiên bản sau', icon: Icons.mic_rounded),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppColors.onDark, size: 30),
                ),
              ),
              AppSpacing.gapMd,
              bars(),
            ],
          ),
          AppSpacing.gapMd,
          Text('Nhấn giữ để nói', style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
