import '../config/cdn_config.dart';

class CourseVisuals {
  const CourseVisuals({
    this.iconUrl,
    this.backgroundUrl,
  });

  final String? iconUrl;
  final String? backgroundUrl;
}

abstract final class CourseAssets {
  static const _icons = {
    'ENGLISH': 'courses/icons/icon-english.avif',
    'ARABIC': 'courses/icons/icon-arabic.avif',
    'MATHEMATICS': 'courses/icons/icon-mathematics.avif',
    'PHYSICS': 'courses/icons/icon-physics.avif',
    'CHEMISTRY': 'courses/icons/icon-chemistry.avif',
    'SCIENCE': 'courses/icons/icon-chemistry.avif',
    'BIOLOGY': 'courses/icons/icon-biology.avif',
    'ISLAM': 'courses/icons/icon-islam.avif',
    'COMPUTER_SCIENCE': 'courses/icons/icon-computer-science.avif',
    'STATISTICS': 'courses/icons/icon-statistics.avif',
    'FRENCH': 'courses/icons/icon-french.avif',
    'GEOLOGY': 'courses/icons/icon-geology.avif',
    'KUWAIT_HISTORY': 'courses/icons/icon-kuwait-history.avif',
    'SOCIAL_STUDIES': 'courses/icons/icon-ns.avif',
    'PHSYCOLOGY': 'courses/icons/icon-psychology.avif',
    'NS': 'courses/icons/icon-ns.avif',
    'DUSTOOR': 'courses/icons/icon-dustoor.avif',
  };

  static const _backgrounds = {
    'ENGLISH': 'courses/bgs/bg-english1.png',
    'ARABIC': 'courses/bgs/bg-arabic1.png',
    'MATHEMATICS': 'courses/bgs/bg-mathematics1.png',
    'PHYSICS': 'courses/bgs/bg-physics.png',
    'CHEMISTRY': 'courses/bgs/bg-chemistry1.png',
    'SCIENCE': 'courses/bgs/bg-chemistry1.png',
    'BIOLOGY': 'courses/bgs/bg-biology.png',
    'ISLAM': 'courses/bgs/bg-islam.png',
    'COMPUTER_SCIENCE': 'courses/bgs/bg-computer-science.png',
    'STATISTICS': 'courses/bgs/bg-statistics.png',
    'FRENCH': 'courses/bgs/bg-french.png',
    'GEOLOGY': 'courses/bgs/bg-geology.png',
    'KUWAIT_HISTORY': 'courses/bgs/bg-kuwait-history.png',
    'SOCIAL_STUDIES': 'courses/bgs/bg-ns1.png',
    'PHSYCOLOGY': 'courses/bgs/bg-psychology.png',
    'NS': 'courses/bgs/bg-ns1.png',
    'DUSTOOR': 'courses/bgs/bg-dustoor.png',
  };

  static CourseVisuals resolve(String? type) {
    final key = (type ?? '').toUpperCase();
    final iconPath = _icons[key];
    final backgroundPath = _backgrounds[key] ?? _backgrounds['ENGLISH']!;

    return CourseVisuals(
      iconUrl: iconPath != null ? CdnConfig.staticUrl(iconPath) : null,
      backgroundUrl: CdnConfig.staticUrl(backgroundPath),
    );
  }
}
