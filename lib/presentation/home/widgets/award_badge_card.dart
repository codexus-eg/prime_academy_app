import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/students/student_awards.dart';
import '../../classification_quiz/data/classification_assets.dart';
import '../models/award_carousel_item.dart';
import 'award_certificate_preview.dart';
import 'award_count_badge.dart';
import 'awards_empty_trophy.dart';

class AwardsPanel extends StatefulWidget {
  const AwardsPanel({
    super.key,
    this.items = const [],
  });

  final List<AwardCarouselItem> items;

  @override
  State<AwardsPanel> createState() => _AwardsPanelState();
}

class _AwardsPanelState extends State<AwardsPanel> {
  static const _loopBlocks = 800;

  PageController? _pageController;
  Timer? _autoplayTimer;
  var _logicalPage = 0;
  var _autoplayActive = false;
  var _programmaticPageChange = false;
  var _showTwoUp = false;

  int get _itemCount => widget.items.length;

  bool get _canLoop => _itemCount > 1;

  int get _initialPage {
    if (!_canLoop) return 0;
    return _itemCount * (_loopBlocks ~/ 2);
  }

  int get _pageCount {
    if (_itemCount == 0) return 0;
    if (!_canLoop) return _itemCount;
    return _itemCount * _loopBlocks;
  }

  @override
  void initState() {
    super.initState();
    _logicalPage = _initialPage;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureController();
  }

  @override
  void didUpdateWidget(covariant AwardsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _stopAutoplay();
      _logicalPage = _initialPage;
      _recreateController();
    }
  }

  void _ensureController() {
    final width = MediaQuery.sizeOf(context).width;
    final showTwoUp = width >= AppSpacing.breakpointMd && _itemCount > 1;
    if (_pageController == null || showTwoUp != _showTwoUp) {
      _showTwoUp = showTwoUp;
      _recreateController();
    }
  }

  void _recreateController() {
    _stopAutoplay();
    final old = _pageController;
    final fraction = _showTwoUp ? 0.5 : 1.0;
    final initial = _canLoop
        ? _logicalPage
        : _logicalPage.clamp(0, math.max(_itemCount - 1, 0)).toInt();
    _pageController = PageController(
      initialPage: initial,
      viewportFraction: fraction,
    );
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    _scheduleAutoplayStart();
  }

  void _scheduleAutoplayStart() {
    if (!_canLoop || _autoplayActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_canLoop || _autoplayActive) return;
      final controller = _pageController;
      if (controller == null || !controller.hasClients) {
        _scheduleAutoplayStart();
        return;
      }
      _startAutoplay();
    });
  }

  void _onPageChanged(int index) {
    setState(() => _logicalPage = index);

    if (!_programmaticPageChange && !_autoplayActive) {
      _startAutoplay();
    }
    _programmaticPageChange = false;
  }

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    if (!_canLoop) return;

    _autoplayActive = true;
    _autoplayTimer = Timer.periodic(AppDurations.awardsAutoplayDelay, (_) {
      if (!mounted || !_canLoop) return;
      final controller = _pageController;
      if (controller == null || !controller.hasClients) return;

      _programmaticPageChange = true;
      controller.animateToPage(
        _logicalPage + 1,
        duration: AppDurations.awardsCarouselScroll,
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoplay() {
    _autoplayTimer?.cancel();
    _autoplayActive = false;
    _programmaticPageChange = false;
  }

  @override
  void dispose() {
    _stopAutoplay();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AppSpacing.breakpointLessonDesktop;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide
              ? AppSpacing.awardsContainerMaxWidth
              : double.infinity,
          minHeight: AppSpacing.awardsContainerMinHeight,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.mainBg3,
            borderRadius: AppRadius.borderAuthForm,
            boxShadow: AppShadows.shadow2xl,
          ),
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          child: widget.items.isEmpty
              ? const _AwardsEmptyState()
              : _AwardsCarousel(
                  items: widget.items,
                  pageController: _pageController!,
                  pageCount: _pageCount,
                  showTwoUp: _showTwoUp,
                  onPageChanged: _onPageChanged,
                ),
        ),
      ),
    );
  }
}

class _AwardsCarousel extends StatelessWidget {
  const _AwardsCarousel({
    required this.items,
    required this.pageController,
    required this.pageCount,
    required this.showTwoUp,
    required this.onPageChanged,
  });

  final List<AwardCarouselItem> items;
  final PageController pageController;
  final int pageCount;
  final bool showTwoUp;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slideWidth = showTwoUp
            ? constraints.maxWidth * 0.5
            : constraints.maxWidth;
        final slideHeight = _slideHeight(context, slideWidth);

