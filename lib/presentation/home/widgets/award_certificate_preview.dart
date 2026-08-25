import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/students/student_awards.dart';
import 'certificate_image_delivery.dart';

TextStyle _certificateLatinStyle({
  required double fontSize,
  FontWeight fontWeight = AppFonts.semibold,
  Color? color,
  double? letterSpacing,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'sans-serif',
    fontFamilyFallback: const ['Arial', 'Helvetica', 'Roboto', 'sans-serif'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? AppColors.primary,
    letterSpacing: letterSpacing,
    height: height ?? 1.0,
  );
}

Widget _certificateLatinText(
  String text, {
  required TextStyle style,
  TextAlign textAlign = TextAlign.center,
  int? maxLines,
  TextOverflow? overflow,
  bool softWrap = true,
}) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        style: style,
      ),
    ),
  );
}

/// Keeps a Latin title on one line (web does not mid-word wrap `CERTIFICATE`).
///
/// `BoxFit.scaleDown` otherwise passes the parent max-width to [Text], which
/// wraps first and then "fits" the already-wrapped block (no scale).
Widget _certificateFitLatin(
  String text, {
  required TextStyle style,
  TextAlign textAlign = TextAlign.center,
}) {
  return SizedBox(
    width: double.infinity,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: UnconstrainedBox(
        child: _certificateLatinText(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    ),
  );
}

/// Arabic quote: scale down instead of breaking words across lines.
Widget _certificateFitQuote(String text, {required double fontSize}) {
  return SizedBox(
    width: double.infinity,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: UnconstrainedBox(
        child: Text(
          text,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: _certificateQuotePreviewStyle(fontSize),
        ),
      ),
    ),
  );
}

/// Web full-certificate typography (`md:` breakpoint at 768px).
class _CertificateFullMetrics {
  const _CertificateFullMetrics(double width)
      : isMobile = width < 768,
        outerPadding = 16,
        innerPadding = width < 768 ? 24 : 32,
        titleSize = width < 768 ? 36 : 48,
        titleTracking = width < 768 ? 10 : 10,
        brandSize = width < 768 ? 30 : 36,
        quoteSize = width < 768 ? 24 : 30,
        nameSize = width < 768 ? 36 : 48,
        sectionGap = width < 768 ? 24 : 32,
        classicTitleSize = width < 768 ? 30 : 36,
        classicBrandSize = width < 768 ? 24 : 30,
        classicQuoteSize = width < 768 ? 20 : 24,
        sideAccentTitleSize = width < 768 ? 36 : 48,
        sideAccentBrandSize = width < 768 ? 24 : 30,
        sideAccentQuoteSize = width < 768 ? 24 : 30,
        sideAccentNameSize = width < 768 ? 30 : 36,
        hexTitleSize = width < 768 ? 36 : 48,
        hexBrandSize = width < 768 ? 24 : 30,
        hexQuoteSize = width < 768 ? 24 : 30,
        hexNameSize = width < 768 ? 30 : 36,
        hexBracketSize = width < 768 ? 32 : 32;

  final bool isMobile;
  final double outerPadding;
  final double innerPadding;
  final double titleSize;
  final double titleTracking;
  final double brandSize;
  final double quoteSize;
  final double nameSize;
  final double sectionGap;
  final double classicTitleSize;
  final double classicBrandSize;
  final double classicQuoteSize;
  final double sideAccentTitleSize;
  final double sideAccentBrandSize;
  final double sideAccentQuoteSize;
  final double sideAccentNameSize;
  final double hexTitleSize;
  final double hexBrandSize;
  final double hexQuoteSize;
  final double hexNameSize;
  final double hexBracketSize;

  static const double outerPaddingStatic = 16;
}

Widget _certificateFullQuoteText(String text, {required double fontSize}) {
  return _certificateFitQuote(text, fontSize: fontSize);
}

