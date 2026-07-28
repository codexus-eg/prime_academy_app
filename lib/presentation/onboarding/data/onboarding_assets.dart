import 'package:flutter/material.dart';

abstract final class OnboardingAssets {
  static const _base = 'assets/web/landing_page/';

  static const gifWelcome =
      '${_base}ezgif-70a66403487d80-ezgif-com-optimize-1.gif';

  static const gifBookMobile =
      '${_base}FinalBookMobile-ezgif.com-optimize.gif';

  static const gifDeskScene =
      '${_base}NewDeskFullScene-ezgif.com-optimize.gif';
}

class OnboardingSlideData {
  const OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.gifAsset,
    this.titleAlign = TextAlign.center,
  });

  final String title;
  final String subtitle;
  final String gifAsset;
  final TextAlign titleAlign;
}

abstract final class OnboardingSlides {
  static const items = [
    OnboardingSlideData(
      title: 'مرحباً بك في برايم أكاديمي',
      subtitle: 'منصة تعليمية ذكية تساعدك على التعلم بأسلوب يناسبك',
      gifAsset: OnboardingAssets.gifWelcome,
    ),
    OnboardingSlideData(
      title: 'ابدأ بالتعلم مع برايم أكاديمي',
      subtitle: 'تدري شنو؟ النجاح صار مرررره سهل !',
      gifAsset: OnboardingAssets.gifBookMobile,
    ),
    OnboardingSlideData(
      title: 'في برايم أكاديمي',
      subtitle:
          'لا تخاف تنسى الفيديوهات عندك، تعيدها متى ما تبي، ومرات قد ما تبي!',
      gifAsset: OnboardingAssets.gifDeskScene,
    ),
  ];
}
