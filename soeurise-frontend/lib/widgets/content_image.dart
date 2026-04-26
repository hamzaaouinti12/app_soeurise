import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';

class ContentImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final BoxFit fit;

  const ContentImage({
    required this.imageUrl,
    this.height = 200,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null ||
        imageUrl!.isEmpty ||
        imageUrl!.contains('placeholder')) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.beige,
              AppColors.beigeLight,
              AppColors.primaryLight.withAlpha(30),
            ],
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_rounded,
              size: 40,
              color: AppColors.primaryLight.withAlpha(150),
            ),
            const SizedBox(height: 8),
            Text(
              'Image',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    final String resolvedUrl = ApiConfig.uploadsUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppBorderRadius.md),
      child: Image.network(
        resolvedUrl,
        height: height,
        width: double.infinity,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ShimmerLoading(
            width: double.infinity,
            height: height,
            borderRadius: AppBorderRadius.md,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  size: 40,
                  color: AppColors.primaryLight.withAlpha(150),
                ),
                const SizedBox(height: 8),
                Text(
                  'Image non disponible',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
