import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/marketplace_logo.dart';
import '../../../models/marketplace.dart';
import '../../../models/price_history.dart';
import '../../../models/product.dart';

/// "Lịch sử giá 90 ngày": red line chart with a "Hiện tại" bubble on the latest point.
/// When several marketplaces have their own history, tabs switch between them.
class PriceHistoryCard extends StatefulWidget {
  const PriceHistoryCard({super.key, required this.product});

  final Product product;

  @override
  State<PriceHistoryCard> createState() => _PriceHistoryCardState();
}

class _PriceHistoryCardState extends State<PriceHistoryCard> {
  static const int _days = 90;
  static const double _chartHeight = 130;
  static const double _topInset = 52;
  static const double _bottomInset = 10;

  /// Selected marketplace id; null means the cheapest one.
  String? _selectedMarketplaceId;

  @override
  void didUpdateWidget(PriceHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) _selectedMarketplaceId = null;
  }

  static List<PriceHistoryPoint> _lastDays(List<PriceHistoryPoint> points) =>
      points.length <= _days ? points : points.sublist(points.length - _days);

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final tracked = product.sortedOffers.where((o) => o.priceHistory.isNotEmpty).toList();
    final selected =
        tracked.where((o) => o.marketplace.id == _selectedMarketplaceId).firstOrNull ?? tracked.firstOrNull;
    final points = selected == null ? product.historyForDays(_days) : _lastDays(selected.priceHistory);
    final currentPrice = selected?.price ?? product.currentPrice;
    final stats = PriceHistoryStats.fromPoints(points);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lịch sử giá $_days ngày', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w800)),
        AppSpacing.gapSm,
        if (tracked.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final offer in tracked) ...[
                  _MarketplaceTab(
                    offer: offer,
                    selected: offer == selected,
                    onTap: () => setState(() => _selectedMarketplaceId = offer.marketplace.id),
                  ),
                  if (offer != tracked.last) AppSpacing.gapSm,
                ],
              ],
            ),
          ),
          AppSpacing.gapSm,
        ],
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
                        Formatters.price(currentPrice),
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
        AppSpacing.gapSm,
        if (stats == null)
          Text('Chưa có dữ liệu lịch sử giá', style: AppTextStyles.small)
        else
          _PriceStatsRow(stats: stats),
      ],
    );
  }
}

class _MarketplaceTab extends StatelessWidget {
  const _MarketplaceTab({required this.offer, required this.selected, required this.onTap});

  final MarketplaceOffer offer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brPill,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: MarketplaceLabel(marketplace: offer.marketplace, colored: selected),
        ),
      ),
    );
  }
}

/// Lowest / average / highest of the visible series plus the trend.
class _PriceStatsRow extends StatelessWidget {
  const _PriceStatsRow({required this.stats});

  final PriceHistoryStats stats;

  @override
  Widget build(BuildContext context) {
    final change = stats.changePercent.abs().toStringAsFixed(1).replaceAll('.', ',');
    final (icon, color, label) = switch (stats.trend) {
      PriceTrend.down => (Icons.trending_down_rounded, AppColors.success, 'Đang giảm $change%'),
      PriceTrend.up => (Icons.trending_up_rounded, AppColors.danger, 'Đang tăng $change%'),
      PriceTrend.flat => (Icons.trending_flat_rounded, AppColors.textSecondary, 'Ổn định'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(label: 'Thấp nhất', value: stats.lowest, color: AppColors.success),
            ),
            Expanded(
              child: _Stat(label: 'Trung bình', value: stats.average, color: AppColors.text),
            ),
            Expanded(
              child: _Stat(label: 'Cao nhất', value: stats.highest, color: AppColors.danger),
            ),
          ],
        ),
        AppSpacing.gapXs,
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Xu hướng: $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.small.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Formatters.price(value),
            style: AppTextStyles.small.copyWith(color: color, fontWeight: FontWeight.w700),
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
