import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_typography.dart';
import 'exam_ready_icons.dart';

class ExamAnimatedProgress extends StatefulWidget {
  const ExamAnimatedProgress({
    super.key,
    this.startPercent = 0,
    this.endPercent = 0,
    this.duration = const Duration(milliseconds: 2000),
    this.showLaunchLabels = false,
    this.onComplete,
  });

  final double startPercent;
  final double endPercent;
  final Duration duration;
  final bool showLaunchLabels;
  final VoidCallback? onComplete;

  @override
  State<ExamAnimatedProgress> createState() => _ExamAnimatedProgressState();
}

class _ExamAnimatedProgressState extends State<ExamAnimatedProgress>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _shimmerController;
  late final AnimationController _flagPulseController;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(vsync: this, duration: widget.duration);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _flagPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progress = Tween<double>(
      begin: widget.startPercent,
      end: widget.endPercent,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: const Cubic(0.25, 0.46, 0.45, 0.94),
    ));

    _progressController.forward().whenComplete(() {
      if (widget.endPercent >= 100) {
        _flagPulseController.repeat();
      }
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    _flagPulseController.dispose();
    super.dispose();
  }

  _ResponsiveSizes _sizesFor(double width) {
    if (width < 480) {
      return const _ResponsiveSizes(
        dotWidth: 56,
        dotHeight: 56,
        flagSize: 36,
        headerSize: 16,
        percentFontSize: 13,
        goalFontSize: 12,
        chevronSize: 12,
      );
    }
    if (width < 768) {
      return const _ResponsiveSizes(
        dotWidth: 64,
        dotHeight: 64,
        flagSize: 42,
        headerSize: 18,
        percentFontSize: 14,
        goalFontSize: 13,
        chevronSize: 14,
      );
    }
    return const _ResponsiveSizes(
      dotWidth: 72,
      dotHeight: 72,
      flagSize: 52,
      headerSize: 20,
      percentFontSize: 15,
      goalFontSize: 14,
      chevronSize: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerContext) {
        final outerWidth = outerContext.maxWidth;

        return SizedBox(
          width: outerWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 72, 40, 56),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final sizes = _sizesFor(width);
                    const trackHeight = 20.0;
                    final trackRightInset = sizes.flagSize * 0.6;
                    final trackWidth = width - trackRightInset;

                    final flagRight = -(sizes.flagSize * 0.1) - 24;

                    return AnimatedBuilder(
                      animation: Listenable.merge([
                        _progress,
                        _shimmerController,
                        _flagPulseController,
                      ]),
                      builder: (context, _) {
                        final value = _progress.value.clamp(0.0, 100.0);
                        final isComplete = value >= 100;
                        final fillWidth = trackWidth * (value / 100);
                        final dotCenterX = fillWidth.clamp(0.0, trackWidth);

                        final pulseT = _flagPulseController.value;
                        final pulse = isComplete
                            ? (pulseT <= 0.5 ? pulseT * 2 : (1 - pulseT) * 2)
                            : 0.0;
                        final flagGlowScale = isComplete ? 1.0 + (0.4 * pulse) : 1.0;
                        final flagGlowOpacity =
                            isComplete ? 0.6 + (0.4 * pulse) : 1.0;
                        final goalOverflow = widget.showLaunchLabels
                            ? sizes.flagSize * 0.9 + 28
                            : 0;

                        return SizedBox(
                          width: width,
                          height: sizes.dotHeight + goalOverflow,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                right: trackRightInset,
                                top: (sizes.dotHeight - trackHeight) / 2,
                                height: trackHeight,
                                child: _ProgressTrack(
                                  fillWidth: fillWidth,
                                  trackWidth: trackWidth,
                                  isComplete: isComplete,
                                  shimmerValue: _shimmerController.value,
                                ),
                              ),
                              Positioned(
                                left: dotCenterX - sizes.dotWidth / 2,
                                top: 0,
                                child: _ProgressDot(
                                  value: value.round(),
                                  width: sizes.dotWidth,
                                  height: sizes.dotHeight,
                                  fontSize: sizes.percentFontSize,
                                  isComplete: isComplete,
                                ),
                              ),
                              Positioned(
                                right: flagRight,
                                top: (sizes.dotHeight - sizes.flagSize) / 2,
                                child: _GoalFlag(
                                  flagSize: sizes.flagSize,
                                  showGoal: widget.showLaunchLabels,
                                  isComplete: isComplete,
                                  glowScale: flagGlowScale,
                                  glowOpacity: flagGlowOpacity,
                                  goalFontSize: sizes.goalFontSize,
                                  chevronSize: sizes.chevronSize,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (widget.showLaunchLabels)
                Positioned(
                  top: 16,
                  left: 40,
                  right: 40,
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        final sizes = _sizesFor(outerWidth - 80);
                        return Text(
                          'هيا نبدأ 🚀',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: sizes.headerSize,
                            fontWeight: AppFonts.bold,
                            letterSpacing: 0.5,
                            shadows: const [
                              Shadow(
                                color: Color(0x80007BFF),
                                blurRadius: 12,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ResponsiveSizes {
  const _ResponsiveSizes({
    required this.dotWidth,
    required this.dotHeight,
    required this.flagSize,
    required this.headerSize,
    required this.percentFontSize,
    required this.goalFontSize,
    required this.chevronSize,
  });

  final double dotWidth;
  final double dotHeight;
  final double flagSize;
  final double headerSize;
  final double percentFontSize;
  final double goalFontSize;
  final double chevronSize;
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({
    required this.fillWidth,
    required this.trackWidth,
    required this.isComplete,
    required this.shimmerValue,
  });

  final double fillWidth;
  final double trackWidth;
  final bool isComplete;
  final double shimmerValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.examTrackNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.examAccentBlue.withValues(alpha: 0.15),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            offset: Offset(0, 2),
            blurRadius: 6,
            spreadRadius: -2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: fillWidth.clamp(0, trackWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: isComplete
                      ? const [Color(0xFF007BFF), Color(0xFF60A5FA)]
                      : const [
                          Color(0xFF0055CC),
                          Color(0xFF007BFF),
                          Color(0xFF3B82F6),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.examAccentBlue.withValues(
                      alpha: isComplete ? 0.7 : 0.5,
                    ),
                    blurRadius: isComplete ? 25 : 15,
                  ),
                  if (isComplete)
                    BoxShadow(
                      color: AppColors.examAccentBlue.withValues(alpha: 0.3),
                      blurRadius: 50,
                    ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment((shimmerValue * 4) - 2, 0),
                  end: Alignment((shimmerValue * 4) - 1, 0),
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.35, 0.5, 0.65],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(19, (index) {
                  final tall = index % 4 == 0;
                  return Container(
                    width: 1,
                    height: tall ? 10 : 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({
    required this.value,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.isComplete,
  });

  final int value;
  final double width;
  final double height;
  final double fontSize;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isComplete ? 1.03 : 1,
      duration: const Duration(milliseconds: 500),
      child: Container(
        constraints: BoxConstraints(minWidth: width),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.examAccentBlue.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.examAccentBlue.withValues(
                alpha: isComplete ? 0.6 : 0.4,
              ),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.examAccentBlue.withValues(alpha: 0.3),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$value%',
          style: TextStyle(
            color: const Color(0xFF0A1128),
            fontWeight: AppFonts.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class _GoalFlag extends StatelessWidget {
  const _GoalFlag({
    required this.flagSize,
    required this.showGoal,
    required this.isComplete,
    required this.glowScale,
    required this.glowOpacity,
    required this.goalFontSize,
    required this.chevronSize,
  });

  final double flagSize;
  final bool showGoal;
  final bool isComplete;
  final double glowScale;
  final double glowOpacity;
  final double goalFontSize;
  final double chevronSize;

  @override
  Widget build(BuildContext context) {

    final glowColor = AppColors.examAccentBlue.withValues(
      alpha: isComplete ? 0.4 : 0.2,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: flagSize,
          height: flagSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: glowOpacity,
                  child: Transform.scale(
                    scale: glowScale,
                    child: Container(
                      width: flagSize * 2,
                      height: flagSize * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [glowColor, Colors.transparent],
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ExamPennantFilledIcon(
                size: flagSize,
                isComplete: isComplete,
              ),
            ],
          ),
        ),
        if (showGoal) ...[
          const SizedBox(height: 6),
          ExamChevronUpIcon(size: chevronSize),
          const SizedBox(height: 2),
          Text(
            'هدفك 100%',
            style: AppTypography.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: AppFonts.medium,
              fontSize: goalFontSize,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
