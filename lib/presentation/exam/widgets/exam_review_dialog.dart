import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/quizzes/answered_question_models.dart';
import '../../../data/quizzes/unit_quiz_api.dart';
import 'exam_review_question_list.dart';

Future<void> showExamReviewDialog(
  BuildContext context, {
  required List<AnsweredQuizQuestion> questions,
  int? quizId,
  String? attemptId,
  bool fetchFromApi = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (context) => _ExamReviewDialog(
      initialQuestions: questions,
      quizId: quizId,
      attemptId: attemptId,
      fetchFromApi: fetchFromApi,
    ),
  );
}

class _ExamReviewDialog extends StatefulWidget {
  const _ExamReviewDialog({
    required this.initialQuestions,
    this.quizId,
    this.attemptId,
    this.fetchFromApi = false,
  });

  final List<AnsweredQuizQuestion> initialQuestions;
  final int? quizId;
  final String? attemptId;
  final bool fetchFromApi;

  @override
  State<_ExamReviewDialog> createState() => _ExamReviewDialogState();
}

class _ExamReviewDialogState extends State<_ExamReviewDialog> {
  late List<AnsweredQuizQuestion> _questions;
  var _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _questions = widget.initialQuestions;
    if (_questions.isEmpty && widget.fetchFromApi) {
      _loadReview();
    }
  }

  Future<void> _loadReview() async {
    final quizId = widget.quizId;
    final attemptId = widget.attemptId;
    if (quizId == null || quizId <= 0 || attemptId == null || attemptId.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final review = await UnitQuizApi.getFirstAttemptReview(
        quizId: quizId,
        attemptId: attemptId,
      );
      if (!mounted) return;
      setState(() {
        _questions = review.answeredQuestions;
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
        _error = 'تعذّر تحميل مراجعة الإجابات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.025,
      ),
      backgroundColor: AppColors.secondaryBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.95,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 8, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0x85808080)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'مراجعة الاختبار',
                        textAlign: TextAlign.start,
                        style: AppTypography.size28.copyWith(
                          color: AppColors.onDark,
                          fontWeight: AppFonts.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.onDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.examAccentBlue,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyMd.copyWith(
                                      color: const Color(0xFFF87171),
                                    ),
                                  ),
                                  if (widget.fetchFromApi) ...[
                                    const SizedBox(height: AppSpacing.base),
                                    OutlinedButton(
                                      onPressed: _loadReview,
                                      child: const Text('إعادة المحاولة'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : _questions.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد إجابات للمراجعة',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.tabInactive,
                                  ),
                                ),
                              )
                            : ExamReviewQuestionList(questions: _questions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
