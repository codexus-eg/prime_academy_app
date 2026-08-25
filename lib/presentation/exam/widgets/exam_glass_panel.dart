import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import 'exam_starry_background.dart';

/// Web `QuizReadyState` panel:
/// `bg-[#0a1128]/80 backdrop-blur-xl border-2 border-[#007bff]/30 rounded-2xl
///  shadow-[0_0_80px_rgba(0,123,255,0.15),inset_0_0_30px_rgba(0,123,255,0.05)]`
///
/// Flutter web's [BackdropFilter] does not sample the quiz glyphs, so the
/// frost is painted from the same moving backdrop, clipped to this card.
class ExamGlassPanel extends StatelessWidget {
  const ExamGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(40, 56, 40, 40),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  static final _radius = BorderRadius.circular(AppRadius.tailwind2xl);

  @override
  Widget build(BuildContext context) {
    final host = ExamBackdropHost.maybeOf(context);
    final screen = MediaQuery.sizeOf(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: _radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26007BFF),
            blurRadius: 80,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: Stack(
          children: [
            if (host != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRect(
                    child: CompositedTransformFollower(
                      link: host.layerLink,
                      showWhenUnlinked: false,
                      targetAnchor: Alignment.topLeft,
                      followerAnchor: Alignment.topLeft,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 24,
                          sigmaY: 24,
                          tileMode: TileMode.decal,
                        ),
                        child: SizedBox(
                          width: screen.width,
                          height: screen.height,
                          child: CustomPaint(
                            size: screen,
                            painter: host.createPainter(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color.fromRGBO(10, 17, 40, 0.8),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.08,
                      colors: [
                        Colors.transparent,
                        Color.fromRGBO(0, 123, 255, 0.05),
                      ],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _radius,
                    border: Border.all(
                      color: const Color.fromRGBO(0, 123, 255, 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
