import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../models/user_profile.dart';
import '../../auth/auth_guard.dart';
import '../providers/profile_providers.dart';

const _languages = {'vi': 'Tiếng Việt', 'en': 'English'};

/// Display name of a `profiles.language` code; unknown codes are shown as-is.
String? languageLabel(String? code) => code == null || code.isEmpty ? null : (_languages[code] ?? code);

Future<void> showProfileEditSheet(BuildContext context, UserProfile profile) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ProfileEditSheet(profile: profile),
  );
}

/// Edits the signed-in user's own `profiles` row.
class ProfileEditSheet extends ConsumerStatefulWidget {
  const ProfileEditSheet({super.key, required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.profile.name);
  late final TextEditingController _phone = TextEditingController(text: widget.profile.phone ?? '');
  late String _language = _languages.containsKey(widget.profile.language) ? widget.profile.language! : 'vi';
  bool _busy = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Nhập tên hiển thị');
      return;
    }
    final profile = widget.profile;
    final phone = _phone.text.trim();
    setState(() => _busy = true);
    final done = await runUserAction(context, ref, () async {
      await ref
          .read(profileProvider.notifier)
          .updateProfile(
            displayName: name == profile.name ? null : name,
            phone: phone == (profile.phone ?? '') ? null : phone,
            language: _language == profile.language ? null : _language,
          );
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (done == null) return;
    AppSnackbar.show(context, 'Đã cập nhật hồ sơ', icon: Icons.check_circle_rounded);
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(String label, IconData icon, {String? error}) => InputDecoration(
    labelText: label,
    errorText: error,
    prefixIcon: Icon(icon, size: 20),
    border: const OutlineInputBorder(borderRadius: AppRadius.brMd),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brMd,
      borderSide: BorderSide(color: AppColors.primary, width: 1.3),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chỉnh sửa hồ sơ', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text(widget.profile.email, style: AppTextStyles.small),
              AppSpacing.gapLg,
              TextField(
                controller: _name,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _nameError = null),
                decoration: _decoration('Tên hiển thị', Icons.person_outline_rounded, error: _nameError),
              ),
              AppSpacing.gapMd,
              TextField(
                controller: _phone,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                decoration: _decoration('Số điện thoại', Icons.phone_outlined),
              ),
              AppSpacing.gapMd,
              Text('Ngôn ngữ', style: AppTextStyles.small),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final entry in _languages.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _language == entry.key,
                      onSelected: _busy ? null : (_) => setState(() => _language = entry.key),
                    ),
                ],
              ),
              AppSpacing.gapLg,
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _busy ? null : _save, child: const Text('Lưu thay đổi')),
              ),
              AppSpacing.gapSm,
              Center(
                child: TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push(AppRoutes.resetPassword);
                        },
                  icon: const Icon(Icons.lock_reset_rounded, size: 18),
                  label: const Text('Đổi mật khẩu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
