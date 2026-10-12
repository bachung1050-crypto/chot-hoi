import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../utils/formatters.dart';

class RatingWidget extends StatelessWidget {
  const RatingWidget({super.key, required this.rating, this.reviewCount, this.showReviewWord = false, this.size = 14});

  final double rating;
  final int? reviewCount;
  final bool showReviewWord;
  final double size;

  @override
  Widget build(BuildContext context) {
    final count = reviewCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: AppColors.star),
        const SizedBox(width: 2),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: rating.toStringAsFixed(1),
                  style: AppTextStyles.label.copyWith(fontSize: size - 1),
                ),
                if (count != null)
                  TextSpan(
                    text: ' (${Formatters.compact(count)})${showReviewWord ? ' đánh giá' : ''}',
                    style: AppTextStyles.caption.copyWith(fontSize: size - 2),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
