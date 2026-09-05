import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../home_tab.dart';

class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    super.key,
    required this.activeTab,
    this.showIncompleteDot = false,
  });

  final HomeTab activeTab;
  final bool showIncompleteDot;

  static const _tabs = [
    HomeTab.courses,
    HomeTab.reports,
    HomeTab.ranking,
    HomeTab.awards,
    HomeTab.incompleteTasks,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final barWidth = screenWidth < AppSpacing.profileTabBarDesignWidth
        ? screenWidth
        : AppSpacing.profileTabBarDesignWidth;

    return Center(
      child: SizedBox(
        width: barWidth,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppColors.mainBg2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.smPlus),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.tabBarPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: AppSpacing.profileTabBarRowHeight,
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: _TabCell(
                            tab: _tabs[i],
                            activeTab: activeTab,
                            showIncompleteDot: showIncompleteDot,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.profileTabBarRowGap),
                SizedBox(
                  height: AppSpacing.profileTabBarRowHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabCell(
                          tab: _tabs[3],
                          activeTab: activeTab,
                          showIncompleteDot: showIncompleteDot,
                        ),
                      ),

                      Expanded(
                        flex: 2,
                        child: _TabCell(
                          tab: _tabs[4],
                          activeTab: activeTab,
                          showIncompleteDot: showIncompleteDot,
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

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.tab,
    required this.activeTab,
    required this.showIncompleteDot,
  });

  final HomeTab tab;
  final HomeTab activeTab;
  final bool showIncompleteDot;

  @override
  Widget build(BuildContext context) {
    final isActive = tab == activeTab;
    final showDot =
        tab == HomeTab.incompleteTasks && showIncompleteDot;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => context.go(tab.routePath),
          borderRadius: AppRadius.borderTabCell,
          hoverColor: AppColors.mainBg2Half,
          splashColor: AppColors.mainBg2Half,
          highlightColor: AppColors.mainBg2Half,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: isActive ? AppGradients.homeTabActive : null,
              borderRadius: AppRadius.borderTabCell,
              boxShadow: isActive ? AppShadows.tabActive : null,
            ),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Align(
                alignment: tab == HomeTab.incompleteTasks
                    ? Alignment.centerRight
                    : Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: showDot ? AppSpacing.base : AppSpacing.xs,
                        end: AppSpacing.xs,
                        top: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: tab == HomeTab.incompleteTasks
                            ? Alignment.centerRight
                            : Alignment.center,
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          textAlign: tab == HomeTab.incompleteTasks
                              ? TextAlign.right
                              : TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: AppTypography.tab.copyWith(
                            color: isActive
                                ? AppColors.onDark
                                : AppColors.tabInactive,
                            fontWeight: AppFonts.medium,
                          ),
                        ),
                      ),
                    ),

                    if (showDot)
                      Positioned(
                        top: AppSpacing.tabIncompleteDotInset,
                        left: AppSpacing.tabIncompleteDotInset - 15,
                        child: const _NotificationDot(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.tabIncompleteDotSize,
      height: AppSpacing.tabIncompleteDotSize,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}
