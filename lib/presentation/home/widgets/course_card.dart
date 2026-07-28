import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/profile_course_styles.dart';

class CourseCard extends StatefulWidget {
  const CourseCard({
    super.key,
    required this.title,
    this.logoUrl,
    this.backgroundUrl,
    this.onGoToCourse,
    this.buttonLabel = 'الذهاب للحصص',
  });

  final String title;
  final String? logoUrl;
  final String? backgroundUrl;
  final VoidCallback? onGoToCourse;
  final String buttonLabel;

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLarge = screenWidth >= AppSpacing.breakpointLg;
    final isSmall = screenWidth >= AppSpacing.breakpointSm;

    final width =
        isLarge ? AppSpacing.courseCardWidthLg : AppSpacing.courseCardWidth;
    final height = isLarge
        ? AppSpacing.courseCardProfileHeightLg
        : AppSpacing.courseCardProfileHeight;
    final footerPadding =
        isSmall ? AppSpacing.base : AppSpacing.courseCardFooterPadding;
    final footerGap =
        isSmall ? AppSpacing.xl : AppSpacing.courseCardFooterGap;
    final iconHeight = isSmall
        ? AppSpacing.courseCardIconHeightSm
        : AppSpacing.courseCardIconHeight;

    final ctaAlpha = _hovered
        ? ProfileCourseStyles.ctaBackgroundAlphaHover
        : ProfileCourseStyles.ctaBackgroundAlpha;
    final titleStyle = isSmall
        ? ProfileCourseStyles.titleDesktop()
        : ProfileCourseStyles.titleMobile();

    final ctaBackgroundInset = EdgeInsets.fromLTRB(
      AppSpacing.courseCardOuterPadding.horizontal + footerPadding,
      0,
      AppSpacing.courseCardOuterPadding.horizontal + footerPadding,
      AppSpacing.courseCardOuterPadding.vertical + footerPadding,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onGoToCourse,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: AppRadius.borderProfileCourse,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                _CourseCardBackground(
                  url: widget.backgroundUrl,
                  width: width,
                  height: height,
                ),
                Padding(
                  padding: AppSpacing.courseCardOuterPadding,
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final iconWidth = constraints.maxWidth *
                                AppSpacing.courseCardIconWidthFactor;

                            return Center(
                              child: _CourseIcon(
                                url: widget.logoUrl,
                                width: iconWidth,
                                height: iconHeight,
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(footerPadding),
                        child: Column(
                          spacing: footerGap,
                          children: [
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            _ProfileCourseCta(
                              label: widget.buttonLabel,
                              backgroundUrl: widget.backgroundUrl,
                              cardWidth: width,
                              cardHeight: height,
                              backgroundInset: ctaBackgroundInset,
                              backgroundAlpha: ctaAlpha,
                              pressed: _pressed,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCardBackground extends StatelessWidget {
  const _CourseCardBackground({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: ProfileCourseStyles.cardScaffoldUnderlay),
        _CourseNetworkImage(
          url: url,
          width: width,
          height: height,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ],
    );
  }
}

class _ProfileCourseCta extends StatelessWidget {
  const _ProfileCourseCta({
    required this.label,
    required this.backgroundUrl,
    required this.cardWidth,
    required this.cardHeight,
    required this.backgroundInset,
    required this.backgroundAlpha,
    required this.pressed,
  });

  final String label;
  final String? backgroundUrl;
  final double cardWidth;
  final double cardHeight;
  final EdgeInsets backgroundInset;
  final double backgroundAlpha;
  final bool pressed;

  static const _transition = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed ? AppSpacing.courseCardCtaPressScale : 1,
      duration: _transition,
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderCourseCta,
          boxShadow: ProfileCourseStyles.ctaShadow,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.borderCourseCta,
          child: AnimatedContainer(
            duration: _transition,
            curve: Curves.easeOut,
            height: AppSpacing.courseCardCtaHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                const ColoredBox(color: ProfileCourseStyles.cardScaffoldUnderlay),
                Positioned(
                  left: -backgroundInset.left,
                  right: -backgroundInset.right,
                  bottom: -backgroundInset.bottom,
                  height: cardHeight,
                  child: _CourseNetworkImage(
                    url: backgroundUrl,
                    width: cardWidth,
                    height: cardHeight,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                AnimatedContainer(
                  duration: _transition,
                  curve: Curves.easeOut,
                  color: ProfileCourseStyles.ctaFill(backgroundAlpha),
                ),
                Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ProfileCourseStyles.ctaLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseIcon extends StatelessWidget {
  const _CourseIcon({
    required this.url,
    required this.width,
    required this.height,
  });

  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    final image = _CourseNetworkImage(
      url: url,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          _IconDropShadowLayer(
            url: url!,
            width: width,
            height: height,
            offset: AppShadows.courseIconDropShadowPrimaryOffset,
            blurSigma: AppShadows.courseIconDropShadowPrimaryBlur,
            opacity: AppShadows.courseIconDropShadowPrimaryOpacity,
          ),
          _IconDropShadowLayer(
            url: url!,
            width: width,
            height: height,
            offset: AppShadows.courseIconDropShadowSecondaryOffset,
            blurSigma: AppShadows.courseIconDropShadowSecondaryBlur,
            opacity: AppShadows.courseIconDropShadowSecondaryOpacity,
          ),
          image,
        ],
      ),
    );
  }
}

class _IconDropShadowLayer extends StatelessWidget {
  const _IconDropShadowLayer({
    required this.url,
    required this.width,
    required this.height,
    required this.offset,
    required this.blurSigma,
    required this.opacity,
  });

  final String url;
  final double width;
  final double height;
  final Offset offset;
  final double blurSigma;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: opacity),
            BlendMode.srcIn,
          ),
          child: _CourseNetworkImage(
            url: url,
            width: width,
            height: height,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class _CourseNetworkImage extends StatelessWidget {
  const _CourseNetworkImage({
    this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  int? _cacheDimension(double? logical, BuildContext context) {
    if (logical == null) return null;
    return (logical * MediaQuery.devicePixelRatioOf(context)).round();
  }

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(color: AppColors.courseCardImageFallback);
    }

    final cacheW = _cacheDimension(width, context);
    final cacheH = _cacheDimension(height, context);

    if (url!.toLowerCase().endsWith('.avif')) {
      return AvifImage.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return const ColoredBox(color: AppColors.courseCardImageFallback);
        },
      );
    }

    return Image.network(
      url!,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(color: AppColors.courseCardImageFallback);
      },
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: AppColors.courseCardImageFallback);
      },
    );
  }
}
