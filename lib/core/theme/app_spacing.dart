import 'package:flutter/material.dart';

abstract final class AppSpacing {

  static const double xxs = 2;
  static const double xs = 4;
  static const double xsPlus = 6;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdPlus = 14;
  static const double base = 16;
  static const double basePlus = 17;
  static const double hairline = 1.1;
  static const double lg = 20;
  static const double lgPlus = 25;
  static const double xl = 24;
  static const double xlPlus = 28;
  static const double xxl = 32;
  static const double xxlPlus = 33;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  static const double containerPadding = base;

  static const double pageContentHorizontal = containerPadding;

  static const EdgeInsetsDirectional pageContentHorizontalPadding =
      EdgeInsetsDirectional.symmetric(horizontal: pageContentHorizontal);

  static const double authTopPadding = 96;

  static const double loginHeaderHeight = 90;
  static const double loginHeaderHorizontal = pageContentHorizontal;
  static const double loginBackButtonSize = 40;
  static const double loginLogoTop = 32;
  static const double loginLogoHeight = 96;
  static const double loginTitleTop = 32;
  static const double loginSubtitleTop = 8;
  static const double loginFormTop = 56;
  static const double loginFieldGap = 8;
  static const double loginFieldBlockGap = 24;
  static const double loginButtonTop = 72;
  static const double loginInputHeight = 58;
  static const double loginButtonHeight = 60;
  static const double loginHorizontalPadding = pageContentHorizontal;
  static const double loginCountryBorder = 2;

  static const double authFormPadding = xxxl;

  static const double authFormGap = xxl;

  static const double navDesktopPadding = 150;
  static const double navMobilePadding = pageContentHorizontal;

  /// Web `MobileNav`: `pt-2.5 pb-5 px-4 gap-3` on small screens.
  static const double mobileNavTopPadding = smPlus;
  static const double mobileNavBottomPadding = lg;
  static const double mobileNavItemGap = md;
  static const double mobileNavMenuIconSize = lgPlus;
  static const double mobileNavLogoWidth = 120;
  static const double mobileNavFlagSize = base;
  static const double mobileNavBellMobileScale = 0.8;
  static const double mobileNavBellDesktopScale = 1.0;

  static const double courseCardWidth = 280;

  static const double courseCardProfileHeight = 280;

  static const double courseCardWidthLg = 300;

  static const double courseCardProfileHeightLg = 302;

  static const double courseCardImageHeight = 167.35;

  static const EdgeInsets courseCardPadding = EdgeInsets.fromLTRB(
    xxl,
    lg,
    xxl,
    sm,
  );

  static const double courseCardContentGap = base;

  static const double courseCardIconWidthFactor = 0.65;

  static const double courseCardIconHeight = 140;

  static const double courseCardIconHeightSm = 120;

  static const EdgeInsets courseCardOuterPadding = EdgeInsets.symmetric(
    vertical: md,
    horizontal: sm,
  );

  static const double courseCardFooterPadding = sm;

  static const double courseCardFooterGap = sm;

  static const double courseCardCtaHeight = 50;

  static const double courseCardCtaVerticalPadding = sm;

  static const double courseCardCtaPressScale = 0.95;

  static const double courseListGap = md;

  static const double courseCardTitlePadding = xsPlus;

  static const double incompleteTaskIconSize = 49;

  static const double lessonVideoBadgeWidth = 32;
  static const double lessonVideoBadgeHeight = 22;
  static const double lessonVideoPlaySize = 18;

  static const double profileGap = base;

  static const double tabBarPadding = xs;

  static const double profileTabBarHeight =
      tabBarPadding * 2 + profileTabBarRowHeight * 2 + profileTabBarRowGap;

  static const double profileTabBarRowHeight = 40;

  static const double profileTabBarDesignWidth = 382;

  static const double profileTabBarRowGap = sm;

  static const double incompleteTaskTabBarHeight = 48;

  static const double tabCellVertical = 10;

