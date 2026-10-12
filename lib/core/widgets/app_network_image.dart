import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Network image with a branded placeholder for loading/error states,
/// so a broken mock URL never breaks the layout.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fallbackIcon = Icons.shopping_bag_outlined,
    this.iconSize = 32,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String url;
  final IconData fallbackIcon;
  final double iconSize;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(icon: fallbackIcon, iconSize: iconSize);
    final image = Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );

    final radius = borderRadius;
    if (radius == null) return image;
    return ClipRRect(borderRadius: radius, child: image);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.iconSize});

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.placeholderGradient),
      child: Center(
        child: Icon(icon, size: iconSize, color: AppColors.ai.withValues(alpha: 0.35)),
      ),
    );
  }
}
