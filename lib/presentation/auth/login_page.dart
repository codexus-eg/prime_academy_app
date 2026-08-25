import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_formatter.dart';
import '../../core/widgets/legal_policy_links.dart';
import '../../data/auth/auth_service.dart';
import '../../data/students/home_bootstrap.dart';
import '../home/widgets/app_nav_scaffold.dart';
import '../home/widgets/notification_navigator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const String routePath = '/';
  static const String routeName = 'login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();

  String? _phoneError;
  String? _apiError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _restoreExistingSession();
    _phoneController.addListener(() {
      if (_apiError != null) setState(() => _apiError = null);
    });
  }

  Future<void> _restoreExistingSession() async {
    final restored = await AuthService.restoreSession();
    if (!mounted || !restored) return;
    await _warmHomeAndNavigate();
  }

  Future<void> _warmHomeAndNavigate() async {
    try {
      await HomeBootstrap.warm(context);
    } catch (_) {
      // Home will fetch if warmup fails.
    }
    if (!mounted) return;
    await NotificationNavigator.openAfterAuth(context);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rawPhone = _phoneController.text.trim();
    final normalized = PhoneFormatter.normalize(rawPhone);

    setState(() {
      _phoneError = rawPhone.isEmpty
          ? 'رقم الهاتف مطلوب'
          : normalized == null
              ? 'يرجى إدخال رقم هاتف صالح'
              : null;
      _apiError = null;
    });

    if (_phoneError != null || normalized == null) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.loginWithPhone(normalized);
      if (!mounted) return;
      await _warmHomeAndNavigate();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _apiError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _apiError = 'حدث خطأ أثناء تسجيل الدخول، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageContentHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.loginLogoTop),
            Center(
              child: Image.asset(
                'assets/images/logo_prime.webp',
                height: AppSpacing.loginLogoHeight,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.loginTitleTop),
            Text(
              'مرحباً بك يابطل',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTypography.loginWelcome.copyWith(
                color: AppColors.onDark,
              ),
            ),
            const SizedBox(height: AppSpacing.loginSubtitleTop),
            Text(
              'أدخل رقم هاتفك للمتابعة',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: AppTypography.loginSubtitle,
            ),
            const SizedBox(height: AppSpacing.loginFormTop),
            _LoginField(
              label: 'رقم الهاتف',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              borderColor: AppTheme.fieldBorderEmail,
              errorText: _phoneError,
              textDirection: TextDirection.ltr,
              onSubmitted: _submit,
              onChanged: (_) {
                if (_phoneError != null || _apiError != null) {
                  setState(() {
                    _phoneError = null;
                    _apiError = null;
                  });
                }
              },
            ),
            if (_apiError != null) ...[
              const SizedBox(height: AppSpacing.base),
              Text(
                _apiError!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.loginButtonTop),
            _LoginSubmitButton(
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: AppSpacing.xl),
            const LegalPolicyLinks(),
            const SizedBox(height: AppSpacing.pageContentHorizontal),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.borderColor,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.textDirection,
    this.onSubmitted,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final Color borderColor;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final TextDirection? textDirection;
  final Future<void> Function()? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTypography.loginFieldLabel.copyWith(
              color: AppColors.onDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.loginFieldGap),
        SizedBox(
          height: AppSpacing.loginInputHeight,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textAlign: TextAlign.right,
            textDirection: textDirection ?? TextDirection.rtl,
            onChanged: onChanged,
            onSubmitted:
                onSubmitted != null ? (_) => onSubmitted!() : null,
            style: AppTypography.bodyLg.copyWith(color: AppColors.onDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.loginInputHint,
              filled: true,
              fillColor: AppTheme.fieldFill,
              contentPadding: const EdgeInsets.all(AppSpacing.base),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderAuthForm,
                borderSide: BorderSide(
                  width: AppSpacing.hairline,
                  color: borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderAuthForm,
                borderSide: BorderSide(
                  width: AppSpacing.hairline,
                  color: borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderAuthForm,
                borderSide: BorderSide(
                  width: AppSpacing.hairline,
                  color: borderColor,
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            textAlign: TextAlign.right,
            style: AppTypography.bodySm.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _LoginSubmitButton extends StatelessWidget {
  const _LoginSubmitButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.borderReportChip,
        child: Ink(
          height: AppSpacing.loginButtonHeight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageContentHorizontal,
            vertical: AppSpacing.xsPlus,
          ),
          decoration: BoxDecoration(
            gradient: AppGradients.loginSubmitRtl,
            borderRadius: AppRadius.borderReportChip,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onDark,
                    ),
                  )
                : Text(
                    'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: AppTypography.loginButtonText.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
