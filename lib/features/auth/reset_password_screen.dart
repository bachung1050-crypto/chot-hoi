import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/supabase_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/app_header.dart';
import '../../repositories/repository_providers.dart';
import 'auth_guard.dart';
import 'providers/auth_providers.dart';

/// Sets a new password: opened from a reset-password email link or from the profile.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go(AppRoutes.profile);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (!mounted) return;
      AppSnackbar.show(context, 'Đã đổi mật khẩu', icon: Icons.check_circle_rounded);
      _close();
    } on DataFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
    filled: true,
    fillColor: AppColors.card,
    border: const OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: AppColors.primary, width: 1.3),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final signedIn = ref.watch(isSignedInProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Đặt mật khẩu mới', onBack: _close),
            Expanded(
              child: !signedIn
                  ? const LoginRequiredState(
                      icon: Icons.lock_reset_rounded,
                      title: 'Liên kết đã hết hạn',
                      message: 'Mở lại liên kết trong email đặt lại mật khẩu, hoặc đăng nhập để đổi mật khẩu.',
                    )
                  : Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.md,
                          AppSpacing.screen,
                          AppSpacing.xl,
                        ),
                        children: [
                          Text('Nhập mật khẩu mới cho tài khoản của bạn', style: AppTextStyles.bodySecondary),
                          AppSpacing.gapLg,
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            decoration: _decoration('Mật khẩu mới'),
                            validator: (v) => (v ?? '').length >= 6 ? null : 'Mật khẩu tối thiểu 6 ký tự',
                          ),
                          AppSpacing.gapMd,
                          TextFormField(
                            controller: _confirm,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _busy ? null : _submit(),
                            decoration: _decoration('Nhập lại mật khẩu'),
                            validator: (v) => v == _password.text ? null : 'Mật khẩu nhập lại không khớp',
                          ),
                          if (error != null) ...[
                            AppSpacing.gapMd,
                            Text(error, style: AppTextStyles.small.copyWith(color: AppColors.danger)),
                          ],
                          AppSpacing.gapXl,
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onDark),
                                  )
                                : const Text('Lưu mật khẩu'),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