Widget _certificateFullShell({
  required Widget child,
  BoxConstraints? constraints,
}) {
  return LayoutBuilder(
    builder: (context, layoutConstraints) {
      return Padding(
        padding: const EdgeInsets.all(_CertificateFullMetrics.outerPaddingStatic),
        child: Center(
          child: ConstrainedBox(
            constraints: constraints ?? const BoxConstraints(maxWidth: 768),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Font Awesome 5.15.4 solid `certificate` — same glyph as web `FaCertificate`.
class _CertificateBadgeIcon extends StatelessWidget {
  const _CertificateBadgeIcon({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  /// Copied from `@fortawesome/fontawesome-free@5.15.4/svgs/solid/certificate.svg`
  /// (react-icons/fa `FaCertificate` used in CertificateClassicFrame.tsx).
  static const _faCertificateSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path fill="currentColor" d="M458.622 255.92l45.985-45.005c13.708-12.977 7.316-36.039-10.664-40.339l-62.65-15.99 17.661-62.015c4.991-17.838-11.829-34.663-29.661-29.671l-61.994 17.667-15.984-62.671C337.085.197 313.765-6.276 300.99 7.228L256 53.57 211.011 7.229c-12.63-13.351-36.047-7.234-40.325 10.668l-15.984 62.671-61.995-17.667C74.87 57.907 58.056 74.738 63.046 92.572l17.661 62.015-62.65 15.99C.069 174.878-6.31 197.944 7.392 210.915l45.985 45.005-45.985 45.004c-13.708 12.977-7.316 36.039 10.664 40.339l62.65 15.99-17.661 62.015c-4.991 17.838 11.829 34.663 29.661 29.671l61.994-17.667 15.984 62.671c4.439 18.575 27.696 24.018 40.325 10.668L256 458.61l44.989 46.001c12.5 13.488 35.987 7.486 40.325-10.668l15.984-62.671 61.994 17.667c17.836 4.994 34.651-11.837 29.661-29.671l-17.661-62.015 62.65-15.99c17.987-4.302 24.366-27.367 10.664-40.339l-45.984-45.004z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _faCertificateSvg,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Web ClassicFrame full badge: always `w-16 h-16` + `FaCertificate` 28px white.
class _CertificateClassicBadge extends StatelessWidget {
  const _CertificateClassicBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.certificateAccent,
            AppColors.purpleLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.certificateGlow.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const _CertificateBadgeIcon(
        size: 28,
        color: Colors.white,
      ),
    );
  }
}

abstract final class AwardCertificatePreview {
  static Widget build({
    required int templateIndex,
    required String studentName,
    required String teacherName,
    bool preview = true,
  }) {
    final safeIndex = templateIndex.clamp(0, 3);
    switch (safeIndex) {
      case 0:
        return _CertificatePremium(
          studentName: studentName,
          teacherName: teacherName,
          preview: preview,
        );
      case 1:
        return _CertificateClassicFrame(
          studentName: studentName,
          teacherName: teacherName,
          preview: preview,
        );
      case 2:
        return _CertificateSideAccent(
          studentName: studentName,
          teacherName: teacherName,
          preview: preview,
        );
      default:
        return _CertificateHexagon(
          studentName: studentName,
          teacherName: teacherName,
          preview: preview,
        );
    }
  }

  static void showCertificatesDialog(
    BuildContext context, {
    required int templateIndex,
    required List<StudentAwardCertificate> certificates,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _CertificatesDialog(
        templateIndex: templateIndex,
        certificates: certificates,
      ),
    );
  }
}

class _CertificatesDialog extends StatelessWidget {
  const _CertificatesDialog({
    required this.templateIndex,
    required this.certificates,
  });

  final int templateIndex;
  final List<StudentAwardCertificate> certificates;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width * 0.9;
    final maxHeight = size.height * 0.8;

    return Dialog(
      backgroundColor: AppColors.secondaryBg,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dialogWidth,
          maxWidth: dialogWidth.clamp(280, 768),
          maxHeight: maxHeight,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < certificates.length; i++) ...[
                      if (i > 0) const SizedBox(height: 24),
                      _CertificateDownloadTile(
                        templateIndex: templateIndex,
                        certificate: certificates[i],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  const _DownloadButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final background = enabled && _hovered
        ? AppColors.accentSoft.withValues(alpha: 0.8)
        : AppColors.accentSoft;

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                const Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: AppFonts.semibold,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateDownloadTile extends StatefulWidget {
  const _CertificateDownloadTile({
    required this.templateIndex,
    required this.certificate,
  });

  final int templateIndex;
  final StudentAwardCertificate certificate;

  @override
  State<_CertificateDownloadTile> createState() =>
      _CertificateDownloadTileState();
}

class _CertificateDownloadTileState extends State<_CertificateDownloadTile> {
  final _captureKey = GlobalKey();
  var _sharing = false;

  Future<void> _shareCertificate() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      if (!mounted) return;
      await deliverCertificateImage(
        pngBytes: byteData.buffer.asUint8List(),
        fileName: 'certificate-${widget.certificate.id}.png',
        shareText: 'شهادة ${widget.certificate.studentName}',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: SizedBox(
            width: double.infinity,
            child: AwardCertificatePreview.build(
              templateIndex: widget.templateIndex,
              studentName: widget.certificate.studentName,
              teacherName: widget.certificate.teacherName,
              preview: false,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: _DownloadButton(
            label: 'تحميل الشهادة',
            loading: _sharing,
            onPressed: _shareCertificate,
          ),
        ),
      ],
    );
  }
}

class _CertificatePremium extends StatelessWidget {
  const _CertificatePremium({
    required this.studentName,
    required this.teacherName,
    required this.preview,
  });

  final String studentName;
  final String teacherName;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (preview) return _premiumPreview();
    return _premiumFull();
  }

  Widget _premiumPreview() {
    // Web CertificatePremium preview (p-1.5, gap-1.5, corner glows).
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(6),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.certificateBorder),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _cornerRadialGlow(
              AppColors.certificateAccent,
              Alignment.topLeft,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _cornerRadialGlow(
              AppColors.purpleLight,
              Alignment.bottomRight,
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  const Positioned.fill(child: _CertificateDualRadialOverlay()),
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _certificateLatinText(
                              'CERTIFICATE',
                              style: _certificateLatinStyle(
                                fontSize: 12,
                                fontWeight: AppFonts.semibold,
                                color: AppColors.certificateAccent,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _certificateLatinText(
                              'PRIMEACADEMY',
                              style: _certificateLatinStyle(
                                fontSize: 11,
                                fontWeight: AppFonts.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.55,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _webPremiumQuotePreview(
                              'والله انك كفو يا اسطوره',
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                studentName,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.custom(
                                  fontSize: 15,
                                  fontWeight: AppFonts.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 0.5,
                              width: 48,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.certificateAccent,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _teacherBlock(
                              preview: true,
                              teacherName: teacherName,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumFull() {
    return _certificateFullShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _CertificateFullMetrics(constraints.maxWidth);

          return Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.certificateBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _CertificateDualRadialOverlay()),
                Padding(
                  padding: EdgeInsets.all(metrics.innerPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _certificateFitLatin(
                        'CERTIFICATE',
                        style: _certificateLatinStyle(
                          fontSize: metrics.titleSize,
                          fontWeight: AppFonts.light,
                          color: AppColors.certificateAccent,
                          letterSpacing: metrics.titleTracking,
                          height: 1.1,
                        ).copyWith(
                          shadows: const [
                            Shadow(
                              color: AppColors.certificateGlow,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 4 : 8),
                      _certificateFitLatin(
                        'PRIMEACADEMY',
                        style: _certificateLatinStyle(
                          fontSize: metrics.brandSize,
                          fontWeight: AppFonts.bold,
                          color: AppColors.primary,
                          letterSpacing: metrics.isMobile ? 1 : 2,
                        ),
                      ),
                      SizedBox(height: metrics.sectionGap),
                      _certificatePremiumQuoteBox(
                        'والله انك كفو يا اسطوره',
                        fontSize: metrics.quoteSize,
                      ),
                      SizedBox(height: metrics.sectionGap),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            studentName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.custom(
                              fontSize: metrics.nameSize,
                              fontWeight: AppFonts.semibold,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 12 : 16),
                      Container(
                        height: metrics.isMobile ? 2 : 2,
                        width: metrics.isMobile ? 96 : 96,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.certificateAccent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.sectionGap),
                      _teacherBlock(
                        preview: false,
                        compact: metrics.isMobile,
                        teacherName: teacherName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CertificateClassicFrame extends StatelessWidget {
  const _CertificateClassicFrame({
    required this.studentName,
    required this.teacherName,
    required this.preview,
  });

  final String studentName;
  final String teacherName;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return preview ? _preview() : _full();
  }

  Widget _preview() {
    // Web CertificateClassicFrame preview.
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(6),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: AppRadius.borderMd,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.certificateBorder,
                  width: 2,
                ),
                borderRadius: AppRadius.borderMd,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: CustomPaint(
                painter: _CertificateDashedBorderPainter(
                  color: AppColors.certificateBorder.withValues(alpha: 0.5),
                  radius: AppRadius.md - 3,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.certificateAccent,
                      AppColors.purpleLight,
                    ],
                  ),
                  borderRadius: AppRadius.borderMd,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CertificateBadgeIcon(
                      size: 14,
                      color: AppColors.certificateAccent,
                    ),
                    const SizedBox(height: 4),
                    _certificateLatinText(
                      'CERTIFICATE',
                      style: _certificateLatinStyle(
                        fontSize: 11,
                        fontWeight: AppFonts.semibold,
                        color: AppColors.certificateAccent,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _certificateLatinText(
                      'PRIMEACADEMY',
                      style: _certificateLatinStyle(
                        fontSize: 10,
                        fontWeight: AppFonts.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _certificateLatinText(
                        'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                        style: _certificateLatinStyle(
                          fontSize: 8,
                          fontWeight: AppFonts.regular,
                          color: AppColors.textMuted,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.certificateAccent,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        studentName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          fontSize: 14,
                          fontWeight: AppFonts.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.certificateBgSubtle,
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: _CertificateQuoteText(
                        text: 'بنتوقعلك مستقبل كبير جدا ان شاء الله',
                        fontSize: 12,
                      ),
                    ),
                    _teacherBlock(preview: true, teacherName: teacherName),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _full() {
    return _certificateFullShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _CertificateFullMetrics(constraints.maxWidth);

          return Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.certificateBorder, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CustomPaint(
                      painter: _CertificateDashedBorderPainter(
                        color: AppColors.certificateBorder.withValues(alpha: 0.5),
                        radius: AppRadius.md - 4,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.certificateAccent,
                            AppColors.purpleLight,
                          ],
                        ),
                        borderRadius: AppRadius.borderMd,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.certificateAccent,
                            Colors.transparent,
                            Colors.transparent,
                            AppColors.purpleLight,
                          ],
                          stops: const [0, 0.4, 0.6, 1],
                        ),
                        borderRadius: AppRadius.borderMd,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.1,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 0.7,
                          colors: [
                            AppColors.certificateAccent,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Opacity(
                    opacity: 0.1,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.bottomLeft,
                          radius: 0.7,
                          colors: [
                            AppColors.purpleLight,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(metrics.innerPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CertificateClassicBadge(),
                      SizedBox(height: metrics.isMobile ? 16 : 24),
                      _certificateFitLatin(
                        'CERTIFICATE',
                        style: _certificateLatinStyle(
                          fontSize: metrics.classicTitleSize,
                          fontWeight: AppFonts.semibold,
                          color: AppColors.certificateAccent,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _certificateFitLatin(
                        'of Achievement',
                        style: _certificateLatinStyle(
                          fontSize: 14,
                          fontWeight: AppFonts.regular,
                          color: AppColors.textMuted,
                          letterSpacing: 4,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 16 : 24),
                      _certificateFitLatin(
                        'PRIMEACADEMY',
                        style: _certificateLatinStyle(
                          fontSize: metrics.classicBrandSize,
                          fontWeight: AppFonts.bold,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _certificateFitLatin(
                        'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                        style: _certificateLatinStyle(
                          fontSize: 14,
                          fontWeight: AppFonts.regular,
                          color: AppColors.textMuted,
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 8 : 16),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.certificateAccent,
                              width: 2,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          studentName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.custom(
                            fontSize: metrics.classicTitleSize,
                            fontWeight: AppFonts.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 16 : 24),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: metrics.isMobile ? 12 : 16,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.certificateBgSubtle,
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: _certificateFullQuoteText(
                          'بنتوقعلك مستقبل كبير جدا ان شاء الله',
                          fontSize: metrics.classicQuoteSize,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 24 : 32),
                      _teacherBlock(
                        preview: false,
                        compact: metrics.isMobile,
                        teacherName: teacherName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CertificateSideAccent extends StatelessWidget {
  const _CertificateSideAccent({
    required this.studentName,
    required this.teacherName,
    required this.preview,
  });

  final String studentName;
  final String teacherName;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return preview ? _preview() : _full();
  }

  Widget _preview() {
    // Web CertificateSideAccent preview.
    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: AppRadius.borderMd,
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 8,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.certificateAccent,
                    AppColors.purpleLight,
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _CertificateStripePatternOverlay()),
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _certificateLatinText(
                      'CERTIFICATE',
                      style: _certificateLatinStyle(
                        fontSize: 12,
                        fontWeight: AppFonts.semibold,
                        color: AppColors.certificateAccent,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _certificateLatinText(
                      'PRIMEACADEMY',
                      style: _certificateLatinStyle(
                        fontSize: 11,
                        fontWeight: AppFonts.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.55,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 1,
                      width: 32,
                      color: AppColors.certificateAccent,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.certificateBgSubtle,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _CertificateQuoteText(
                        text: 'أنت من الأبطال الذين يصنعون الفرق',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        studentName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          fontSize: 15,
                          fontWeight: AppFonts.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _teacherBlock(preview: true, teacherName: teacherName),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _full() {
    return _certificateFullShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _CertificateFullMetrics(constraints.maxWidth);

          return Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: AppRadius.borderLg,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.certificateAccent,
                          AppColors.purpleLight,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: CustomPaint(
                      painter: _CertificateSideAccentStripePainter(),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.7, -0.3),
                          radius: 0.8,
                          colors: [
                            AppColors.purpleLight,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    metrics.isMobile ? 40 : 48,
                    metrics.isMobile ? 32 : 40,
                    metrics.isMobile ? 32 : 40,
                    metrics.isMobile ? 32 : 40,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _certificateFitLatin(
                        'CERTIFICATE',
                        style: _certificateLatinStyle(
                          fontSize: metrics.sideAccentTitleSize,
                          fontWeight: AppFonts.semibold,
                          color: AppColors.certificateAccent,
                          letterSpacing: 6,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 8 : 16),
                      _certificateFitLatin(
                        'PRIMEACADEMY',
                        style: _certificateLatinStyle(
                          fontSize: metrics.sideAccentBrandSize,
                          fontWeight: AppFonts.semibold,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: 64,
                        color: AppColors.certificateAccent,
                      ),
                      SizedBox(height: metrics.isMobile ? 24 : 32),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: metrics.isMobile ? 16 : 24,
                          vertical: metrics.isMobile ? 12 : 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.certificateBgSubtle,
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _certificateFullQuoteText(
                          'أنت من الأبطال الذين يصنعون الفرق',
                          fontSize: metrics.sideAccentQuoteSize,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 24 : 32),
                      Text(
                        studentName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          fontSize: metrics.sideAccentNameSize,
                          fontWeight: AppFonts.semibold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 24 : 32),
                      _teacherBlock(
                        preview: false,
                        compact: metrics.isMobile,
                        teacherName: teacherName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CertificateHexagon extends StatelessWidget {
  const _CertificateHexagon({
    required this.studentName,
    required this.teacherName,
    required this.preview,
  });

  final String studentName;
  final String teacherName;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return preview ? _preview() : _full();
  }

  Widget _preview() {
    // Web CertificateHexagon preview.
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.certificateBorder),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -3,
            left: -3,
            child: _hexDecoration(
              size: 16,
              opacity: 0.4,
              colors: const [
                AppColors.certificateAccent,
                AppColors.purpleLight,
              ],
            ),
          ),
          Positioned(
            bottom: -3,
            right: -3,
            child: _hexDecoration(
              size: 20,
              opacity: 0.35,
              colors: const [
                AppColors.purpleLight,
                AppColors.certificateAccent,
              ],
            ),
          ),
          const Positioned.fill(child: _CertificateCenterRadialOverlay()),
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _certificateLatinText(
                      'CERTIFICATE',
                      style: _certificateLatinStyle(
                        fontSize: 12,
                        fontWeight: AppFonts.semibold,
                        color: AppColors.certificateAccent,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _certificateLatinText(
                      'PRIMEACADEMY',
                      style: _certificateLatinStyle(
                        fontSize: 11,
                        fontWeight: AppFonts.bold,
                        color: AppColors.primary,
                        letterSpacing: 0.55,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.certificateBgSubtle,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(60)),
                      ),
                      child: _CertificateQuoteText(
                        text: 'نُشيد باجتهادك ونتمنى لك دوام التفوق والنجاح',
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⟨',
                          style: _certificateLatinStyle(
                            fontSize: 11,
                            color: AppColors.certificateAccent
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            studentName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.custom(
                              fontSize: 14,
                              fontWeight: AppFonts.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '⟩',
                          style: _certificateLatinStyle(
                            fontSize: 11,
                            color: AppColors.certificateAccent
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _teacherBlock(preview: true, teacherName: teacherName),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _full() {
    return _certificateFullShell(
      constraints: const BoxConstraints(maxWidth: 768),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _CertificateFullMetrics(constraints.maxWidth);

          return Container(
            width: double.infinity,
            clipBehavior: Clip.none,
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.certificateBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -16,
                  left: -16,
                  child: _hexDecoration(
                    size: 48,
                    opacity: 0.2,
                    colors: const [
                      AppColors.certificateAccent,
                      AppColors.purpleLight,
                    ],
                  ),
                ),
                Positioned(
                  bottom: -16,
                  right: -16,
                  child: _hexDecoration(
                    size: 64,
                    opacity: 0.15,
                    colors: const [
                      AppColors.purpleLight,
                      AppColors.certificateAccent,
                    ],
                  ),
                ),
                const Positioned.fill(child: _CertificateCenterRadialOverlay()),
                Padding(
                  padding: EdgeInsets.all(metrics.isMobile ? 32 : 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _certificateFitLatin(
                        'CERTIFICATE',
                        style: _certificateLatinStyle(
                          fontSize: metrics.hexTitleSize,
                          fontWeight: AppFonts.semibold,
                          color: AppColors.certificateAccent,
                          letterSpacing: 6,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 8 : 16),
                      _certificateFitLatin(
                        'PRIMEACADEMY',
                        style: _certificateLatinStyle(
                          fontSize: metrics.hexBrandSize,
                          fontWeight: AppFonts.semibold,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 24 : 32),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: metrics.isMobile ? 24 : 32,
                          vertical: metrics.isMobile ? 16 : 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.certificateBgSubtle,
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: _certificateFullQuoteText(
                          'نُشيد باجتهادك ونتمنى لك دوام التفوق والنجاح',
                          fontSize: metrics.hexQuoteSize,
                        ),
                      ),
                      SizedBox(height: metrics.isMobile ? 24 : 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '⟨',
                            style: _certificateLatinStyle(
                              fontSize: metrics.hexBracketSize,
                              color: AppColors.certificateAccent.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Text(
                              studentName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.custom(
                                fontSize: metrics.hexNameSize,
                                fontWeight: AppFonts.semibold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '⟩',
                            style: _certificateLatinStyle(
                              fontSize: metrics.hexBracketSize,
                              color: AppColors.certificateAccent.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: metrics.isMobile ? 32 : 40),
                      _teacherBlock(
                        preview: false,
                        compact: metrics.isMobile,
                        teacherName: teacherName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _hexDecoration({
  required double size,
  required double opacity,
  required List<Color> colors,
}) {
  return Opacity(
    opacity: opacity,
    child: ClipPath(
      clipper: _HexagonClipper(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
      ),
    ),
  );
}

TextStyle _certificateQuotePreviewStyle([double fontSize = 12]) =>
    TextStyle(
      fontFamily: AppFonts.bahij,
      fontFamilyFallback: const ['Arial', 'Tahoma', 'sans-serif'],
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.yellow,
      height: 1.625,
    );

/// Web premium quote box: my-1 py-3 px-4 rounded-xl + left/right borders.
Widget _webPremiumQuotePreview(String text) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.certificateBgSubtle,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ColoredBox(
              color: AppColors.certificateAccent,
              child: SizedBox(width: 3),
            ),
          ),
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ColoredBox(
              color: AppColors.purpleLight,
              child: SizedBox(width: 3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _CertificateQuoteText(text: text, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

Widget _certificatePremiumQuoteBox(String text, {double fontSize = 12}) {
  final isPreview = fontSize <= 12;
  final compact = fontSize <= 16;

  final verticalMargin = isPreview ? 4.0 : (compact ? 12.0 : 24.0);
  final verticalPadding = isPreview ? 10.0 : (compact ? 14.0 : 20.0);
  const horizontalPadding = 16.0;

  return Container(
    width: double.infinity,
    margin: EdgeInsets.symmetric(vertical: verticalMargin),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: CustomPaint(
        painter: const _CertificatePremiumQuoteBoxPainter(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: _certificateFitQuote(text, fontSize: fontSize),
        ),
      ),
    ),
  );
}

class _CertificatePremiumQuoteBoxPainter extends CustomPainter {
  const _CertificatePremiumQuoteBoxPainter();

  static const double _borderWidth = 2;

  static const double _radius = AppRadius.shadcnLg;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(_radius),
    );
    final inner = outer.deflate(_borderWidth);

    canvas.drawRRect(
      outer,
      Paint()
        ..isAntiAlias = true
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.certificateBgSubtle,
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    canvas.drawPath(
      _cssSideBorderPath(outer: outer, inner: inner, left: true),
      Paint()
        ..isAntiAlias = true
        ..color = AppColors.certificateAccent,
    );
    canvas.drawPath(
      _cssSideBorderPath(outer: outer, inner: inner, left: false),
      Paint()
        ..isAntiAlias = true
        ..color = AppColors.purpleLight,
    );
  }

  static Path _cssSideBorderPath({
    required RRect outer,
    required RRect inner,
    required bool left,
  }) {
    final path = Path();
    if (left) {
      path
        ..moveTo(outer.left + outer.tlRadiusX, outer.top)
        ..arcToPoint(
          Offset(outer.left, outer.top + outer.tlRadiusY),
          radius: Radius.elliptical(outer.tlRadiusX, outer.tlRadiusY),
          clockwise: false,
        )
        ..lineTo(outer.left, outer.bottom - outer.blRadiusY)
        ..arcToPoint(
          Offset(outer.left + outer.blRadiusX, outer.bottom),
          radius: Radius.elliptical(outer.blRadiusX, outer.blRadiusY),
          clockwise: false,
        )
        ..lineTo(inner.left + inner.blRadiusX, inner.bottom)
        ..arcToPoint(
          Offset(inner.left, inner.bottom - inner.blRadiusY),
          radius: Radius.elliptical(inner.blRadiusX, inner.blRadiusY),
          clockwise: true,
        )
        ..lineTo(inner.left, inner.top + inner.tlRadiusY)
        ..arcToPoint(
          Offset(inner.left + inner.tlRadiusX, inner.top),
          radius: Radius.elliptical(inner.tlRadiusX, inner.tlRadiusY),
          clockwise: true,
        )
        ..close();
    } else {
      path
        ..moveTo(outer.right - outer.trRadiusX, outer.top)
        ..arcToPoint(
          Offset(outer.right, outer.top + outer.trRadiusY),
          radius: Radius.elliptical(outer.trRadiusX, outer.trRadiusY),
          clockwise: true,
        )
        ..lineTo(outer.right, outer.bottom - outer.brRadiusY)
        ..arcToPoint(
          Offset(outer.right - outer.brRadiusX, outer.bottom),
          radius: Radius.elliptical(outer.brRadiusX, outer.brRadiusY),
          clockwise: true,
        )
        ..lineTo(inner.right - inner.brRadiusX, inner.bottom)
        ..arcToPoint(
          Offset(inner.right, inner.bottom - inner.brRadiusY),
          radius: Radius.elliptical(inner.brRadiusX, inner.brRadiusY),
          clockwise: false,
        )
        ..lineTo(inner.right, inner.top + inner.trRadiusY)
        ..arcToPoint(
          Offset(inner.right - inner.trRadiusX, inner.top),
          radius: Radius.elliptical(inner.trRadiusX, inner.trRadiusY),
          clockwise: false,
        )
        ..close();
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _CertificatePremiumQuoteBoxPainter oldDelegate) =>
      false;
}

class _CertificateQuoteText extends StatelessWidget {
  const _CertificateQuoteText({
    required this.text,
    this.fontSize = 12,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: _certificateQuotePreviewStyle(fontSize),
      ),
    );
  }
}

Widget _cornerRadialGlow(Color color, Alignment alignment) {
  return Opacity(
    opacity: 0.3,
    child: SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: 0.7,
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    ),
  );
}

class _CertificateDualRadialOverlay extends StatelessWidget {
  const _CertificateDualRadialOverlay();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.15,
      child: CustomPaint(
        painter: _CertificateDualRadialPainter(),
      ),
    );
  }
}

class _CertificateDualRadialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 0.5,
          colors: const [AppColors.certificateAccent, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.4, 0.4),
          radius: 0.5,
          colors: const [AppColors.purpleLight, Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CertificateCenterRadialOverlay extends StatelessWidget {
  const _CertificateCenterRadialOverlay();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AppColors.certificateAccent,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateStripePatternOverlay extends StatelessWidget {
  const _CertificateStripePatternOverlay();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.05,
      child: CustomPaint(
        painter: _CertificateStripePatternPainter(),
      ),
    );
  }
}

class _CertificateStripePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.certificateAccent
      ..strokeWidth = 0.5;

    const spacing = 10.0;
    final diagonal = size.width + size.height;
    for (var offset = -diagonal; offset < diagonal; offset += spacing) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CertificateSideAccentStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.certificateAccent
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (var i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CertificateDashedBorderPainter extends CustomPainter {
  const _CertificateDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CertificateDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

Widget _teacherBlock({
  required bool preview,
  required String teacherName,
  bool compact = false,
}) {
  final labelSize = preview ? 7.0 : (compact ? 10.0 : 14.0);
  final nameSize = preview ? 10.0 : (compact ? 14.0 : 20.0);
  final labelTracking = preview ? 2.0 : (compact ? 3.0 : 5.0);

  final label = _certificateLatinText(
    'CLASS TEACHER',
    style: _certificateLatinStyle(
      fontSize: labelSize,
      fontWeight: AppFonts.regular,
      color: AppColors.textMuted.withValues(alpha: preview ? 0.8 : 1),
      letterSpacing: labelTracking,
    ),
    maxLines: 1,
    softWrap: false,
  );

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (preview)
        label
      else
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: UnconstrainedBox(child: label),
          ),
        ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: UnconstrainedBox(
          child: Text(
            teacherName,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.custom(
              fontSize: nameSize,
              fontWeight: AppFonts.medium,
              color: AppColors.primary.withValues(alpha: preview ? 1 : 0.95),
            ),
          ),
        ),
      ),
    ],
  );
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
