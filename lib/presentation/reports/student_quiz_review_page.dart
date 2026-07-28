import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/quizzes/answered_question_models.dart';
import '../../data/quizzes/unit_quiz_api.dart';
import '../exam/widgets/exam_review_question_list.dart';
import 'quiz_report_pdf_delivery.dart';
import 'quiz_report_print_html.dart';

class StudentQuizReviewPage extends StatefulWidget {
  const StudentQuizReviewPage({
    super.key,
    required this.quizId,
    required this.attemptId,
  });

  final int quizId;
  final String attemptId;

  static const routePath = '/quiz-preview/:quizId/:attemptId/student';
  static const routeName = 'student-quiz-review';

  static String pathFor({required int quizId, required String attemptId}) =>
      '/quiz-preview/$quizId/$attemptId/student';

  @override
  State<StudentQuizReviewPage> createState() => _StudentQuizReviewPageState();
}

class _StudentQuizReviewPageState extends State<StudentQuizReviewPage> {
  var _loading = true;
  var _printing = false;
  String? _error;
  QuizAttemptReview? _review;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await UnitQuizApi.getFirstAttemptReview(
        quizId: widget.quizId,
        attemptId: widget.attemptId,
      );
      if (!mounted) return;
      setState(() {
        _review = data;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل التقرير';
        _loading = false;
      });
    }
  }

  Future<void> _printReport() async {
    final review = _review;
    if (review == null || _printing) return;

    final fileName = 'quiz-report-${widget.attemptId}.pdf';
    final delivery = startQuizReportPdfDelivery(fileName: fileName);

    setState(() => _printing = true);
    try {
      final score = review.score ?? 0;
      final points = review.pointsAwarded ?? 0;
      final accuracy = score > 0 ? (points / score) * 100 : 0.0;
      final total = QuizReportPrintHtml.countQuestions(review.answeredQuestions);

      final html = QuizReportPrintHtml.build(
        review: review,
        accuracy: accuracy,
        totalQuestions: total,
      );

      final pdfBytes = await UnitQuizApi.downloadReportPdf(
        quizId: widget.quizId,
        attemptId: widget.attemptId,
        html: html,
        styles: QuizReportPrintHtml.styles,
      );

      if (!mounted) return;
      await delivery.complete(pdfBytes);
    } on ApiException catch (error) {
      delivery.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      delivery.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر طباعة التقرير')),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = _review;
    final score = review?.score ?? 0;
    final points = review?.pointsAwarded ?? 0;
    final accuracy = score > 0 ? (points / score) * 100 : 0.0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.mainBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReviewHeader(
              loading: _loading,
              printing: _printing,
              review: review,
              accuracy: accuracy,
              onBack: () => context.pop(),
              onPrint: review == null ? null : _printReport,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.blue),
                    )
                  : _error != null
                      ? _ReviewError(message: _error!, onRetry: _loadReview)
                      : _ReviewBody(questions: review!.answeredQuestions),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.loading,
    required this.printing,
    required this.accuracy,
    required this.onBack,
    this.review,
    this.onPrint,
  });

  final bool loading;
  final bool printing;
  final double accuracy;
  final QuizAttemptReview? review;
  final VoidCallback onBack;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final showStats = !loading && review != null;
    final width = MediaQuery.sizeOf(context).width;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.mainBg.withValues(alpha: 0.8),
            border: const Border(
              bottom: BorderSide(color: Color(0xFF313648)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Row(
                    children: [
                      _ReviewHeaderButton(
                        onPressed: onBack,
                        backgroundColor: const Color(0xFF1B2130),
                        foregroundColor: AppColors.textMuted,
                        borderColor: const Color(0xFF313648),
                        icon: Icons.arrow_back_rounded,
                        label: 'العودة',
                      ),
                      const Spacer(),
                      if (showStats) ...[
                        if (width >= 768) ...[
                          _HeaderMiniStats(
                            pointsAwarded: review!.pointsAwarded ?? 0,
                            score: review!.score ?? 0,
                            accuracy: accuracy,
                          ),
                          const SizedBox(width: 12),
                        ],
                        _ReviewHeaderButton(
                          onPressed: printing ? null : onPrint,
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          borderColor: Colors.transparent,
                          icon: printing ? null : Icons.print_rounded,
                          label: 'طباعة التقرير',
                          loading: printing,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332072E0),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ],
                    ],
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

class _ReviewHeaderButton extends StatelessWidget {
  const _ReviewHeaderButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.label,
    this.icon,
    this.loading = false,
    this.boxShadow,
  });

  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final IconData? icon;
  final String label;
  final bool loading;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
            border: Border.all(color: borderColor),
            boxShadow: boxShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foregroundColor,
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, size: 16, color: foregroundColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTypography.bodySm.copyWith(
                    color: foregroundColor,
                    fontWeight: AppFonts.medium,
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

class _HeaderMiniStats extends StatelessWidget {
  const _HeaderMiniStats({
    required this.pointsAwarded,
    required this.score,
    required this.accuracy,
  });

  final int pointsAwarded;
  final int score;
  final double accuracy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mainBg2,
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        border: Border.all(color: const Color(0xFF313648)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'الدرجة:',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Text(
                '$pointsAwarded/$score',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.bold,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF313648),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الدقة:',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blue, Color(0xFF7B4FE0)],
                ).createShader(bounds),
                child: Text(
                  '${accuracy.toStringAsFixed(2)}%',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: AppFonts.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.base),
            OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.questions});

  final List<AnsweredQuizQuestion> questions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.xl,
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF12161F), Color(0xFF1B2130)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: const Color(0xFF313648)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A2072E0),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.base),
              child: ExamReviewQuestionList(
                questions: questions,
                shrinkWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
