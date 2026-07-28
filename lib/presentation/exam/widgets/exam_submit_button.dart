import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class ExamSubmitButton extends StatefulWidget {
  const ExamSubmitButton({
    super.key,
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback? onPressed;

  @override
  State<ExamSubmitButton> createState() => _ExamSubmitButtonState();
}

class _ExamSubmitButtonState extends State<ExamSubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  static const _maxWidth = 320.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _syncShimmer();
  }

  @override
  void didUpdateWidget(covariant ExamSubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncShimmer();
    }
  }

  void _syncShimmer() {
    if (widget.active) {
      _shimmerController.repeat();
    } else {
      _shimmerController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.active ? widget.onPressed : null,
                  borderRadius: AppRadius.borderAuthButton,
                  hoverColor: widget.active
                      ? AppColors.blueHover.withValues(alpha: 0.2)
                      : null,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.active
                          ? AppColors.accentBg
                          : AppColors.cardBlueBg,
                      borderRadius: AppRadius.borderAuthButton,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.borderAuthButton,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.hardEdge,
                        children: [
                          if (widget.active)
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  return AnimatedBuilder(
                                    animation: _shimmerController,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          -width +
                                              (width * 2) *
                                                  _shimmerController.value,
                                          0,
                                        ),
                                        child: child,
                                      );
                                    },
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          Text(
                            'تقديم',

                            style: AppTypography.bodyLg.copyWith(
                              color: widget.active
                                  ? AppColors.onDark
                                  : AppColors.onDark.withValues(alpha: 0.3),
                              fontWeight: AppFonts.bold,
                              fontSize: 18,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
