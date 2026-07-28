import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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

    final boxSize = MediaQuery.sizeOf(context).width >= 640 ? 48.0 : 40.0;

    return Directionality(
      textDirection: TextDirection.ltr,
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _chars.length; i++)
                  if (_chars[i] == ' ')
                    SizedBox(
                      width: boxSize,
                      height: boxSize,
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 28,
                      ),
                    )
                  else
                    _CharBox(
                      size: boxSize,
                      value: _values[i],
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
    required this.value,
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final double size;
  final String value;
  final String state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = switch (state) {
      'correct' => (
          const Color(0x66166534),
          const Color(0xFF22C55E),
          const Color(0xFF4ADE80),
        ),
      'wrong' => (
          const Color(0x667F1D1D),
          const Color(0xFFEF4444),
          const Color(0xFFF87171),
        ),
      'filled' => (
          const Color(0x333B82F6),
          const Color(0xFF60A5FA),
          Colors.white,
        ),
      _ => (
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.2),
          Colors.white,
        ),
    };

    return SizedBox(
      width: size,
      height: size,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          color: colors.$3,
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: colors.$1,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: colors.$2, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(color: colors.$2, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide(
              color: state == 'empty'
                  ? Colors.white.withValues(alpha: 0.5)
                  : colors.$2,
              width: 2,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
