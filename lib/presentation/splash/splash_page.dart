import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/auth/auth_service.dart';
import '../home/home_page.dart';
import '../onboarding/onboarding_page.dart';
import 'data/splash_frames.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  static const String routePath = '/splash';
  static const String routeName = 'splash';

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  int _frameIndex = 0;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    for (var i = 1; i < SplashFrames.frames.length; i++) {
      await Future<void>.delayed(SplashFrames.frameInterval);
      if (!mounted) return;
      setState(() => _frameIndex = i);
    }

    await Future<void>.delayed(SplashFrames.frameInterval);
    if (!mounted) return;

    final restored = await AuthService.restoreSession();
    if (!mounted) return;

    if (restored) {
      context.go('${HomePage.routePath}/courses');
      return;
    }

    context.go(OnboardingPage.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final frame = SplashFrames.frames[_frameIndex];

    return Scaffold(
      backgroundColor: AppColors.mainBg2,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / SplashFrames.designWidth;
          final scaleY = constraints.maxHeight / SplashFrames.designHeight;
          final blobSize = SplashFrames.blobSize * scaleX;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const _SplashBackdrop(),
              _AnimatedBlob(
                duration: SplashFrames.frameInterval,
                left: frame.primary.left * scaleX,
                top: frame.primary.top * scaleY,
                size: blobSize,
                opacity: 0.97,
                reversed: frame.primary.reversed,
              ),
              _AnimatedBlob(
                duration: SplashFrames.frameInterval,
                left: frame.secondary.left * scaleX,
                top: frame.secondary.top * scaleY,
                size: blobSize,
                opacity: 0.53,
                reversed: frame.secondary.reversed,
              ),
              Align(
                alignment: const Alignment(0, 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo_prime.png',
                      width: 256,
                      height: 128,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _SplashDots(dotsArePurple: frame.dotsArePurple),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.splashBackground,
        ),
      ),
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  const _AnimatedBlob({
    required this.duration,
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
    required this.reversed,
  });

  final Duration duration;
  final double left;
  final double top;
  final double size;
  final double opacity;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: duration,
      curve: Curves.easeInOutCubic,
      left: left,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: SplashFrames.glowBlurSigma,
            sigmaY: SplashFrames.glowBlurSigma,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.splashBlobGlow(reversed: reversed),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SplashFrames.blobGradient(reversed: reversed),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashDots extends StatelessWidget {
  const _SplashDots({required this.dotsArePurple});

  final List<bool> dotsArePurple;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < dotsArePurple.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          AnimatedContainer(
            duration: SplashFrames.frameInterval,
            curve: Curves.easeInOutCubic,
            width: AppSpacing.md,
            height: AppSpacing.md,
            decoration: BoxDecoration(
              gradient: dotsArePurple[i]
                  ? SplashFrames.purpleGradient
                  : SplashFrames.orangeGradient,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
