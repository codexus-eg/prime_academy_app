import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_session.dart';
import '../../data/students/student_profile.dart';
import '../../data/students/students_api.dart';
import 'home_tab.dart';
import 'student_profile_scope.dart';
import 'widgets/app_drawer.dart';
import 'widgets/home_profile_section.dart';
import 'widgets/home_tab_bar.dart';
import 'widgets/home_top_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  StudentProfile? _profile;
  AuthUser? _authUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAuthUser();
    _loadProfile();
  }

  Future<void> _loadAuthUser() async {
    final user = await AuthSession.load();
    if (!mounted) return;
    setState(() => _authUser = user);
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await StudentsApi.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProfileAfterAvatarUpload() async {
    try {
      final profile = await StudentsApi.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع الصورة لكن تعذّر تحديث الملف الشخصي')),
      );
    }
  }

  String get _displayName {
    final profileName = _profile?.name.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;
    final authName = _authUser?.name.trim() ?? '';
    if (authName.isNotEmpty) return authName;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final activeTab = HomeTab.fromLocation(location) ?? HomeTab.defaultTab;

    return StudentProfileScope(
      profile: _profile,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onRetry: _loadProfile,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.coursePageBackground,
        drawerScrimColor: AppColors.overlayBlack80,
        drawer: AppDrawer(user: _authUser),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 1,
                        color: AppTheme.mobileNavBorder,
                      ),
                    ),
                  ),
                  child: HomeTopBar(
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: HomeProfileSection(
                  userName: _displayName,
                  avatarUrl: _profile?.imageUrl,
                  onAvatarUploaded: _refreshProfileAfterAvatarUpload,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.md),
              ),
              SliverPadding(
                padding: AppSpacing.pageContentHorizontalPadding,
                sliver: SliverToBoxAdapter(
                  child: HomeTabBar(
                    activeTab: activeTab,
                    showIncompleteDot: _profile?.hasIncomplete ?? false,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.base),
              ),
              if (activeTab == HomeTab.reports || activeTab == HomeTab.ranking)
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Padding(
                    padding: AppSpacing.pageContentHorizontalPadding,
                    child: widget.child,
                  ),
                )
              else
                SliverPadding(
                  padding: AppSpacing.pageContentHorizontalPadding,
                  sliver: SliverToBoxAdapter(child: widget.child),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
