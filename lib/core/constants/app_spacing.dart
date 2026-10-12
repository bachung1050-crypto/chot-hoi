import 'package:flutter/widgets.dart';

import 'app_colors.dart';

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double screen = 20;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: screen);

  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
  static const SizedBox gapXxxl = SizedBox(width: xxxl, height: xxxl);
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppShadows {
  static const List<BoxShadow> card = [BoxShadow(color: Color(0x0A171717), blurRadius: 16, offset: Offset(0, 6))];

  static const List<BoxShadow> ai = [BoxShadow(color: Color(0x336C5CE7), blurRadius: 24, offset: Offset(0, 10))];

  static final List<BoxShadow> bottomBar = [
    BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6)),
  ];
}
