import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/onboarding/onboarding_storage.dart';
import '../auth/login_page.dart';
import 'data/onboarding_assets.dart';
import 'widgets/onboarding_shared.dart';
import 'widgets/onboarding_slide.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String routePath = '/onboarding';
  static const String routeName = 'onboarding';
  static const pageCount = 3;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  var _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToLogin() async {
    await OnboardingStorage.markCompleted();
    if (!mounted) return;
    context.go(LoginPage.routePath);
  }

  void _onNext() {
    if (_currentPage >= OnboardingPage.pageCount - 1) {
      _goToLogin();
      return;
    }
    _pageController.nextPage(
      duration: AppDurations.onboardingPage,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBg2,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: OnboardingSlides.items.length,
                itemBuilder: (context, index) {
                  return OnboardingSlide(
                    data: OnboardingSlides.items[index],
                    isActive: index == _currentPage,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OnboardingPageIndicator(activeIndex: _currentPage),
            const SizedBox(height: AppSpacing.xl),
            OnboardingActions(
              onNext: _onNext,
              onSkip: _goToLogin,
            ),
          ],
        ),
      ),
    );
  }
}
