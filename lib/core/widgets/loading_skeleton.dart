import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Placeholder rows shown while product lists load.
class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                SkeletonBox(width: 92, height: 92, radius: AppRadius.md),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 14),
                      AppSpacing.gapSm,
                      SkeletonBox(width: 120, height: 12),
                      AppSpacing.gapSm,
                      SkeletonBox(width: 90, height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Horizontal row of card placeholders for carousels.
class CarouselSkeleton extends StatelessWidget {
  const CarouselSkeleton({super.key, this.itemWidth = 136, this.height = 210});

  final double itemWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.screenPadding,
        itemCount: 3,
        separatorBuilder: (_, _) => AppSpacing.gapMd,
        itemBuilder: (_, _) => SkeletonBox(width: itemWidth, height: height, radius: AppRadius.lg),
      ),
    );
  }
}
