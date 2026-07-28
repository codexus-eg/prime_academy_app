import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/contact_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gradient_border.dart';
import '../../data/misc/inquiry_service.dart';
import '../common/site_page.dart';

abstract final class ContactPage {
  static const String routePath = '/contact';
  static const String routeName = 'contact';
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _fullnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  bool _isSubmitting = false;
  Map<String, String> _fieldErrors = {};

  @override
  void dispose() {
    _fullnameCtrl.dispose();
    _phoneCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.bodyMd),
          backgroundColor: error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Map<String, String> _validate() {
    final errors = <String, String>{};
    if (_fullnameCtrl.text.trim().isEmpty) {
      errors['fullname'] = 'الاسم مطلوب';
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      errors['phone_number'] = 'رقم الهاتف مطلوب';
    }
    if (_contentCtrl.text.trim().isEmpty) {
      errors['content'] = 'الرسالة مطلوبة';
    }
    return errors;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final errors = _validate();
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      _showToast('يرجى ملئ الحقول ببيانات صحيحة', error: true);
      return;
    }

    setState(() {
      _fieldErrors = {};
      _isSubmitting = true;
    });

    try {
      await InquiryService.addInquiry(
        fullname: _fullnameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
      );
      if (!mounted) return;
      _showToast('تم ارسال الرسالة');
      _fullnameCtrl.clear();
      _phoneCtrl.clear();
      _contentCtrl.clear();
    } on InquiryException catch (error) {
      if (!mounted) return;
      setState(() => _fieldErrors = error.fieldErrors ?? {});
      _showToast('حدث خطأ يرجى المحاولة في وقت لاحق', error: true);
    } catch (_) {
      if (!mounted) return;
      _showToast('حدث خطأ يرجى المحاولة في وقت لاحق', error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 1024;
    final isMedium = screenWidth >= 640;

    return SitePageScaffold(
      maxContentWidth: 1200,
      children: [
        const SiteHeroTitle(text: 'تواصل معنا'),
        const SizedBox(height: 64),

        Text(
          'لديك أي أسئلة ؟',
          textAlign: TextAlign.center,
          style: AppTypography.custom(
            fontSize: isMedium ? 30 : 24,
            fontWeight: AppFonts.semibold,
            color: AppColors.onDark,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMedium ? 600 : 300),
            child: Text(
              'نحن هنا لدعمك والإجابة على جميع استفساراتك واحتياجاتك التعليمية. '
              'لا تتردد في الاتصال بنا للحصول على المساعدة وتقديم ملاحظاتك',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                fontSize: 17,
                color: AppColors.textMuted,
                height: 1.7,
              ),
            ),
          ),
        ),
        const SizedBox(height: 64),

        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildForm(isMedium)),
              const SizedBox(width: 96),
              SiteStoryIllustration(isMedium: isMedium),
            ],
          )
        else ...[
          _buildForm(isMedium),
          const SizedBox(height: 48),
          Center(child: SiteStoryIllustration(isMedium: isMedium)),
        ],

        const SizedBox(height: 64),
        _SocialSection(onOpen: _openUrl),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildForm(bool isMedium) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 550),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMedium)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ContactField(
                    controller: _fullnameCtrl,
                    hint: 'اسمك بالكامل',
                    icon: Icons.person_outline,
                    error: _fieldErrors['fullname'],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ContactField(
                    controller: _phoneCtrl,
                    hint: 'رقم هاتفك المحمول',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    error: _fieldErrors['phone_number'],
                    inputFormatters: [_PhoneInputFormatter()],
                  ),
                ),
              ],
            )
          else ...[
            _ContactField(
              controller: _fullnameCtrl,
              hint: 'اسمك بالكامل',
              icon: Icons.person_outline,
              error: _fieldErrors['fullname'],
            ),
            const SizedBox(height: 16),
            _ContactField(
              controller: _phoneCtrl,
              hint: 'رقم هاتفك المحمول',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              error: _fieldErrors['phone_number'],
              inputFormatters: [_PhoneInputFormatter()],
            ),
          ],
          const SizedBox(height: 16),
          _ContactField(
            controller: _contentCtrl,
            hint: 'اكتب رسالتك',
            icon: Icons.send_outlined,
            maxLines: 5,
            minHeight: 150,
            error: _fieldErrors['content'],
          ),
          const SizedBox(height: 24),
          _HeroSubmitButton(
            isLoading: _isSubmitting,
            onTap: _handleSubmit,
          ),
        ],
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.minHeight,
    this.error,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final double? minHeight;
  final String? error;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final borderColor = error != null ? AppColors.error : AppColors.borderSubtle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight ?? 0,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: AppTypography.bodyLg.copyWith(color: AppColors.onDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  AppTypography.bodyLg.copyWith(color: AppColors.textMuted),
              prefixIcon: Icon(icon, color: AppColors.rankSilver, size: 16),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              filled: false,
              alignLabelWithHint: maxLines > 1,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: maxLines > 1 ? 16 : 20,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderTailwindXl,
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderTailwindXl,
                borderSide: BorderSide(
                  color: error != null ? AppColors.error : AppColors.blue,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: AppTypography.bodySm.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.replaceAll(RegExp(r'[^0-9+\s-]'), '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class _HeroSubmitButton extends StatefulWidget {
  const _HeroSubmitButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_HeroSubmitButton> createState() => _HeroSubmitButtonState();
}

class _HeroSubmitButtonState extends State<_HeroSubmitButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1,
        duration: const Duration(milliseconds: 250),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderTailwindXl,
            boxShadow: AppShadows.buttonRest,
          ),
          child: GradientBorder(
            borderRadius: AppRadius.borderTailwindXl,
            backgroundColor: AppColors.surfaceElevated,
            padding: EdgeInsets.zero,
            child: Material(
              color: AppColors.transparent,
              borderRadius: AppRadius.borderTailwindXl,
              child: InkWell(
                onTap: widget.isLoading ? null : widget.onTap,
                borderRadius: AppRadius.borderTailwindXl,
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onDark,
                            ),
                          )
                        : Text(
                            'Send',
                            style: AppTypography.custom(
                              fontSize: 20,
                              fontWeight: AppFonts.semibold,
                              color: AppColors.onDark,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialSection extends StatelessWidget {
  const _SocialSection({required this.onOpen});

  final Future<void> Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = screenWidth >= 1024
        ? 800.0
        : screenWidth >= 768
            ? 600.0
            : double.infinity;
    final horizontalPadding = screenWidth >= 640 ? 50.0 : 16.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderProfileCourse,
            boxShadow: AppShadows.buttonRest,
          ),
          child: GradientBorder(
            borderRadius: AppRadius.borderProfileCourse,
            backgroundColor: AppColors.surfaceElevated,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 32,
            ),
            child: Column(
              children: [
                Text(
                  'او راسلنا عبر مواقع التواصل الاجتماعي',
                  textAlign: TextAlign.center,
                  style: AppTypography.custom(
                    fontSize: screenWidth >= 640 ? 24 : 17,
                    color: AppColors.onDark,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < ContactContent.socialIcons.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      _SocialIconButton(
                        icon: ContactContent.socialIcons[i],
                        onTap: () => onOpen(ContactContent.socialIcons[i].url),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIconButton extends StatefulWidget {
  const _SocialIconButton({required this.icon, required this.onTap});

  final ContactSocialIcon icon;
  final VoidCallback onTap;

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.15 : 1,
        duration: const Duration(milliseconds: 400),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            customBorder: const CircleBorder(),
            child: Ink(
              decoration: BoxDecoration(
                color: widget.icon.backgroundColor,
                gradient: widget.icon.gradient,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: widget.icon.padding,
                child: Icon(
                  widget.icon.icon,
                  color: AppColors.onDark,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
