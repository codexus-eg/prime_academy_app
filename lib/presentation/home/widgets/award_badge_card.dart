import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    this.loading = false,
  });

  final List<AwardCarouselItem> items;
  final bool loading;

  @override
  State<AwardsPanel> createState() => _AwardsPanelState();
}

class _AwardsPanelState extends State<AwardsPanel> {
  final _pageController = PageController();
  Timer? _autoplayTimer;
  var _currentPage = 0;
  var _autoplayActive = false;
  var _programmaticPageChange = false;

  @override
  void didUpdateWidget(covariant AwardsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _stopAutoplay();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);

    if (!_programmaticPageChange && !_autoplayActive) {
      _startAutoplay();
    }
    _programmaticPageChange = false;
  }

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    if (widget.items.length <= 1) return;

    _autoplayActive = true;
    _autoplayTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || widget.items.length <= 1) return;
      if (!_pageController.hasClients) return;

      final next = (_currentPage + 1) % widget.items.length;
      _programmaticPageChange = true;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
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
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

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
          alignment: Alignment.center,
          child: widget.items.isEmpty
              ? const _AwardsEmptyState()
              : _AwardsCarousel(
                  items: widget.items,
                  pageController: _pageController,
                  currentPage: _currentPage,
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
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<AwardCarouselItem> items;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final maxSlideHeight = _maxSlideHeight(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: maxSlideHeight,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: pageController,
              itemCount: items.length,
              physics: const PageScrollPhysics(),
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                return _AnimatedCarouselSlide(
                  active: index == currentPage,
                  child: _AwardSlideItem(item: items[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  double _maxSlideHeight(BuildContext context) {
    var hasCertificate = false;
    for (final item in items) {
      if (item is AwardCertificateCarouselItem) {
        hasCertificate = true;
        break;
      }
    }

    if (hasCertificate) {
      return AppSpacing.awardsCertificateSize +
          AppSpacing.awardsItemGap +
          AppSpacing.xl +
          16;
    }

    return AppSpacing.awardsImageSize +
        AppSpacing.awardsItemGap +
        AppSpacing.xl;
  }
}

class _AnimatedCarouselSlide extends StatefulWidget {
  const _AnimatedCarouselSlide({
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<_AnimatedCarouselSlide> createState() => _AnimatedCarouselSlideState();
}

class _AnimatedCarouselSlideState extends State<_AnimatedCarouselSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    if (widget.active) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCarouselSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

class _AwardSlideItem extends StatelessWidget {
  const _AwardSlideItem({required this.item});

  final AwardCarouselItem item;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      AwardLevelCarouselItem(:final level, :final count) =>
        _LevelSlide(level: level, count: count),
      AwardCertificateCarouselItem(
        :final templateIndex,
        :final certificates,
      ) =>
        _CertificateSlide(
          templateIndex: templateIndex,
          certificates: certificates,
        ),
    };
  }
}

class _LevelSlide extends StatelessWidget {
  const _LevelSlide({
    required this.level,
    required this.count,
  });

  final StudentAwardLevel level;
  final int count;

  @override
  Widget build(BuildContext context) {
    final imageIndex = level.imageIndex.clamp(
      0,
      ClassificationAssets.characterImages.length - 1,
    );
    final imageAsset = ClassificationAssets.characterImages[imageIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: AppSpacing.awardsImageSize,
              height: AppSpacing.awardsImageSize,
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
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
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
  });

  final int templateIndex;
  final List<StudentAwardCertificate> certificates;

  @override
  Widget build(BuildContext context) {
    if (certificates.isEmpty) return const SizedBox.shrink();
    final first = certificates.first;
    final count = certificates.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
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
                child: Opacity(
                  opacity: 1,
                  child: HoverOpacity(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: AppRadius.borderShadcnLg,
                        child: SizedBox(
                          width: AppSpacing.awardsCertificateSize,
                          height: AppSpacing.awardsCertificateSize,
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
            ),
          ],
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
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
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
