import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/answers_direction.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/knowledge_quiz_question.dart';

class LuckKnowledgeFillView extends StatefulWidget {
  const LuckKnowledgeFillView({
    super.key,
    required this.question,
    required this.answered,
    required this.isCorrect,
    required this.onSubmit,
  });

  final KnowledgeFillBlankQuestion question;
  final bool answered;
  final bool? isCorrect;
  final ValueChanged<String> onSubmit;

  @override
  State<LuckKnowledgeFillView> createState() => _LuckKnowledgeFillViewState();
}

class _LuckKnowledgeFillViewState extends State<LuckKnowledgeFillView> {
  late List<String> _chars;
  late List<String> _values;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _resetFields();
  }

  @override
  void didUpdateWidget(covariant LuckKnowledgeFillView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _disposeFields();
      _resetFields();
    }
  }

  @override
  void dispose() {
    _disposeFields();
    super.dispose();
  }

  void _resetFields() {
    final plain = QuizHtmlText.plainText(widget.question.correctAnswerText);
    _chars = plain.split('');
    _values = List.filled(_chars.length, '');
    _focusNodes = List.generate(_chars.length, (_) => FocusNode());
    _controllers = List.generate(
      _chars.length,
      (_) => TextEditingController(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final first = _chars.indexWhere((c) => c != ' ');
      if (first >= 0) _focusNodes[first].requestFocus();
    });
  }

  void _disposeFields() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  String get _fullAnswer => List.generate(
        _chars.length,
        (i) => _chars[i] == ' ' ? ' ' : _values[i],
      ).join();

  bool get _allFilled {
    for (var i = 0; i < _chars.length; i++) {
      if (_chars[i] != ' ' && _values[i].trim().isEmpty) return false;
    }
    return _chars.any((c) => c != ' ');
  }

  void _maybeAutoSubmit() {
    if (widget.answered || !_allFilled) return;
    widget.onSubmit(_fullAnswer);
  }

  void _onChanged(int index, String value) {
    if (widget.answered) return;
    final char = value.isEmpty ? '' : value.characters.last;
    setState(() {
      _values[index] = char;
      _controllers[index].text = char;
      _controllers[index].selection =
          TextSelection.collapsed(offset: char.length);
    });
    if (char.isNotEmpty) {
      var next = index + 1;
      while (next < _chars.length && _chars[next] == ' ') {
        next++;
      }
      if (next < _chars.length) _focusNodes[next].requestFocus();
    }
    _maybeAutoSubmit();
  }

  String _charState(int index) {
    if (!widget.answered) {
      return _values[index].isEmpty ? 'empty' : 'filled';
    }
    if (_chars[index] == ' ') return 'space';
    return _values[index].toLowerCase() == _chars[index].toLowerCase()
        ? 'correct'
        : 'wrong';
  }

  @override
  Widget build(BuildContext context) {
    final plainCorrect = QuizHtmlText.plainText(widget.question.correctAnswerText);
    final studentAnswer = _fullAnswer.trim();
    final showCorrectBanner = widget.answered &&
        widget.isCorrect == false &&
        studentAnswer.toLowerCase() != plainCorrect.toLowerCase();

    // Web: `w-10 h-10 lg:w-12 lg:h-12` (lg = 1024px).
    final boxSize = MediaQuery.sizeOf(context).width >= 1024 ? 48.0 : 40.0;

    return Directionality(
      textDirection: widget.question.answersDirection.textDirection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCorrectBanner) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: const Color(0x1AF59E0B),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: const Color(0x4DF59E0B)),
              ),
              child: Column(
                children: [
                  Text(
                    'الإجابة الصحيحة',
                    style: AppTypography.bodySm.copyWith(
                      color: const Color(0xFFFBBF24),
                      fontWeight: AppFonts.semibold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    plainCorrect,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLg.copyWith(
                      color: Colors.white,
                      fontWeight: AppFonts.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _chars.length; i++)
                  if (_chars[i] == ' ')
                    SizedBox(
                      width: boxSize,
                      height: boxSize,
                      child: Center(
                        child: Container(
                          width: boxSize * 0.55,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    )
                  else
                    _CharBox(
                      size: boxSize,
                      state: _charState(i),
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      enabled: !widget.answered,
                      onChanged: (value) => _onChanged(i, value),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharBox extends StatelessWidget {
  const _CharBox({
    required this.size,
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final double size;
  final String state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // Web: rounded-lg (8px), border-2, text-xl font-bold.
    // empty: bg-white/5 border-white/20 focus:border-white/50
    // filled: bg-accent-bg-500/20 border-accent-bg-400
    // correct/wrong: green / red as on the web fill question.
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final Color fill;
        final Color border;
        final Color text;
        switch (state) {
          case 'correct':
            fill = const Color(0x66166534);
            border = const Color(0xFF22C55E);
            text = const Color(0xFF4ADE80);
          case 'wrong':
            fill = const Color(0x667F1D1D);
            border = const Color(0xFFEF4444);
            text = const Color(0xFFF87171);
          case 'filled':
            fill = AppColors.blue.withValues(alpha: 0.2);
            border = const Color(0xFF60A5FA);
            text = Colors.white;
          default:
            fill = Colors.white.withValues(alpha: 0.05);
            border = Colors.white.withValues(alpha: focused ? 0.5 : 0.2);
            text = Colors.white;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
            border: Border.all(color: border, width: 2),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                counterStyle: TextStyle(fontSize: 0, height: 0),
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              maxLength: 1,
              cursorColor: Colors.white,
              cursorWidth: 1.5,
              style: TextStyle(
                color: text,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
              ],
              decoration: const InputDecoration(
                counterText: '',
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
