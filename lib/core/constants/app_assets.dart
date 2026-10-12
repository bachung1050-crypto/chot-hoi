abstract final class AppAssets {
  static const String aiBanner = 'assets/images/ai_banner.png';
  static const String aiMascot = 'assets/images/ai_mascot.png';
  static const String imageSearchHero = 'assets/images/image_search_hero.png';

  /// Width / height of [aiBanner].
  static const double aiBannerAspectRatio = 816 / 306;

  /// 3D illustration for a category icon key, or null when only a vector icon exists.
  static String? categoryImage(String iconKey) => switch (iconKey) {
    'phone' || 'laptop' || 'headphones' || 'home' || 'fashion' => 'assets/images/categories/cat_$iconKey.png',
    _ => null,
  };
}
