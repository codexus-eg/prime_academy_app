import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/about_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/legal_policy_links.dart';
import '../common/site_page.dart';

abstract final class AboutPage {
  static const String routePath = '/about';
  static const String routeName = 'about';
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 1024;
    final isMedium = screenWidth >= 768;

    return SitePageScaffold(
      maxContentWidth: 1200,
      children: [
        const SiteHeroTitle(text: 'من نحن'),
        const SizedBox(height: 96),

        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 500, child: _AboutTextColumn()),
              const SizedBox(width: 96),
              Expanded(
                child: _AboutMediaColumn(isMedium: isMedium),
              ),
            ],
          )
        else ...[
          const _AboutTextColumn(),
          const SizedBox(height: 48),
          _AboutMediaColumn(isMedium: screenWidth >= 640),
        ],
        const SizedBox(height: 48),
        const LegalPolicyLinks(),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AboutTextColumn extends StatelessWidget {
  const _AboutTextColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'برايم أكاديـمي',
          style: AppTypography.custom(
            fontSize: 20,
            fontWeight: AppFonts.bold,
            color: AppColors.secondaryOpaque,
          ),
        ),
        const SizedBox(height: 24),

        const SiteHeroPill(text: 'نبذة عنا', width: 150),
        const SizedBox(height: 24),
        for (final info in AboutContent.mainInfo) ...[
          Text(info, style: AppTypography.bodyLg.copyWith(height: 1.9)),
          const SizedBox(height: 24),
        ],

        const SiteHeroPill(
          text: 'انظمة برايم اكاديمي المبتكرة',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < AboutContent.secondaryInfo.length; i++) ...[
          _SectionItem(index: i, section: AboutContent.secondaryInfo[i]),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _AboutMediaColumn extends StatelessWidget {
  const _AboutMediaColumn({required this.isMedium});

  final bool isMedium;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: SiteStoryIllustration(
            isMedium: isMedium,
            mediumWidth: 523,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 0.85,
              children: [
                for (final counter in AboutContent.counters)
                  AboutCounterRing(counter: counter),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionItem extends StatelessWidget {
  const _SectionItem({required this.index, required this.section});

  final int index;
  final AboutSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, color: AppColors.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '(${index + 1}) ${section.title}',
                style: AppTypography.custom(
                  fontSize: 18,
                  fontWeight: AppFonts.semibold,
                  color: AppColors.onDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          section.text,
          style: AppTypography.custom(
            fontSize: 15,
            color: const Color(0xFFD1D5DB),
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

class AboutCounterRing extends StatefulWidget {
  const AboutCounterRing({super.key, required this.counter});

  final AboutCounter counter;

  @override
  State<AboutCounterRing> createState() => _AboutCounterRingState();
}

class _AboutCounterRingState extends State<AboutCounterRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = widget.counter.maxValue * _controller.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [

                  Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                  ),

                  CustomPaint(
                    size: const Size(140, 140),
                    painter: _CounterRingPainter(progress: progress),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.counter.icon,
                        color: AppColors.onDark,
                        size: 30,
                      ),
                      Text(
                        '${progress.floor()}%',
                        style: AppTypography.custom(
                          fontSize: 24,
                          fontWeight: AppFonts.medium,
                          color: AppColors.onDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.counter.title,
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                fontSize: 18,
                color: AppColors.onDark,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CounterRingPainter extends CustomPainter {
  const _CounterRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final strokeWidth = size.width * 0.17;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color.fromRGBO(128, 128, 128, 0.397)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.secondary, AppColors.accent],
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * (progress / 100),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CounterRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
