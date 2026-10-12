import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../image_search/widgets/image_search_widgets.dart';

/// Home entry point for the "Tìm bằng hình ảnh" flow.
class ImageSearchCard extends StatelessWidget {
  const ImageSearchCard({super.key, required this.onCapture, required this.onPickLibrary});

  final VoidCallback onCapture;
  final VoidCallback onPickLibrary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.aiLight, AppColors.primaryLight],
        ),
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.ai.withValues(alpha: 0.22), width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    AppAssets.imageSearchHero,
                    width: 104,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 104, height: 100, child: Icon(Icons.photo_camera_rounded, size: 48)),
                  ),
                  const Positioned(
                    top: -6,
                    left: -4,
                    child: Icon(Icons.auto_awesome_rounded, color: AppColors.warning, size: 20),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.imageSearchTitle,
                      style: AppTextStyles.h3.copyWith(color: AppColors.ai, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(AppStrings.imageSearchSubtitle, style: AppTextStyles.title),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          for (var i = 0; i < AppStrings.imageSearchFlow.length; i++) ...[
                            if (i > 0)
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  child: Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.ai),
                                ),
                              ),
                            TextSpan(text: AppStrings.imageSearchFlow[i]),
                          ],
                        ],
                      ),
                      style: AppTextStyles.caption.copyWith(color: AppColors.text, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          GradientActionButton(
            label: 'Chụp ngay',
            icon: Icons.photo_camera_rounded,
            showChevron: true,
            height: 50,
            onPressed: onCapture,
          ),
          AppSpacing.gapSm,
          SoftActionButton(label: 'Chọn từ thư viện', icon: Icons.photo_library_rounded, onPressed: onPickLibrary),
        ],
      ),
    );
  }
}
