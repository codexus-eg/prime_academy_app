import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/auth/auth_session.dart';
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
  });

  final Widget body;
  final Color? backgroundColor;
  final Color? topBarBackground;
  final bool showTopBarBorder;

  @override
  State<AppNavScaffold> createState() => _AppNavScaffoldState();
}

class _AppNavScaffoldState extends State<AppNavScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthSession.load();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _openMenu() async {
    await _loadUser();
    if (!mounted) return;
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.backgroundColor ?? AppTheme.coursePageBackground,
      drawerScrimColor: AppColors.overlayBlack80,
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
                onMenuTap: _openMenu,
              ),
            ),
            Expanded(child: widget.body),
          ],
        ),
      ),
    );
  }
}
