import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onDark,
      primaryContainer: AppColors.primaryLight,
      secondary: AppColors.ai,
      onSecondary: AppColors.onDark,
      surface: AppColors.card,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.danger,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.brLg);

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTextStyles.textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.h2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onDark,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: buttonShape,
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          side: const BorderSide(color: AppColors.primary, width: 1.3),
          shape: buttonShape,
          textStyle: AppTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary, textStyle: AppTextStyles.label),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.primaryLight,
        side: BorderSide(color: AppColors.border),
        labelStyle: AppTextStyles.label,
        shape: StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelPadding: const EdgeInsets.only(top: 2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.caption.copyWith(
            fontSize: 12,
            color: selected ? AppColors.primary : AppColors.text,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: selected ? 32 : 30, color: selected ? AppColors.primary : AppColors.text);
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.card),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.textTertiary, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.primary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.onDark),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.text,
        titleTextStyle: AppTextStyles.title,
        subtitleTextStyle: AppTextStyles.small,
      ),
    );
  }
}
