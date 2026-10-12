import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../utils/app_snackbar.dart';
import 'tap_scale.dart';

/// "✦ Hỏi Chốt Hời AI..." input. In [readOnly] mode it behaves like a button.
class AiSearchBar extends StatelessWidget {
  const AiSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = AppStrings.homeSearchHint,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hintStyle = AppTextStyles.body.copyWith(color: AppColors.textSecondary);
    final textController = controller;

    final input = readOnly
        ? Text(hintText, maxLines: 1, overflow: TextOverflow.ellipsis, style: hintStyle)
        : TextField(
            controller: textController,
            focusNode: focusNode,
            autofocus: autofocus,
            onSubmitted: onSubmitted,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.search,
            style: AppTextStyles.body,
            cursorColor: AppColors.ai,
            decoration: InputDecoration.collapsed(hintText: hintText, hintStyle: hintStyle),
          );

    Widget trailing = IconButton(
      tooltip: 'Tìm bằng giọng nói',
      icon: const Icon(Icons.mic_rounded, color: AppColors.text),
      onPressed: () => AppSnackbar.show(context, 'Tìm bằng giọng nói sẽ có ở phiên bản sau', icon: Icons.mic_rounded),
    );

    if (!readOnly && textController != null) {
      final mic = trailing;
      trailing = ValueListenableBuilder<TextEditingValue>(
        valueListenable: textController,
        builder: (context, value, _) {
          if (value.text.trim().isEmpty) return mic;
          return IconButton(
            tooltip: 'Gửi',
            onPressed: () => onSubmitted?.call(value.text),
            icon: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(gradient: AppColors.aiGradient, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, color: AppColors.onDark, size: 20),
            ),
          );
        },
      );
    }

    final bar = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.aiLight, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.ai, size: 20),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: input,
            ),
          ),
          trailing,
        ],
      ),
    );

    if (!readOnly) return bar;
    return TapScale(scale: 0.98, onTap: onTap, child: bar);
  }
}
