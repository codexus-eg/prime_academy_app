import 'package:flutter/material.dart';

import '../../core/constants/contact_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/gradient_border.dart';
import '../home/widgets/app_nav_scaffold.dart';

class SitePageScaffold extends StatelessWidget {
  const SitePageScaffold({
    super.key,
    required this.children,
    this.maxContentWidth = 640,
  });

  final List<Widget> children;

  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return AppNavScaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class SiteHeroTitle extends StatelessWidget {
  const SiteHeroTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderProfileCourse,
          boxShadow: AppShadows.buttonRest,
        ),
        child: GradientBorder(
          borderRadius: AppRadius.borderProfileCourse,
          backgroundColor: AppColors.surfaceElevated,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              fontSize: 30,
              fontWeight: AppFonts.bold,
              color: AppColors.onDark,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class SiteHeroPill extends StatefulWidget {
  const SiteHeroPill({
    super.key,
    required this.text,
    this.width,
    this.textAlign = TextAlign.right,
  });

  final String text;
  final double? width;
  final TextAlign textAlign;

  @override
  State<SiteHeroPill> createState() => _SiteHeroPillState();
}

class _SiteHeroPillState extends State<SiteHeroPill> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _hovered ? 0.95 : 1,
      duration: const Duration(milliseconds: 300),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderTailwindXl,
          boxShadow: _hovered ? AppShadows.buttonHover : AppShadows.buttonRest,
        ),
        child: GradientBorder(
          borderRadius: AppRadius.borderTailwindXl,
          backgroundColor: AppColors.surfaceElevated,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            widget.text,
            textAlign: widget.textAlign,
            style: AppTypography.custom(
              fontSize: 24,
              fontWeight: AppFonts.medium,
              color: AppColors.onDark,
              height: 1.3,
            ),
          ),
        ),
      ),
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: widget.width != null
            ? SizedBox(width: widget.width, child: child)
            : child,
      ),
    );
  }
}

class SiteStoryIllustration extends StatelessWidget {
  const SiteStoryIllustration({
    super.key,
    required this.isMedium,
    this.mediumWidth = 500,
  });

  final bool isMedium;

  final double mediumWidth;

  @override
  Widget build(BuildContext context) {
    final width = isMedium ? mediumWidth : 350.0;
    const height = 295.0;

    return ClipRRect(
      borderRadius: AppRadius.borderTailwindXl,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          ContactContent.storyBookAsset,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: AppColors.mainBg3,
            child: Icon(
              Icons.image_outlined,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
