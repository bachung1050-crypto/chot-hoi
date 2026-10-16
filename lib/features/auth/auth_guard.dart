import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/empty_state.dart';
import 'providers/auth_providers.dart';

void showLoginPrompt(BuildContext context) {
  AppSnackbar.show(
    context,
    'Đăng nhập để sử dụng tính năng này',
    icon: Icons.lock_outline_rounded,
    actionLabel: 'Đăng nhập',
    onAction: () => context.push(AppRoutes.login),
  );
}

/// Runs a user-owned action: asks to sign in when signed out and turns
/// repository failures into a snackbar instead of an uncaught error.
/// Returns null when the action did not run or failed.
Future<T?> runUserAction<T>(BuildContext context, WidgetRef ref, Future<T> Function() action) async {
  if (!ref.read(isSignedInProvider)) {
    showLoginPrompt(context);
    return null;
  }
  try {
    return await action();
  } on AuthRequiredFailure {
    if (context.mounted) showLoginPrompt(context);
  } on DataFailure catch (e) {
    if (context.mounted) AppSnackbar.show(context, e.message, icon: Icons.error_outline_rounded);
  }
  return null;
}

/// Empty state shown in place of user-owned content when signed out.
class LoginRequiredState extends StatelessWidget {
  const LoginRequiredState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: 'Đăng nhập',
      onAction: () => context.push(AppRoutes.login),
    );
  }
}
