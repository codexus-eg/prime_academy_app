import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/painting/css_lesson_action_gradient_painter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum LessonActionStyle {
  dark,
  blueRadial,
  purpleRadial,
}

class LessonActionButton extends StatefulWidget {
  const LessonActionButton({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.trailingBadge,
    this.labelAsBadge = false,
    this.showCompletionRibbon = false,
    this.style = LessonActionStyle.dark,
    this.onTap,
  }) : assert(icon != null || leading != null);

  final String label;
  final IconData? icon;
  final Widget? leading;
  final String? trailingBadge;

  final bool labelAsBadge;

  final bool showCompletionRibbon;
  final LessonActionStyle style;
  final VoidCallback? onTap;

  @override
  State<LessonActionButton> createState() => _LessonActionButtonState();
}

class _LessonActionButtonState extends State<LessonActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  Color get _ringColor => switch (widget.style) {
        LessonActionStyle.purpleRadial => AppColors.contentBtnFlashcardsHover,
        _ => AppColors.contentBtnRingHover,
      };

  Color? get _gradientAccent => switch (widget.style) {
        LessonActionStyle.blueRadial => AppColors.blue,
        LessonActionStyle.purpleRadial => AppColors.purple,
        LessonActionStyle.dark => null,
      };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = width >= 768 ? 40.0 : AppSpacing.lessonActionHeight;
    final radius = BorderRadius.circular(AppRadius.shadcnMd);
    final showRing = _enabled && (_hovered || _pressed);
    final accent = _gradientAccent;
    const ringWidth = 2.0;

    final content = Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null)
          widget.leading!
        else
          Icon(widget.icon, size: 16, color: AppColors.onDark),
        if (widget.label.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: widget.labelAsBadge
                ? _CompletionBadge(text: widget.label)
                : Text(
                    widget.label,
                    textDirection: TextDirection.rtl,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onDark,
                    ),
                  ),
          ),
        ],
        if (widget.trailingBadge != null &&
            widget.trailingBadge!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          _CompletionBadge(text: widget.trailingBadge!),
        ],
      ],
    );

    final button = AnimatedOpacity(
      duration: AppDurations.hoverScale,
      opacity: _enabled && _pressed ? 0.8 : 1,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (accent != null)
                      CssLessonActionGradientLayer(
                        accent: accent,
                        background: AppColors.contentBtnBg,
                      )
                    else
                      const ColoredBox(color: AppColors.contentBtnBg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: content,
                    ),
                    if (widget.showCompletionRibbon)
                      const _CompletionRibbonOverlay(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -ringWidth,
              top: -ringWidth,
              right: -ringWidth,
              bottom: -ringWidth,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: AppDurations.hoverScale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppRadius.shadcnMd + ringWidth,
                    ),
                    border: Border.all(
                      color: showRing ? _ringColor : Colors.transparent,
                      width: ringWidth,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!_enabled) {
      return MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: button,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: button,
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.contentCompletionBadge,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: AppTypography.bodySm.copyWith(
            fontWeight: AppFonts.semibold,
            color: AppColors.onDark,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _CompletionRibbonOverlay extends StatelessWidget {
  const _CompletionRibbonOverlay();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: _CompletionRibbon(),
      ),
    );
  }
}

class _CompletionRibbon extends StatelessWidget {
  const _CompletionRibbon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -20,
          top: 8,
          child: Transform.rotate(
            angle: -55 * math.pi / 180,
            child: Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.contentCompletionRibbon,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
