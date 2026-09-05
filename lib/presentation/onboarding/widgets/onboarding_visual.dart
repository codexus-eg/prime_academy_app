import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Looped onboarding GIF. Renders only while [isActive] so inactive [PageView]
/// pages do not decode heavy assets in parallel.
///
/// Always paints **inside** the allocated slot (below the slide title/subtitle).
/// Never uses unbounded transforms that draw over text above.
class OnboardingVisual extends StatelessWidget {
  const OnboardingVisual({
    super.key,
    required this.asset,
    required this.isActive,
  });

  final String asset;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          if (maxW <= 0 || maxH <= 0) {
            return const SizedBox.shrink();
          }

          // Fit a square (or available box) fully inside the text-below region.
          final side = maxW < maxH ? maxW : maxH;

          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: side,
              height: side,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.hardEdge,
                child: ColoredBox(
                  color: AppColors.mainBg2,
                  child: isActive ? _GifContent(asset: asset) : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GifContent extends StatelessWidget {
  const _GifContent({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[OnboardingVisual] GIF failed: $asset\n$error');
        return const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.white54,
          ),
        );
      },
    );
  }
}
