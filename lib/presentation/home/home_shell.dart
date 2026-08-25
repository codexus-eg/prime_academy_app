import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/images/network_image_precache.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../data/auth/auth_session.dart';
import '../../data/students/student_profile.dart';
import '../../data/students/student_profile_cache.dart';
import '../../data/students/students_api.dart';
import 'home_tab.dart';
import 'student_profile_scope.dart';
import 'widgets/app_nav_scaffold.dart';
import 'widgets/home_profile_section.dart';
import 'widgets/home_tab_bar.dart';
import 'widgets/home_tab_content_transition.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  StudentProfile? _profile;
  AuthUser? _authUser;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAuthUser();
    final cached = StudentProfileCache.profile;
    if (cached != null) {
      _profile = cached;
      if (!StudentProfileCache.visualsReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          NetworkImagePrecache.precacheHomeVisuals(context, cached).then((_) {
            StudentProfileCache.store(cached, visualsReady: true);
          });
        });
      }
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadAuthUser() async {
    final user = await AuthSession.load();
    if (!mounted) return;
    setState(() => _authUser = user);
  }

  Future<void> _loadProfile() async {
    setState(() => _errorMessage = null);

    try {
      final profile = await StudentsApi.fetchMyProfile();
      if (!mounted) return;

      if (!StudentProfileCache.visualsReady) {
        await NetworkImagePrecache.precacheHomeVisuals(context, profile);
        if (!mounted) return;
      }

      StudentProfileCache.store(profile, visualsReady: true);
      setState(() => _profile = profile);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'حدث خطأ أثناء تحميل البيانات');
    }
  }

  Future<void> _refreshProfileAfterAvatarUpload() async {
    try {
      final profile = await StudentsApi.fetchMyProfile();
      if (!mounted) return;
      await NetworkImagePrecache.precacheHomeVisuals(context, profile);
      if (!mounted) return;
      StudentProfileCache.store(profile, visualsReady: true);
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
      isLoading: false,
      errorMessage: _errorMessage,
      onRetry: _loadProfile,
      child: AppNavScaffold(
        backgroundColor: AppTheme.coursePageBackground,
        body: CustomScrollView(
            slivers: [
              if (_errorMessage != null && _profile == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: AppSpacing.pageContentHorizontalPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.base),
                          TextButton(
                            onPressed: _loadProfile,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
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
                  SliverPadding(
                    padding: AppSpacing.pageContentHorizontalPadding,
                    sliver: SliverToBoxAdapter(
                      child: HomeTabContentTransition(
                        tab: activeTab,
                        child: widget.child,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
              ],
            ],
          ),
      ),
    );
  }
}
