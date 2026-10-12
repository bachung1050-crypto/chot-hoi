import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/price_history.dart';
import '../../../models/product.dart';

/// "Lịch sử giá 90 ngày": red line chart with a "Hiện tại" bubble on the latest point.
class PriceHistoryCard extends StatelessWidget {
  const PriceHistoryCard({super.key, required this.product});

  static const int _days = 90;
  static const double _chartHeight = 130;
  static const double _topInset = 52;
  static const double _bottomInset = 10;

  final Product product;

  @override
  Widget build(BuildContext context) {
    final points = product.historyForDays(_days);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lịch sử giá $_days ngày', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
        AppSpacing.gapSm,
        SizedBox(
          height: _chartHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PriceLinePainter(points: points, topInset: _topInset, bottomInset: _bottomInset),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.brSm,
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatters.price(product.currentPrice),
                        style: AppTextStyles.caption.copyWith(color: AppColors.text, fontWeight: FontWeight.w800),
                      ),
                      Text('Hiện tại', style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontSize: 10)),
                    ],
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

class _PriceLinePainter extends CustomPainter {
  _PriceLinePainter({required this.points, required this.topInset, required this.bottomInset});

  final List<PriceHistoryPoint> points;
  final double topInset;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final prices = points.map((p) => p.price).toList();
    final minPrice = prices.reduce(math.min).toDouble();
    final maxPrice = prices.reduce(math.max).toDouble();
    final span = math.max(1.0, maxPrice - minPrice);
    final chartHeight = size.height - topInset - bottomInset;

    Offset at(int i) =>
        Offset(size.width * i / (points.length - 1), topInset + chartHeight * (1 - (prices[i] - minPrice) / span));

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }

    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.danger.withValues(alpha: 0.16), AppColors.danger.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    final last = at(points.length - 1);
    canvas
      ..drawCircle(last, 6, Paint()..color = AppColors.danger.withValues(alpha: 0.2))
      ..drawCircle(last, 3.5, Paint()..color = AppColors.danger);
  }

  @override
  bool shouldRepaint(_PriceLinePainter oldDelegate) => oldDelegate.points != points;
}
