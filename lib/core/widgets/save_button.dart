import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_guard.dart';
import '../../features/saved/providers/saved_products_provider.dart';
import '../../models/product.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../utils/app_snackbar.dart';

/// Heart toggle bound to the saved-products state.
class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.product, this.size = 18, this.elevated = true, this.onToggled});

  final Product product;
  final double size;

  /// White circular background with a soft shadow, for use over images.
  final bool elevated;

  /// Overrides the default snackbar feedback.
  final ValueChanged<bool>? onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isProductSavedProvider(product.id));

    Future<void> toggle() async {
      final nowSaved = await runUserAction(
        context,
        ref,
        () => ref.read(savedProductsProvider.notifier).toggle(product),
      );
      if (nowSaved == null || !context.mounted) return;
      final callback = onToggled;
      if (callback != null) {
        callback(nowSaved);
        return;
      }
      AppSnackbar.show(
        context,
        nowSaved ? 'Đã lưu sản phẩm' : 'Đã bỏ lưu sản phẩm',
        icon: nowSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        actionLabel: nowSaved ? 'Xem' : null,
        onAction: nowSaved ? () => context.go('/saved') : null,
      );
    }

    return Semantics(
      button: true,
      label: saved ? 'Bỏ lưu' : 'Lưu sản phẩm',
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: elevated ? AppShadows.card : null),
        child: Material(
          color: elevated ? AppColors.card : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.6,
                    end: 1,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut)),
                  child: child,
                ),
                child: Icon(
                  saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(saved),
                  size: size,
                  color: saved ? AppColors.danger : AppColors.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
