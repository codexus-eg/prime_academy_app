import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/platform_view_occlusion.dart';
import '../../../data/auth/auth_controller.dart';
import '../../../data/auth/auth_session.dart';
import '../../auth/login_page.dart';
import '../home_page.dart';
import 'app_drawer.dart';
import 'home_top_bar.dart';

/// Global mobile nav + drawer, matching web `MobileNav` on every route.
class AppNavScaffold extends StatefulWidget {
  const AppNavScaffold({
    super.key,
    required this.body,
    this.backgroundColor,
    this.topBarBackground,
    this.showTopBarBorder = true,
    this.showLogo = true,
  });

  final Widget body;
  final Color? backgroundColor;
  final Color? topBarBackground;
  final bool showTopBarBorder;
  final bool showLogo;

  @override
  State<AppNavScaffold> createState() => _AppNavScaffoldState();
}

class _AppNavScaffoldState extends State<AppNavScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> _drawerOpen = ValueNotifier(false);

  AuthController get _auth => AuthController.instance;

  bool get _showAuthenticatedNav =>
      _auth.isResolved && _auth.isAuthenticated;

  bool get _showNotifications {
    if (!_showAuthenticatedNav) return false;
    final role = _auth.user?.role;
    return role != null && role != 0;
  }

  AuthUser? get _user => _auth.user;

  void _onLogoTap() {
    final destination = _showAuthenticatedNav
        ? HomePage.routePath
        : LoginPage.routePath;
    context.go(destination);
  }

  @override
  void dispose() {
    _drawerOpen.dispose();
    super.dispose();
  }

  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        return PlatformViewOcclusion(
          notifier: _drawerOpen,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor:
                widget.backgroundColor ?? AppTheme.coursePageBackground,
            drawerScrimColor: AppColors.overlayBlack80,
            onDrawerChanged: (opened) => _drawerOpen.value = opened,
            drawer: AppDrawer(user: _user),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.topBarBackground,
                      border: widget.showTopBarBorder
                          ? const Border(
                              bottom: BorderSide(
                                width: 1,
                                color: AppTheme.mobileNavBorder,
                              ),
                            )
                          : null,
                    ),
                    child: HomeTopBar(
                      showLogo: widget.showLogo,
                      showNotifications: _showNotifications,
                      onMenuTap: _openMenu,
                      onLogoTap: _onLogoTap,
                    ),
                  ),
                  Expanded(child: widget.body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
