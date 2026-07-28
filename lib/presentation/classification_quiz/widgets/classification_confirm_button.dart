import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_typography.dart';

class ClassificationConfirmButton extends StatefulWidget {
  const ClassificationConfirmButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<ClassificationConfirmButton> createState() =>
      _ClassificationConfirmButtonState();
}

class _ClassificationConfirmButtonState extends State<ClassificationConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.enabled) _shimmer.repeat();
  }

  @override
  void didUpdateWidget(covariant ClassificationConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_shimmer.isAnimating) {
      _shimmer.repeat();
    } else if (!widget.enabled && _shimmer.isAnimating) {
      _shimmer.stop();
      _shimmer.value = 0;
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled ? widget.onPressed : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFF3B82F6)],
                  )
                : null,
            color: widget.enabled
                ? null
                : Colors.white.withValues(alpha: 0.1),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                if (widget.enabled)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shimmer,
                      builder: (context, _) {
                        return Transform.translate(
                          offset: Offset(
                            (_shimmer.value * 2 - 1) * 220,
                            0,
                          ),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.skewX(-0.4),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0x33FFFFFF),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  child: Text(
                    'تأكيد الإجابة',
                    style: AppTypography.bodyLg.copyWith(
                      color: widget.enabled
                          ? AppColors.onDark
                          : Colors.white.withValues(alpha: 0.3),
                      fontWeight: AppFonts.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
