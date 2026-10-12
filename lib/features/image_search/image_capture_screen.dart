import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_network_image.dart';
import '../../core/widgets/tap_scale.dart';
import 'providers/image_search_controller.dart';
import 'widgets/image_search_widgets.dart';

/// Step 1: frame a product photo (demo frames) or pick one from the sample library.
class ImageCaptureScreen extends ConsumerStatefulWidget {
  const ImageCaptureScreen({super.key, this.openLibrary = false});

  /// Opens the library sheet right away (from the Home "Chọn từ thư viện" button).
  final bool openLibrary;

  @override
  ConsumerState<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends ConsumerState<ImageCaptureScreen> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    if (widget.openLibrary) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final images = await ref.read(imageSampleImagesProvider.future);
        if (mounted) _openLibrary(images);
      });
    }
  }

  void _useImage(String url) {
    ref.read(imageSearchProvider.notifier).selectImage(url);
    context.push(AppRoutes.imageRequest);
  }

  Future<void> _openLibrary(List<String> images) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chọn ảnh từ thư viện', style: AppTextStyles.h3),
              AppSpacing.gapMd,
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final url in images)
                    TapScale(
                      onTap: () => Navigator.of(context).pop(url),
                      child: AppNetworkImage(
                        url: url,
                        borderRadius: AppRadius.brMd,
                        fallbackIcon: Icons.image_outlined,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) _useImage(picked);
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(imageSampleImagesProvider).value ?? const [];
    final current = images.isEmpty ? null : images[_selected.clamp(0, images.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Tìm bằng hình ảnh'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.xs, AppSpacing.screen, AppSpacing.lg),
                children: [
                  AspectRatio(
                    aspectRatio: 0.82,
                    child: ClipRRect(
                      borderRadius: AppRadius.brLg,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: AppColors.surfaceMuted),
                          if (current != null)
                            AppNetworkImage(url: current, fallbackIcon: Icons.photo_camera_outlined, iconSize: 56),
                          const ViewfinderCorners(),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Row(
                    children: [
                      for (var i = 0; i < images.length; i++) ...[
                        if (i > 0) AppSpacing.gapSm,
                        Expanded(
                          child: TapScale(
                            onTap: () => setState(() => _selected = i),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.brMd,
                                  border: Border.all(
                                    color: i == _selected ? AppColors.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: AppNetworkImage(
                                  url: images[i],
                                  borderRadius: AppRadius.brSm,
                                  fallbackIcon: Icons.image_outlined,
                                  iconSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.gapLg,
                  GradientActionButton(
                    label: 'Chụp ảnh',
                    icon: Icons.photo_camera_rounded,
                    onPressed: () {
                      if (current != null) _useImage(current);
                    },
                  ),
                  AppSpacing.gapMd,
                  SoftActionButton(
                    label: 'Chọn từ thư viện',
                    icon: Icons.photo_library_rounded,
                    onPressed: () => _openLibrary(images),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
