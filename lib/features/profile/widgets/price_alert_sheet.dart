import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/price_alert.dart';
import '../../../models/product.dart';
import '../../auth/auth_guard.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

/// Opens the create/edit sheet for the alert on [product]; asks to sign in first when needed.
Future<void> showPriceAlertSheet(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  bool showProductLink = false,
}) async {
  if (!ref.read(isSignedInProvider)) {
    showLoginPrompt(context);
    return;
  }
  final existing = ref.read(priceAlertsProvider.notifier).alertFor(product.id);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PriceAlertSheet(product: product, existing: existing, showProductLink: showProductLink),
  );
}

class PriceAlertSheet extends ConsumerStatefulWidget {
  const PriceAlertSheet({super.key, required this.product, this.existing, this.showProductLink = false});

  final Product product;
  final PriceAlert? existing;
  final bool showProductLink;

  @override
  ConsumerState<PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends ConsumerState<PriceAlertSheet> {
  late final TextEditingController _target;
  late bool _enabled = widget.existing?.enabled ?? true;
  bool _busy = false;
  String? _error;

  PriceAlert? get _existing => widget.existing;

  int get _currentPrice => _existing?.currentPrice ?? widget.product.currentPrice;

  String get _marketplaceName => (_existing?.offer ?? widget.product.cheapestOffer).marketplace.name;

  @override
  void initState() {
    super.initState();
    final target = _existing?.targetPrice ?? PriceAlertsNotifier.defaultTargetPrice(_currentPrice);
    _target = TextEditingController(text: '$target');
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(PriceAlertsNotifier notifier) action, String message, IconData icon) async {
    setState(() => _busy = true);
    final done = await runUserAction(context, ref, () async {
      await action(ref.read(priceAlertsProvider.notifier));
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (done == null) return;
    AppSnackbar.show(context, message, icon: icon);
    Navigator.of(context).pop();
  }

  void _save() {
    final target = int.tryParse(_target.text) ?? 0;
    if (target <= 0) {
      setState(() => _error = 'Nhập giá mục tiêu lớn hơn 0');
      return;
    }
    final existing = _existing;
    _run(
      (notifier) async {
        if (existing == null) {
          await notifier.saveAlert(widget.product, targetPrice: target, offer: widget.product.cheapestOffer);
          return;
        }
        if (target != existing.targetPrice) await notifier.updateTargetPrice(existing.id, target);
        if (_enabled != existing.enabled) await notifier.setEnabled(existing.id, enabled: _enabled);
      },
      'Sẽ báo bạn khi giá ≤ ${Formatters.price(target)}',
      Icons.notifications_active_rounded,
    );
  }

  void _delete(PriceAlert alert) =>
      _run((notifier) => notifier.delete(alert.id), 'Đã xóa cảnh báo giá', Icons.delete_outline_rounded);

  @override
  Widget build(BuildContext context) {
    final existing = _existing;
    final error = _error;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Báo tôi khi giảm giá' : 'Cảnh báo giá', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(widget.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.small),
              AppSpacing.gapLg,
              Row(
                children: [
                  Expanded(child: Text('Giá hiện tại ($_marketplaceName)', style: AppTextStyles.bodySecondary)),
                  Text(
                    Formatters.price(_currentPrice),
                    style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              TextField(
                controller: _target,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: 'Báo tôi khi giá ≤',
                  suffixText: 'đ',
                  errorText: error,
                  border: const OutlineInputBorder(borderRadius: AppRadius.brMd),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide(color: AppColors.primary, width: 1.3),
                  ),
                ),
              ),
              if (existing != null) ...[
                AppSpacing.gapSm,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_enabled ? 'Đang theo dõi' : 'Đã tạm dừng', style: AppTextStyles.body),
                  value: _enabled,
                  onChanged: _busy ? null : (value) => setState(() => _enabled = value),
                ),
              ],
              AppSpacing.gapLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(existing == null ? 'Tạo cảnh báo' : 'Lưu thay đổi'),
                ),
              ),
              if (existing != null) ...[
                AppSpacing.gapSm,
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    if (widget.showProductLink)
                      TextButton.icon(
                        onPressed: () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push(AppRoutes.product(widget.product.id));
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Xem sản phẩm'),
                      ),
                    TextButton.icon(
                      onPressed: _busy ? null : () => _delete(existing),
                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Xóa cảnh báo'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
