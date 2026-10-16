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
import '../../core/widgets/chot_hoi_logo.dart';
import '../../repositories/repository_providers.dart';

/// Email/password sign in and sign up.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go(AppRoutes.profile);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    try {
      if (_register) {
        final needsConfirmation = await auth.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _name.text.trim(),
        );
        if (!mounted) return;
        if (needsConfirmation) {
          setState(() {
            _register = false;
            _busy = false;
          });
          AppSnackbar.show(
            context,
            'Đã gửi email xác nhận. Xác nhận xong hãy đăng nhập.',
            icon: Icons.mark_email_read_outlined,
          );
          return;
        }
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
      if (!mounted) return;
      AppSnackbar.show(context, 'Đăng nhập thành công');
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

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Nhập email của bạn để nhận liên kết đặt lại mật khẩu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) {
        AppSnackbar.show(context, 'Đã gửi liên kết đặt lại mật khẩu tới $email', icon: Icons.mark_email_read_outlined);
      }
    } on DataFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    if (mounted) setState(() => _busy = false);
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: _register ? 'Đăng ký' : 'Đăng nhập', onBack: _close),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.md,
                    AppSpacing.screen,
                    AppSpacing.xl,
                  ),
                  children: [
                    const Center(child: ChotHoiLogo(size: 40)),
                    AppSpacing.gapLg,
                    Text(
                      _register ? 'Tạo tài khoản để lưu deal và theo dõi giá' : 'Đăng nhập để lưu deal và theo dõi giá',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                    AppSpacing.gapXl,
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: _decoration('Tên hiển thị', Icons.person_outline_rounded),
                      ),
                      AppSpacing.gapMd,
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration('Email', Icons.mail_outline_rounded),
                      validator: (v) => (v ?? '').contains('@') ? null : 'Email không hợp lệ',
                    ),
                    AppSpacing.gapMd,
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _busy ? null : _submit(),
                      decoration: _decoration(
                        'Mật khẩu',
                        Icons.lock_outline_rounded,
                        suffix: IconButton(
                          tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                        ),
                      ),
                      validator: (v) => (v ?? '').length >= 6 ? null : 'Mật khẩu tối thiểu 6 ký tự',
                    ),
                    if (!_register)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: const Text('Quên mật khẩu?'),
                        ),
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
                          : Text(_register ? 'Đăng ký' : 'Đăng nhập'),
                    ),
                    AppSpacing.gapSm,
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _register = !_register;
                              _error = null;
                            }),
                      child: Text(_register ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Đăng ký'),
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
