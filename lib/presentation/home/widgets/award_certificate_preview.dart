import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
}) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      ),
    ),
  );
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
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
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
                    child: _certificatePreviewColumn(
                      padding: EdgeInsets.zero,
                      children: _withPreviewGaps([
                        _certificateLatinText(
                          'CERTIFICATE',
                          style: _certificateLatinStyle(
                            fontSize: 12,
                            fontWeight: AppFonts.semibold,
                            color: AppColors.certificateAccent,
                            letterSpacing: 3,
                          ),
                        ),
                        _certificateLatinText(
                          'PRIMEACADEMY',
                          style: _certificateLatinStyle(
                            fontSize: 11,
                            fontWeight: AppFonts.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.55,
                          ),
                        ),
                        _certificatePremiumQuoteBox('والله انك كفو يا اسطوره'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
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
                        Container(
                          height: 0.5,
                          width: 48,
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
                        _teacherBlock(preview: true, teacherName: teacherName),
                      ]),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 560;
        final isMobile = width < 768;

        final outerPadding = compact ? 8.0 : 16.0;
        final innerPadding = compact ? 16.0 : (isMobile ? 24.0 : 32.0);
        final titleSize = compact ? 26.0 : (isMobile ? 32.0 : 48.0);
        final brandSize = compact ? 20.0 : (isMobile ? 26.0 : 36.0);
        final quoteSize = compact || isMobile ? 24.0 : 30.0;
        final nameSize = compact ? 20.0 : (isMobile ? 28.0 : 48.0);
        final titleTracking = compact ? 6.0 : (isMobile ? 8.0 : 10.0);
        final sectionGap = compact ? 12.0 : (isMobile ? 20.0 : 24.0);

        return Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Container(
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
                      padding: EdgeInsets.all(innerPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _certificateLatinText(
                            'CERTIFICATE',
                            style: _certificateLatinStyle(
                              fontSize: titleSize,
                              fontWeight: AppFonts.light,
                              color: AppColors.certificateAccent,
                              letterSpacing: titleTracking,
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
                          SizedBox(height: compact ? 4 : 8),
                          _certificateLatinText(
                            'PRIMEACADEMY',
                            style: _certificateLatinStyle(
                              fontSize: brandSize,
                              fontWeight: AppFonts.bold,
                              color: AppColors.primary,
                              letterSpacing: compact ? 1 : 2,
                            ),
                          ),
                          SizedBox(height: sectionGap),
                          _certificatePremiumQuoteBox(
                            'والله انك كفو يا اسطوره',
                            fontSize: quoteSize,
                          ),
                          SizedBox(height: sectionGap),
                          Text(
                            studentName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.custom(
                              fontSize: nameSize,
                              fontWeight: AppFonts.semibold,
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 12),
                          Container(
                            height: compact ? 1 : 2,
                            width: compact ? 72 : 96,
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
                          SizedBox(height: sectionGap),
                          _teacherBlock(
                            preview: false,
                            compact: compact,
                            teacherName: teacherName,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    return _previewShell(
      borderRadius: AppRadius.borderMd,
      padding: const EdgeInsets.all(6),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.blue, width: 2),
                borderRadius: AppRadius.borderMd,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: CustomPaint(
                painter: _CertificateDashedBorderPainter(
                  color: AppColors.blue.withValues(alpha: 0.4),
                  radius: AppRadius.md - 9,
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
                    colors: [AppColors.blue, AppColors.purpleLight],
                  ),
                  borderRadius: AppRadius.borderMd,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _certificatePreviewColumn(
              children: _withPreviewGaps([
              const Icon(Icons.workspace_premium, color: AppColors.blue, size: 14),
              Text(
                'Certificate',
                style: AppTypography.custom(
                  fontSize: 11,
                  fontWeight: AppFonts.bold,
                  color: AppColors.blue,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'PRIMEACADEMY',
                style: AppTypography.custom(
                  fontSize: 10,
                  fontWeight: AppFonts.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'This Certificate is Proudly Presented to',
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  fontSize: 8,
                  fontWeight: AppFonts.light,
                  color: AppColors.textMuted,
                  letterSpacing: 3,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.blue, width: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.blue.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: _CertificateQuoteText(
                  text: 'بنتوقعلك مستقبل كبير جدا ان شاء الله',
                ),
              ),
              _teacherBlock(preview: true, teacherName: teacherName),
            ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _full() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        border: Border.all(color: AppColors.blue, width: 2),
        borderRadius: AppRadius.borderAuthButton,
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.purpleLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Certificate',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 32,
              letterSpacing: 6,
              fontWeight: AppFonts.semibold,
            ),
          ),
          Text(
            'of Achievement',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'PRIMEACADEMY',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              letterSpacing: 2,
              fontWeight: AppFonts.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This Certificate is Proudly Presented to',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.blue, width: 2)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              studentName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: AppFonts.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'بنتوقعلك مستقبل كبير جدا ان شاء الله',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.yellow,
              fontSize: 20,
              fontWeight: AppFonts.semibold,
            ),
          ),
          const SizedBox(height: 24),
          _teacherBlock(preview: false, teacherName: teacherName),
        ],
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
    return _previewShell(
      borderRadius: AppRadius.borderMd,
      clipBehavior: Clip.antiAlias,
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
                  colors: [AppColors.blue, AppColors.purpleLight],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _CertificateStripePatternOverlay()),
          Positioned.fill(
            child: _certificatePreviewColumn(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              children: _withPreviewGaps([
                Text(
                  'Certificate',
                  style: AppTypography.custom(
                    fontSize: 12,
                    fontWeight: AppFonts.bold,
                    color: AppColors.blue,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'PRIMEACADEMY',
                  style: AppTypography.custom(
                    fontSize: 11,
                    fontWeight: AppFonts.bold,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  height: 1,
                  width: 32,
                  color: AppColors.blue,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withValues(alpha: 0.08),
                        AppColors.purpleLight.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _CertificateQuoteText(
                    text: 'أنت من الأبطال الذين يصنعون الفرق',
                  ),
                ),
                Text(
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
                _teacherBlock(preview: true, teacherName: teacherName),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _full() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: AppRadius.borderAuthForm,
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
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
                  colors: [AppColors.blue, AppColors.purpleLight],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 32, 32),
            child: Column(
              children: [
                Text(
                  'Certificate',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 40,
                    letterSpacing: 6,
                    fontWeight: AppFonts.semibold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PRIMEACADEMY',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    letterSpacing: 2,
                    fontWeight: AppFonts.semibold,
                  ),
                ),
                Container(
                  height: 2,
                  width: 64,
                  color: AppColors.blue,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue.withValues(alpha: 0.08),
                        AppColors.purpleLight.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'أنت من الأبطال الذين يصنعون الفرق',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 24,
                      fontWeight: AppFonts.semibold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  studentName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: AppFonts.semibold,
                  ),
                ),
                const SizedBox(height: 24),
                _teacherBlock(preview: false, teacherName: teacherName),
              ],
            ),
          ),
        ],
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
    return _previewShell(
      margin: const EdgeInsets.all(4),
      borderRadius: AppRadius.borderMd,
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -3,
            left: -3,
            child: _hexDecoration(16, 0.3),
          ),
          Positioned(
            bottom: -3,
            right: -3,
            child: _hexDecoration(20, 0.25),
          ),
          const Positioned.fill(child: _CertificateCenterRadialOverlay()),
          Positioned.fill(
            child: _certificatePreviewColumn(
              children: _withPreviewGaps([
              Text(
                'Certificate',
                style: AppTypography.custom(
                  fontSize: 12,
                  fontWeight: AppFonts.bold,
                  color: AppColors.blue,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'PRIMEACADEMY',
                style: AppTypography.custom(
                  fontSize: 11,
                  fontWeight: AppFonts.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.1),
                      AppColors.purpleLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: _CertificateQuoteText(
                  text: 'نُشيد باجتهادك ونتمنى لك دوام التفوق والنجاح',
                  fontSize: 9,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '⟨',
                    style: AppTypography.custom(
                      fontSize: 11,
                      color: AppColors.blue.withValues(alpha: 0.6),
                    ),
                  ),
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
                  Text(
                    '⟩',
                    style: AppTypography.custom(
                      fontSize: 11,
                      color: AppColors.blue.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              _teacherBlock(preview: true, teacherName: teacherName),
            ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _full() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: AppRadius.borderAuthForm,
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Certificate',
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 40,
              letterSpacing: 6,
              fontWeight: AppFonts.semibold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PRIMEACADEMY',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: AppFonts.semibold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.blue.withValues(alpha: 0.1),
                  AppColors.purpleLight.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Text(
              'نُشيد باجتهادك ونتمنى لك دوام التفوق والنجاح',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 24,
                fontWeight: AppFonts.semibold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⟨', style: TextStyle(color: AppColors.blue.withValues(alpha: 0.5), fontSize: 32)),
              Flexible(
                child: Text(
                  studentName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 32,
                    fontWeight: AppFonts.semibold,
                  ),
                ),
              ),
              Text('⟩', style: TextStyle(color: AppColors.blue.withValues(alpha: 0.5), fontSize: 32)),
            ],
          ),
          const SizedBox(height: 24),
          _teacherBlock(preview: false, teacherName: teacherName),
        ],
      ),
    );
  }
}

Widget _hexDecoration(double size, double opacity) {
  return ClipPath(
    clipper: _HexagonClipper(),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withValues(alpha: opacity),
            AppColors.purpleLight.withValues(alpha: opacity),
          ],
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

Widget _certificatePremiumQuoteBox(String text, {double fontSize = 12}) {
  final isPreview = fontSize <= 12;
  final compact = fontSize <= 16;

  final verticalMargin = isPreview ? 4.0 : (compact ? 12.0 : 24.0);
  final verticalPadding = isPreview ? 12.0 : (compact ? 14.0 : 20.0);
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
          child: _CertificateQuoteText(text: text, fontSize: fontSize),
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
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            softWrap: false,
            style: _certificateQuotePreviewStyle(fontSize),
          ),
        ),
      ),
    );
  }
}

List<Widget> _withPreviewGaps(List<Widget> children) {
  if (children.isEmpty) return children;
  final spaced = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    if (i > 0) spaced.add(const SizedBox(height: 6));
    spaced.add(children[i]);
  }
  return spaced;
}

Widget _certificatePreviewColumn({
  required List<Widget> children,
  EdgeInsetsGeometry padding = const EdgeInsets.all(4),
}) {
  return Padding(
    padding: padding,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

Widget _previewShell({
  required Widget child,
  BorderRadius borderRadius = AppRadius.borderMd,
  Border? border,
  EdgeInsetsGeometry? padding,
  EdgeInsetsGeometry? margin,
  Clip clipBehavior = Clip.hardEdge,
}) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    margin: margin,
    padding: padding,
    clipBehavior: clipBehavior,
    decoration: BoxDecoration(
      color: AppColors.secondaryBg,
      borderRadius: borderRadius,
      border: border,
    ),
    child: child,
  );
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
              AppColors.blue,
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
      ..color = AppColors.blue
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

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _certificateLatinText(
        'CLASS TEACHER',
        style: _certificateLatinStyle(
          fontSize: labelSize,
          fontWeight: AppFonts.regular,
          color: AppColors.textMuted.withValues(alpha: preview ? 0.8 : 1),
          letterSpacing: labelTracking,
        ),
      ),
      Text(
        teacherName,
        textAlign: TextAlign.center,
        style: AppTypography.custom(
          fontSize: nameSize,
          fontWeight: AppFonts.medium,
          color: AppColors.primary.withValues(alpha: preview ? 1 : 0.95),
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
