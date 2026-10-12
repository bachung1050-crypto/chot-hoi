import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/tap_scale.dart';

/// Full-width orange gradient call to action.
class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.showChevron = false,
    this.height = 52,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool showChevron;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.98,
      onTap: onPressed,
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.brMd,
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.onDark, size: 22),
            AppSpacing.gapSm,
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button.copyWith(color: AppColors.onDark, fontSize: 16),
              ),
            ),
            if (showChevron) ...[
              AppSpacing.gapSm,
              const Icon(Icons.chevron_right_rounded, color: AppColors.onDark, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lavender outlined secondary action, e.g. "Chọn từ thư viện".
class SoftActionButton extends StatelessWidget {
  const SoftActionButton({super.key, required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.98,
      onTap: onPressed,
      child: Container(
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.aiLight,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.ai.withValues(alpha: 0.25)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.aiDeep, size: 22),
              AppSpacing.gapSm,
              Text(label, maxLines: 1, style: AppTextStyles.title.copyWith(color: AppColors.aiDeep)),
            ],
          ),
        ),
      ),
    );
  }
}

/// White camera-style corner brackets drawn over a photo.
class ViewfinderCorners extends StatelessWidget {
  const ViewfinderCorners({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _CornersPainter(), child: SizedBox.expand());
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 18.0;
    const length = 34.0;
    const radius = 12.0;
    final paint = Paint()
      ..color = AppColors.onDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final left = inset;
    final top = inset;
    final right = size.width - inset;
    final bottom = size.height - inset;

    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x, y + dy * length)
      ..lineTo(x, y + dy * radius)
      ..quadraticBezierTo(x, y, x + dx * radius, y)
      ..lineTo(x + dx * length, y);

    canvas
      ..drawPath(corner(left, top, 1, 1), paint)
      ..drawPath(corner(right, top, -1, 1), paint)
      ..drawPath(corner(left, bottom, 1, -1), paint)
      ..drawPath(corner(right, bottom, -1, -1), paint);
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}

/// "Chụp ảnh — Thêm yêu cầu — Phân tích" progress indicator.
class ImageSearchStepper extends StatelessWidget {
  const ImageSearchStepper({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const stages = AppStrings.imageSearchStages;
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              if (i > 0)
                Expanded(child: Container(height: 2, color: i <= currentIndex ? AppColors.ai : AppColors.border)),
              _StepDot(done: i < currentIndex, active: i == currentIndex),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < stages.length; i++)
              Expanded(
                child: Text(
                  stages[i],
                  textAlign: switch (i) {
                    0 => TextAlign.left,
                    _ when i == stages.length - 1 => TextAlign.right,
                    _ => TextAlign.center,
                  },
                  style: AppTextStyles.caption.copyWith(
                    color: i == currentIndex ? AppColors.text : AppColors.textSecondary,
                    fontWeight: i == currentIndex ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.active});

  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.ai : AppColors.card,
        border: Border.all(color: done || active ? AppColors.ai : AppColors.border, width: 2),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.onDark)
          : active
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppColors.ai, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

/// Vertical list of analysis steps with check / spinner / pending markers.
class AnalysisStepList extends StatelessWidget {
  const AnalysisStepList({super.key, required this.steps, required this.completed});

  final List<String> steps;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: i < completed
                      ? const DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.ai, shape: BoxShape.circle),
                          child: Icon(Icons.check_rounded, size: 16, color: AppColors.onDark),
                        )
                      : i == completed
                      ? const Padding(
                          padding: EdgeInsets.all(2),
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ai),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border, width: 2),
                          ),
                        ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Text(
                    steps[i],
                    style: AppTextStyles.body.copyWith(
                      color: i <= completed ? AppColors.text : AppColors.textTertiary,
                      fontWeight: i == completed ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
