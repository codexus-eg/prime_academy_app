import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_typography.dart';
import '../data/classification_assets.dart';
import '../models/classification_level.dart';

bool _isMobileLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 768;

class ClassificationSubmitContainer extends StatefulWidget {
  const ClassificationSubmitContainer({
    super.key,
    required this.currentLevel,
    required this.nextLevel,
    required this.isCorrect,
    required this.feedbackKey,
  });

  final ClassificationLevel currentLevel;
  final ClassificationLevel? nextLevel;
  final bool? isCorrect;
  final int feedbackKey;

  @override
  State<ClassificationSubmitContainer> createState() =>
      _ClassificationSubmitContainerState();
}

class _ClassificationSubmitContainerState
    extends State<ClassificationSubmitContainer>
    with TickerProviderStateMixin {
  static const _correctMessages = [
    '!صح صح',
    '!يا سلام يا جدع',
    '!أحسنت يا بطل',
    '!برافو عليك',
    '!عظمة على عظمة',
    '!ربنا يبارك فيك',
    '!شيخ يا شيخ',
    '!كبير أوي',
    '!صج صج',
    '!يا هلا والله',
    '!أحسنت يا طيب',
    '!مرررة حلو',
    '!ما شاء الله تبارك الله',
    '!الله يبارك فيك',
    '!شيخ الشباب',
    '!ما قصرت',
    '!كبير والله',
  ];

  static const _incorrectMessages = [
    '!غلط غلط',
    '!آه آه مش كده',
    '!لا لا لأ',
    '!يلا في مرة تانية',
    '!حرام عليك',
    '!فوت يا عم',
    '!معلش المره الجاية',
    '!غلط غلط',
    '!آه آه مو جذي',
    '!لا لا لأ',
    '!يلا بمرة ثانية',
    '!حرام عليك',
    '!فاتتك يا رجال',
    '!جربها مرة ثانية',
    '!لا مو هذي',
  ];

  String? _message;
  var _visible = false;
  late final AnimationController _feedbackController;
  late final AnimationController _arrowController;
  late final Animation<double> _feedbackOpacity;
  late final Animation<double> _arrowSlide;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _feedbackOpacity = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeInOut,
    );
    _arrowSlide = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
    _showFeedbackIfNeeded(widget.feedbackKey, widget.isCorrect);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncArrowAnimation(_isMobileLayout(context));
  }

  void _syncArrowAnimation(bool mobile) {
    if (mobile) {
      if (_arrowController.isAnimating) _arrowController.stop();
    } else if (!_arrowController.isAnimating) {
      _arrowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ClassificationSubmitContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.feedbackKey != oldWidget.feedbackKey) {
      _showFeedbackIfNeeded(widget.feedbackKey, widget.isCorrect);
    }
  }

  void _showFeedbackIfNeeded(int feedbackKey, bool? isCorrect) {
    if (feedbackKey <= 0 || isCorrect == null) return;
    final pool = isCorrect ? _correctMessages : _incorrectMessages;
    final mobile = mounted ? _isMobileLayout(context) : false;
    setState(() {
      _message = pool[math.Random().nextInt(pool.length)];
      _visible = true;
    });
    _feedbackController.forward(from: 0);
    Future.delayed(
      Duration(milliseconds: mobile ? 1500 : 2000),
      () {
        if (mounted) setState(() => _visible = false);
      },
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);

    final currentImage =
        ClassificationAssets.characterImages[widget.currentLevel.imageIndex];
    final nextImage = widget.nextLevel == null
        ? null
        : ClassificationAssets
            .characterImages[widget.nextLevel!.imageIndex];

    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: mobile ? const Color(0xEB0A0E1C) : null,
        gradient: mobile
            ? null
            : LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.mainBg3,
                  AppColors.mainBg3.withValues(alpha: 0),
                ],
              ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LevelBadge(
                    imageAsset: currentImage,
                    title: widget.currentLevel.title,
                    size: 48,
                    emphasized: true,
                    showGlow: !mobile,
                    maxTitleWidth: 80,
                  ),
                  if (widget.nextLevel != null && nextImage != null) ...[
                    const SizedBox(width: 12),
                    if (mobile)
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 14,
                      )
                    else
                      AnimatedBuilder(
                        animation: _arrowSlide,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_arrowSlide.value, 0),
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 14,
                        ),
                      ),
                    const SizedBox(width: 12),
                    _LevelBadge(
                      imageAsset: nextImage,
                      title: widget.nextLevel!.title,
                      size: 32,
                      emphasized: false,
                      showGlow: false,
                      maxTitleWidth: 64,
                    ),
                  ],
                ],
              ),
              const Spacer(),
              if (_visible && _message != null)
                FadeTransition(
                  opacity: _feedbackOpacity,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      _message!,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onDark,
                        fontWeight: AppFonts.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 128),
            ],
          ),
        ),
      ),
    );

    if (mobile) return bar;

    return ClipRect(
      child: BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: bar,
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.imageAsset,
    required this.title,
    required this.size,
    required this.emphasized,
    required this.showGlow,
    required this.maxTitleWidth,
  });

  final String imageAsset;
  final String title;
  final double size;
  final bool emphasized;
  final bool showGlow;
  final double maxTitleWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxTitleWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (emphasized && showGlow)

                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondaryOpaque
                                  .withValues(alpha: 0.14),
                              const Color(0xFFA855F7).withValues(alpha: 0.14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (emphasized)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      imageAsset,
                      width: size,
                      height: size,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
                    child: Opacity(
                      opacity: 0.4,
                      child: Image.asset(
                        imageAsset,
                        width: size,
                        height: size,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          emphasized
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFFC084FC)],
                  ).createShader(bounds),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
        ],
      ),
    );
  }
}
