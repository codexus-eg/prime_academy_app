import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/nav_links.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/auth/auth_navigation.dart';
import '../../../data/auth/auth_service.dart';
import '../../../data/auth/auth_session.dart';
import '../../auth/login_page.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, required this.user});

  final AuthUser? user;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;

  static const double _widthMobile = 300;
  static const double _widthWide = 350;
  static const double _smBreakpoint = 640;

  bool get _isAuthenticated => widget.user != null;

  bool get _isStudent => widget.user?.role == 1;

  String get _profileRedirect => '/home';

  String get _roleLabel {
    switch (widget.user?.role) {
      case 1:
        return 'طالب';
      case 2:
        return 'معلم';
      case 0:
        return 'مشرف';
      case 3:
        return 'مساعد';
      default:
        return '';
    }
  }

  void _closeDrawer() {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _navigate(String path) {
    _closeDrawer();

    if (path == '/home') {
      context.go(path);
    } else {
      context.push(path);
    }
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeletingAccount) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'هل أنت متأكد من حذف حسابك نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await AuthService.deleteMyAccount();
      if (!mounted) return;
      _closeDrawer();
      await AuthNavigation.finishLocalSignOut();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isDeletingAccount = false);
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      _closeDrawer();
      await AuthNavigation.signOut();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width >= _smBreakpoint ? _widthWide : _widthMobile;

    return Drawer(
      width: width,
      backgroundColor: AppColors.primaryBg,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              userName: widget.user?.name ?? '',
              roleLabel: _roleLabel,
              showUser: widget.user != null,
              onClose: _closeDrawer,
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_isAuthenticated) ...[
                              SizedBox(
                                width: double.infinity,
                                child: _ProfileButton(
                                  onTap: () => _navigate(_profileRedirect),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                child: _LoginButton(
                                  onTap: () {
                                    _closeDrawer();
                                    context.go(LoginPage.routePath);
                                  },
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            for (var i = 0; i < NavLinks.links.length; i++) ...[
                              SizedBox(
                                width: double.infinity,
                                child: _NavLinkRow(
                                  label: NavLinks.links[i].label,
                                  icon: _iconForIndex(i),
                                  onTap: () => _navigate(NavLinks.links[i].to),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (_isStudent) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.overlayWhite4,
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: _LogoutButton(
                                  isLoading: _isLoggingOut,
                                  onTap: _handleLogout,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_isStudent)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: _DeleteAccountButton(
                            isLoading: _isDeletingAccount,
                            onTap: _handleDeleteAccount,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.menu_book;
      case 1:
        return Icons.mail_outline;
      default:
        return Icons.circle;
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.userName,
    required this.roleLabel,
    required this.showUser,
    required this.onClose,
  });

  final String userName;
  final String roleLabel;
  final bool showUser;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(

      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.overlayWhite4, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showUser)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.rankBlueGlow20,
                          AppColors.blueLightGlow10,
                        ],
                      ),
                      borderRadius: AppRadius.borderTailwindXl,
                      border: Border.all(color: AppColors.rankBlueGlow20),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.blueLight,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: AppFonts.semibold,
                            color: AppColors.onDark,
                          ),
                        ),
                        Text(
                          roleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          _IconTile(
            icon: Icons.close,
            iconColor: AppColors.onDark,
            iconSize: 20,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mainBg3,
      borderRadius: AppRadius.borderTailwindXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderTailwindXl,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderTailwindXl,
            border: Border.all(color: AppColors.overlayWhite6),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(

      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.borderTailwindXl,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderTailwindXl,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.rankBlueGlow20, AppColors.blueLightGlow10],
              ),
              borderRadius: AppRadius.borderTailwindXl,
              border: Border.all(color: AppColors.rankBlueBorder30),
            ),
            child: const Padding(

              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'حسابي',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppFonts.bahij,
                      fontSize: 16,
                      fontWeight: AppFonts.medium,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.person, color: AppColors.blueLight, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: AppRadius.borderTailwindXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderTailwindXl,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.rankBlueGlow20, AppColors.blueLightGlow10],
            ),
            borderRadius: AppRadius.borderTailwindXl,
            border: Border.all(color: AppColors.rankBlueBorder30),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'تسجيل الدخول',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFonts.bahij,
                    fontSize: 16,
                    fontWeight: AppFonts.medium,
                    color: AppColors.onDark,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.login_rounded, color: AppColors.blueLight, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLinkRow extends StatelessWidget {
  const _NavLinkRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: AppRadius.borderTailwindXl,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderTailwindXl,
        hoverColor: AppColors.overlayWhite4,
        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFonts.bahij,
                  fontSize: 16,
                  fontWeight: AppFonts.medium,
                  color: AppColors.onDark.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                color: AppColors.onDark.withValues(alpha: 0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: AppRadius.borderTailwindXl,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: AppRadius.borderTailwindXl,
        hoverColor: AppColors.errorGlow20,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.errorGlow10,
            borderRadius: AppRadius.borderTailwindXl,
            border: Border.all(color: AppColors.errorGlow20),
          ),
          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'تسجيل الخروج',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFonts.bahij,
                    fontSize: 16,
                    fontWeight: AppFonts.medium,
                    color: AppColors.errorSoft,
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.errorSoft,
                    ),
                  )
                else
                  const Icon(
                    Icons.logout,
                    color: AppColors.errorSoft,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      borderRadius: AppRadius.borderTailwindXl,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: AppRadius.borderTailwindXl,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderTailwindXl,
            border: Border.all(color: AppColors.overlayWhite4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'حذف حسابي',
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.tabInactive,
                    fontWeight: AppFonts.medium,
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.person_remove_outlined,
                    color: AppColors.tabInactive.withValues(alpha: 0.8),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
