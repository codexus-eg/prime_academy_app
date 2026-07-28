import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'ranking_inline_icons.dart';

class RankingSearchField extends StatefulWidget {
  const RankingSearchField({
    super.key,
    required this.controller,
    this.hintText = 'ابحث عن طالب...',
  });

  final TextEditingController controller;
  final String hintText;

  static const _iconInset = 44.0;

  @override
  State<RankingSearchField> createState() => _RankingSearchFieldState();
}

class _RankingSearchFieldState extends State<RankingSearchField> {
  final _focusNode = FocusNode();
  var _focused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = widget.controller.text.isNotEmpty;
    final borderColor = _focused
        ? AppColors.rankBlueBorder30
        : AppColors.overlayWhite6;

    return SizedBox(
      height: AppSpacing.profileFilterHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mainBg3,
          borderRadius: AppRadius.borderTailwindXl,
          border: Border.all(color: borderColor),
          boxShadow: AppShadows.lg,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onDark,
            fontWeight: AppFonts.regular,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTypography.bodyMd.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: RankingSearchField._iconInset,
              vertical: AppSpacing.md,
            ),
            prefixIcon: hasQuery
                ? IconButton(
                    icon: RankingClearSearchIcon(
                      size: AppSpacing.base,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    onPressed: () => widget.controller.clear(),
                  )
                : null,
            suffixIcon: const Padding(
              padding: EdgeInsetsDirectional.all(AppSpacing.mdPlus),
              child: RankingSearchIcon(),
            ),
          ),
        ),
      ),
    );
  }
}