  static const double buttonHorizontalLg = xxxl;

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: base,
    vertical: md,
  );

  static const EdgeInsets pageHorizontal =
      EdgeInsets.symmetric(horizontal: pageContentHorizontal);

  static const EdgeInsets profileSection = EdgeInsets.symmetric(
    horizontal: base,
    vertical: xl,
  );

  static const EdgeInsetsDirectional profileTabContentPadding =
      EdgeInsetsDirectional.only(bottom: xl);

  static const EdgeInsets screenPadding = EdgeInsets.all(base);

  static const EdgeInsetsDirectional homeListPadding =
      EdgeInsetsDirectional.fromSTEB(xl, 0, xl, xl);

  static const double courseSectionTop = huge;

  static const double courseTitleModuleGap = massive;

  static const double courseTitleScreenInset = 3;

  static const double courseModulesVertical = 120;

  static const double courseModulesHorizontal = pageContentHorizontal;

  static const double courseModuleGap = base;

  static const double courseTitleInner = base;

  static const double courseLessonVertical = md;

  static const double courseLessonIconInset = huge;

  static const double courseLessonLeading = sm;

  static const double courseLessonConnector = md;

  static const double courseLessonLineWidth = 2.5;

  static const double courseModuleGlowHeight = 100;

  static const double courseModuleGlowTop = -80;

  static const double courseModuleOliveIcon = 40;

  static const double courseModuleOliveIconLg = 56;

  static const double courseModuleHeaderInnerGap = sm;

  static const double courseModuleTriggerGap = base;

  static const double courseModuleDescriptionWidthFactor = 0.9;

  static const double lessonNavHeight = 87;

  static const double lessonPageSectionGap = 56;

  static const double lessonMainColumnGap = sm;

  static const double lessonAsideInnerGap = 32;

  static const double lessonAsideBottomPadding = 32;

  static const double lessonAsideWidth = 375;

  static const double lessonAsideHeaderExpanded = 300;

  static const double lessonAsideHeaderCompact = 100;

  static const double wobblyCircleSize = 215;

  static const double lessonAsideHeaderCollapsed = 120;

  static const double wobblyCircleSizeCollapsed = 115;

  static const double lessonListItemHeight = 80;

  static const double lessonActionHeight = 36;

  /// Web chat/files `height: 150`.
  static const double lessonChatFilesHeaderHeight = 150;

  /// Web `h-17 w-17` (4.25rem).
  static const double lessonChatAvatarSize = 68;

  /// Web `min-w-62.5` (15.625rem).
  static const double lessonChatBubbleMinWidth = 250;

  /// Web message `max-h-64`.
  static const double lessonChatMediaMaxHeight = 256;

  /// Web `MessageTextarea` / recording bar `h-[40px]`.
  static const double lessonChatInputHeight = 40;

  /// Web messages container `gap-6`.
  static const double lessonChatMessageGap = 24;

  static const double profileSectionGap = base;

  static const double profileReportsSectionGap = xl;

  static const double profileFilterGap = md;

  static const double profileFilterHeight = 48;

  static const double profileFilterCourseWidth = 336;

  static const double profileFilterModuleWidth = 256;

  static const double awardsContainerMinHeight = 400;

  static const double awardsContainerMaxWidth = 780;

  static const double awardsImageSize = 192;

  /// Web `md:w-54.5` (13.625rem).
  static const double awardsImageSizeMd = 218;

  static const double awardsCarouselGap = xl;

  static const double awardsItemGap = md;

  static const double awardsEmptyTrophySize = 120;

  static const double awardsCertificateSize = 282;

  static const double rankingTablePadding = xl;

  static const double rankingGridGap = md;

  static const double rankingRowPaddingX = base;

  static const double rankingRowPaddingY = 14;

  static const double rankingHeaderPaddingY = 14;

  static const double rankingAvatarCol = 48;

  static const double rankingRankCol = 72;

  static const double rankingPointsCol = 112;

  static const double rankingTableMinWidth = 340;

  static const double rankingRankBadgeSize = 28;

  static const double rankingRankBadgeSizeLg = 32;

  static const double reportCardPadding = xl;

  static const double reportCardGap = base;

  static const double reportStatsGap = base;

  static const double reportIconBox = iconTileLg;

  static const double reportEmptyIconShell = 80;

  static const double reportEmptyPaddingY = 80;

  static const double reportCardTopOffset = sm;

  static const double reportStatusBadgePaddingX = md;

  static const double reportStatusBadgePaddingY = xs;

  static const double reportStatusBadgeGap = xsPlus;

  static const double reportStatusBadgeDot = xsPlus;

  static const double inputHeightDefault = 36;
  static const double inputHeightAuth = 48;

  static const double buttonHeightLg = huge;

  static const double heroButtonVerticalPadding = 11;

  static const double circleButtonPadding = lg;

  static const double iconButtonSize = 40;

  static const double notificationBellOuterSize = 36;

  static const double notificationBellDotSize = md;

  static const double tabIncompleteDotSize = sm;

  static const double tabIncompleteDotInset = xsPlus;

  static const double notificationBellIconWidth = 18;
  static const double notificationBellIconHeight = 18;

  static const double notificationPanelWidth = 300;
  static const double notificationPanelHeight = 400;

  static const double iconTile = 24;
  static const double iconTileLg = 48;

  static const double profileAvatarSize = 96;

  static const double notificationDotSm = 8;
  static const double notificationDotXs = 5;

  static const double breakpointSm = 640;
  static const double breakpointMd = 768;
  static const double breakpointLg = 960;
  static const double breakpointXl = 1200;
  static const double breakpointLessonDesktop = 900;

  static const List<double> mobileWidths = [320, 360, 375, 390, 412, 430];
  static const List<double> tabletWidths = [768, 820, 1024];
}