        return SizedBox(
          height: slideHeight,
          width: double.infinity,
          // Badges sit outside the card (web: overflow visible).
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: pageController,
              itemCount: pageCount,
              allowImplicitScrolling: true,
              clipBehavior: Clip.none,
              physics: const PageScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final item = items[index % items.length];
                return Padding(
                  // Web CarouselItem: pl-4 + py-4
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.base,
                  ),
                  child: Center(
                    child: _AwardSlideItem(
                      item: item,
                      maxWidth: slideWidth - AppSpacing.base,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  double _slideHeight(BuildContext context, double slideWidth) {
    final hasCertificate =
        items.any((item) => item is AwardCertificateCarouselItem);
    // Web: py-4 above/below + card. Extra top room for count badge (-top-4).
    const verticalPad = AppSpacing.base * 2;
    const badgeRoom = AppSpacing.base;

    if (hasCertificate) {
      final certSize = _certificateDisplaySize(slideWidth - AppSpacing.base);
      return badgeRoom + verticalPad + certSize;
    }

    final levelSize =
        _levelImageSize(context, slideWidth - AppSpacing.base);
    return badgeRoom +
        verticalPad +
        levelSize +
        AppSpacing.awardsItemGap +
        AppSpacing.xl;
  }
}

/// Web `w-70.5` design size; scales down on narrow slides.
double _certificateDisplaySize(double maxWidth) {
  return math.min(AppSpacing.awardsCertificateSize, maxWidth);
}

double _levelImageSize(BuildContext context, double maxWidth) {
  final wide = MediaQuery.sizeOf(context).width >= AppSpacing.breakpointMd;
  final preferred =
      wide ? AppSpacing.awardsImageSizeMd : AppSpacing.awardsImageSize;
  return math.min(preferred, math.max(maxWidth, 120));
}

class _AwardSlideItem extends StatelessWidget {
  const _AwardSlideItem({
    required this.item,
    required this.maxWidth,
  });

  final AwardCarouselItem item;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      AwardLevelCarouselItem(:final level, :final count) => _LevelSlide(
          level: level,
          count: count,
          maxWidth: maxWidth,
        ),
      AwardCertificateCarouselItem(
        :final templateIndex,
        :final certificates,
      ) =>
        _CertificateSlide(
          templateIndex: templateIndex,
          certificates: certificates,
          maxWidth: maxWidth,
        ),
    };
  }
}

class _LevelSlide extends StatelessWidget {
  const _LevelSlide({
    required this.level,
    required this.count,
    required this.maxWidth,
  });

  final StudentAwardLevel level;
  final int count;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final imageIndex = level.imageIndex.clamp(
      0,
      ClassificationAssets.characterImages.length - 1,
    );
    final imageAsset = ClassificationAssets.characterImages[imageIndex];
    final size = _levelImageSize(context, maxWidth);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.awardsImageSurface,
                borderRadius: AppRadius.borderAuthButton,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
            if (count > 1)
              Positioned(
                top: 8,
                left: 8,
                child: AwardCountBadge(count: count),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.awardsItemGap),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth * 0.85),
          child: Text(
            level.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.secondaryOld,
              fontWeight: AppFonts.semibold,
            ),
          ),
        ),
      ],
    );
  }
}

class _CertificateSlide extends StatelessWidget {
  const _CertificateSlide({
    required this.templateIndex,
    required this.certificates,
    required this.maxWidth,
  });

  final int templateIndex;
  final List<StudentAwardCertificate> certificates;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (certificates.isEmpty) return const SizedBox.shrink();
    final first = certificates.first;
    final count = certificates.length;
    final size = _certificateDisplaySize(maxWidth);
    const design = AppSpacing.awardsCertificateSize;

    // Web: w-70.5 h-70.5 card; scale down on small slides via FittedBox.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (count > 1)
          Positioned(
            top: -16,
            left: -12,
            child: AwardCountBadge(
              count: count,
              certificateStyle: true,
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.borderAuthButton,
            onTap: () {
              AwardCertificatePreview.showCertificatesDialog(
                context,
                templateIndex: templateIndex,
                certificates: certificates,
              );
            },
            child: HoverOpacity(
              child: SizedBox(
                width: size,
                height: size,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: design,
                    height: design,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AwardCertificatePreview.build(
                        templateIndex: templateIndex,
                        studentName: first.studentName,
                        teacherName: first.teacherName,
                        preview: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HoverOpacity extends StatefulWidget {
  const HoverOpacity({super.key, required this.child});

  final Widget child;

  @override
  State<HoverOpacity> createState() => _HoverOpacityState();
}

class _HoverOpacityState extends State<HoverOpacity> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _pressed ? 0.8 : 1,
        child: widget.child,
      ),
    );
  }
}

class _AwardsEmptyState extends StatefulWidget {
  const _AwardsEmptyState();

  @override
  State<_AwardsEmptyState> createState() => _AwardsEmptyStateState();
}

class _AwardsEmptyStateState extends State<_AwardsEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppDurations.awardsCarouselScroll,
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeInOut,
    );
    _scale = Tween<double>(begin: 0.9, end: 1).animate(_fade);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AwardsEmptyTrophy(),
            const SizedBox(height: AppSpacing.xl),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'لا توجد جوائز مكتسبة حتى الأن',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.awardsEmptyText,
                  fontSize: 14,
                  fontWeight: AppFonts.regular,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef AwardBadgeCard = AwardsPanel;
