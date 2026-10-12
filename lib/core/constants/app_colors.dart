import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFFFF5A36);
  static const Color primaryDark = Color(0xFFE5431F);
  static const Color primaryLight = Color(0xFFFFF0EB);
  static const Color ai = Color(0xFF6C5CE7);
  static const Color aiLight = Color(0xFFF0EEFD);
  static const Color aiBubble = Color(0xFFEAE6FF);
  static const Color aiDeep = Color(0xFF2F2A6B);

  // Surfaces
  static const Color background = Color(0xFFF7F7F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F2F4);
  static const Color border = Color(0xFFEAEAEA);

  // Text
  static const Color text = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF777777);
  static const Color textTertiary = Color(0xFFA3A3A3);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xCCFFFFFF);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFE8F6EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF5E6);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFDECEC);
  static const Color star = Color(0xFFF5B300);
  static const Color shadow = Color(0xFF171717);

  // Ranking medals
  static const Color gold = Color(0xFFF5B300);
  static const Color silver = Color(0xFF9CA3AF);
  static const Color bronze = Color(0xFFD97706);
  static const Color rankSecond = Color(0xFF7BC67E);
  static const Color rankThird = Color(0xFF3FA66B);

  // Marketplaces
  static const Color shopee = Color(0xFFEE4D2D);
  static const Color tiktokShop = Color(0xFF111111);
  static const Color lazada = Color(0xFF1B1F8A);
  static const Color tiki = Color(0xFF1A94FF);

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8E7CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF5A36), Color(0xFFFF8A5B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient placeholderGradient = LinearGradient(
    colors: [Color(0xFFF2F2F4), Color(0xFFF0EEFD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color tintPhone = Color(0xFFEDE8FF);
  static const Color tintLaptop = Color(0xFFFFEDE3);
  static const Color tintHeadphones = Color(0xFFF0EAFF);
  static const Color tintHome = Color(0xFFE3F1FF);
  static const Color tintFashion = Color(0xFFFFF0E2);

  /// Pastel tile background matching each category illustration.
  static Color categoryTint(String iconKey) => switch (iconKey) {
    'phone' => tintPhone,
    'laptop' => tintLaptop,
    'headphones' => tintHeadphones,
    'home' => tintHome,
    'fashion' => tintFashion,
    _ => primaryLight,
  };
}
