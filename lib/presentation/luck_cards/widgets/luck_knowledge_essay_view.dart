import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/answers_direction.dart';
import '../../../data/quizzes/knowledge_quiz_question.dart';
import '../../quiz/widgets/knowledge_essay_answer_reveal.dart';

class LuckKnowledgeEssayView extends StatefulWidget {
  const LuckKnowledgeEssayView({
    super.key,
    required this.question,
    required this.answered,
    this.isCorrect,
    required this.onSubmit,
  });

  final KnowledgeEssayQuestion question;
  final bool answered;
  /// Parent grade after submit (same validation as web).
  final bool? isCorrect;
  final ValueChanged<String> onSubmit;

  @override
  State<LuckKnowledgeEssayView> createState() => _LuckKnowledgeEssayViewState();
}

class _LuckKnowledgeEssayViewState extends State<LuckKnowledgeEssayView> {
  static const double _textareaHeight = 128;
  static const double _maxWidth = 448;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool? get _gradedCorrect => widget.isCorrect;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void didUpdateWidget(covariant LuckKnowledgeEssayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _onFocusChanged() => setState(() {});

  void _submit() {
    if (widget.answered) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }

  bool _handleKey(KeyEvent event) {
    if (!_focusNode.hasFocus || widget.answered) return false;
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.enter) return false;
    if (HardwareKeyboard.instance.isShiftPressed) return false;
    _submit();
    return true;
  }

  /// After submit: always reveal model answer; green when correct, red when wrong.
  bool get _showCorrectAnswer =>
      widget.answered && _gradedCorrect != null;

  bool get _useGreenRevealTheme {
    final graded = _gradedCorrect;
    return (graded ?? false) || widget.question.markAllAnswersCorrect;
  }

  ({Color border, Color fill}) _inputColors() {
    final graded = _gradedCorrect;
    if (widget.answered && graded != null) {
      final success = graded || widget.question.markAllAnswersCorrect;
      return success
          ? (
              border: const Color(0xFF22C55E),
              fill: const Color(0x33166534),
            )
          : (
              border: const Color(0xFFEF4444),
              fill: const Color(0x337F1D1D),
            );
    }
    return (
      border: _focusNode.hasFocus
          ? Colors.white.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.1),
      fill: Colors.white.withValues(alpha: 0.05),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputColors = _inputColors();
    final canSubmit = _controller.text.trim().isNotEmpty;
    final fieldStyle = AppTypography.bodyLg.copyWith(color: Colors.white);
    final direction = widget.question.answersDirection;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showCorrectAnswer) ...[
            KnowledgeEssayAnswerReveal(
              correctTitles:
                  widget.question.correctAnswers.map((a) => a.title),
              useGreenTheme: _useGreenRevealTheme,
              answersDirection: direction,
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: inputColors.fill,
              borderRadius: AppRadius.borderTailwindXl,
              border: Border.all(color: inputColors.border, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: _textareaHeight,
              width: double.infinity,
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hoverColor: Colors.transparent,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !widget.answered,
                  maxLines: null,
                  expands: true,
                  textDirection: direction.textDirection,
                  textAlign: direction.textAlign,
                  textAlignVertical: TextAlignVertical.top,
                  style: fieldStyle,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'اكتب إجابتك...',
                    hintStyle: fieldStyle.copyWith(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppSpacing.base),
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
          ),
          if (!widget.answered) ...[
            const SizedBox(height: AppSpacing.base),
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: canSubmit ? 1 : 0.3,
                child: GestureDetector(
                  onTap: canSubmit ? _submit : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'تأكيد',
                      style: AppTypography.bodySm.copyWith(
                        color: Colors.black,
                        fontWeight: AppFonts.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
