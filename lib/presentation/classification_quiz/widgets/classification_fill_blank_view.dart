import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../models/classification_question.dart';
import 'classification_answer_palette.dart';

class ClassificationFillBlankView extends StatefulWidget {
  const ClassificationFillBlankView({
    super.key,
    required this.question,
    required this.onSubmitReady,
    required this.onAnswerChange,
    required this.onCorrectChange,
    required this.onAnswered,
    this.hideTitle = false,
    this.examStyle = false,
  });

  final ClassificationFillBlankQuestion question;
  final ValueChanged<VoidCallback> onSubmitReady;
  final ValueChanged<bool> onAnswerChange;
  final ValueChanged<bool> onCorrectChange;
  final ValueChanged<String> onAnswered;
  final bool hideTitle;
  final bool examStyle;

  @override
  State<ClassificationFillBlankView> createState() =>
      _ClassificationFillBlankViewState();
}

class _ClassificationFillBlankViewState extends State<ClassificationFillBlankView> {
  late List<String> _chars;
  late List<String> _values;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  var _submitted = false;
  var _anyFocused = false;

  @override
  void initState() {
    super.initState();
    _resetFields();
    widget.onSubmitReady(_submit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAnswerChange(_hasAnyInput && !_submitted);
    });
  }

  @override
  void didUpdateWidget(covariant ClassificationFillBlankView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _disposeFields();
      _submitted = false;
      _resetFields();
      widget.onSubmitReady(_submit);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onAnswerChange(_hasAnyInput && !_submitted);
    });
  }

  @override
  void dispose() {
    _disposeFields();
    super.dispose();
  }

  void _resetFields() {
    _chars = widget.question.correctAnswer.split('');
    _values = List.filled(_chars.length, '');
    _focusNodes = List.generate(_chars.length, (_) => FocusNode());
    for (final node in _focusNodes) {
      node.addListener(_onAnyFocusChange);
    }
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
      node.removeListener(_onAnyFocusChange);
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  void _onAnyFocusChange() {
    final focused = _focusNodes.any((node) => node.hasFocus);
    if (focused == _anyFocused) return;
    setState(() => _anyFocused = focused);
  }

  bool get _hasAnyInput => _values.any((value) => value.isNotEmpty);

  String get _fullAnswer => List.generate(
        _chars.length,
        (i) => _chars[i] == ' ' ? ' ' : _values[i],
      ).join();

  bool get _isCorrect {
    final userFiltered = StringBuffer();
    for (var i = 0; i < _chars.length; i++) {
      if (_chars[i] != ' ') userFiltered.write(_values[i]);
    }
    final correctFiltered = _chars.where((c) => c != ' ').join();
    return userFiltered.toString().toLowerCase() ==
        correctFiltered.toLowerCase();
  }

  void _submit() {
    if (_submitted) return;
    setState(() => _submitted = true);
    widget.onAnswerChange(false);
    widget.onCorrectChange(_isCorrect);
    Future<void>.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      widget.onAnswered(_fullAnswer);
    });
  }

  void _onChanged(int index, String value) {
    if (_submitted) return;
    final char = value.isEmpty ? '' : value.characters.last;
    setState(() {
      _values[index] = char;
      _controllers[index].text = char;
      _controllers[index].selection =
          TextSelection.collapsed(offset: char.length);
    });
    widget.onAnswerChange(_hasAnyInput);
    if (char.isNotEmpty) {
      var next = index + 1;
      while (next < _chars.length && _chars[next] == ' ') {
        next++;
      }
      if (next < _chars.length) _focusNodes[next].requestFocus();
    }
  }

  String _charState(int index) {
    if (!_submitted) {
      return _values[index].isEmpty ? 'empty' : 'filled';
    }
    if (_chars[index] == ' ') return 'space';
    return _values[index].toLowerCase() == _chars[index].toLowerCase()
        ? 'correct'
        : 'wrong';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.examStyle) {
      return _buildExamFillBlank(context);
    }

    final width = MediaQuery.sizeOf(context).width;
    final boxSize = width >= 640 ? 64.0 : 56.0;
    final letterFontSize = width >= 640 ? 30.0 : 24.0;
    final titleFontSize = width >= 640 ? 18.0 : 16.0;
    final showWrongReveal = _submitted && !_isCorrect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.hideTitle)

          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(
              color: AppColors.mainBg3,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 25,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: QuizHtmlText(
              html: widget.question.title,
              baseStyle: AppTypography.bodyLg.copyWith(
                color: AppColors.onDark,
                fontSize: titleFontSize,
                height: 1.625,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            children: [
              if (showWrongReveal) ...[
                _WrongAnswerReveal(chars: _chars),
                const SizedBox(height: 32),
              ],
              Stack(
                clipBehavior: Clip.none,
                children: [

                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.mainBg3.withValues(alpha: 0.5),
                              AppColors.mainBg2.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 160),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.mainBg3.withValues(alpha: 0.9),
                          AppColors.mainBg2.withValues(alpha: 0.9),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 25,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),

                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tiles = <Widget>[];
                          var colorIndex = 0;
                          for (var i = 0; i < _chars.length; i++) {
                            if (_chars[i] == ' ') {
                              tiles.add(
                                SizedBox(
                                  width: 32,
                                  child: Center(
                                    child: Container(
                                      width: 24,
                                      height: 1,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.3),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              tiles.add(
                                _LetterInput(
                                  size: boxSize,
                                  fontSize: letterFontSize,
                                  palette:
                                      ClassificationAnswerPalette.forIndex(
                                    colorIndex++,
                                  ),
                                  state: _charState(i),
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  enabled: !_submitted,
                                  onChanged: (value) => _onChanged(i, value),
                                ),
                              );
                            }
                            if (i < _chars.length - 1) {
                              tiles.add(const SizedBox(width: 16));
                            }
                          }

                          return SizedBox(
                            width: constraints.maxWidth,
                            height: math.max(160.0, boxSize),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: tiles,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamFillBlank(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 768;

    final boxSize = width >= 1024 ? 56.0 : 40.0;
    final showWrongContainer = _submitted && !_isCorrect;

    final containerHeight = mobile ? 240.0 : 360.0;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        height: containerHeight,

        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: showWrongContainer ? AppColors.cardRedBg : AppColors.cardBlueBg,
          borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
          border: Border.all(
            color: showWrongContainer
                ? AppColors.cardRedBorder
                : AppColors.cardBlueBorder,
            width: 2,
          ),

          boxShadow: mobile
              ? null
              : showWrongContainer
                  ? const [
                      BoxShadow(
                        color: AppColors.cardRedGlowOuter,
                        blurRadius: 5,
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: AppColors.cardBlueGlowOuter,
                        blurRadius: 5,
                      ),
                      const BoxShadow(
                        color: AppColors.cardBlueGlowInner,
                        blurRadius: 5,
                        spreadRadius: -2,
                      ),
                      if (_anyFocused && !_submitted) ...const [
                        BoxShadow(
                          color: AppColors.cardBlueGlowOuter,
                          blurRadius: 25,
                        ),
                        BoxShadow(
                          color: AppColors.cardBlueGlowInner,
                          blurRadius: 20,
                          spreadRadius: -4,
                        ),
                      ],
                    ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < _chars.length; i++)
                if (_chars[i] == ' ')
                  SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: Icon(
                      Icons.horizontal_rule_rounded,
                      size: 40,
                      color: AppColors.onDark.withValues(alpha: 0.2),
                    ),
                  )
                else
                  _ExamLetterInput(
                    size: boxSize,
                    state: _charState(i),
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    enabled: !_submitted,
                    mobile: mobile,
                    onChanged: (value) => _onChanged(i, value),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrongAnswerReveal extends StatelessWidget {
  const _WrongAnswerReveal({required this.chars});

  final List<String> chars;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tileSize = width >= 640 ? 56.0 : 48.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x26F59E0B), Color(0x26F97316)],
        ),
        border: Border.all(color: const Color(0x66F59E0B), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'الإجابة الصحيحة',
            style: TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < chars.length; i++)
                  if (chars[i] == ' ')
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 1,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0x80F59E0B),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: tileSize,
                      height: tileSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppRadius.tailwindXl),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x4DF59E0B), Color(0x4DF97316)],
                        ),
                        border: Border.all(
                          color: const Color(0x99F59E0B),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        chars[i],
                        style: TextStyle(
                          color: const Color(0xFFFCD34D),
                          fontSize: width >= 640 ? 22 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterInput extends StatelessWidget {
  const _LetterInput({
    required this.size,
    required this.fontSize,
    required this.palette,
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final double size;
  final double fontSize;
  final ClassificationAnswerPalette palette;
  final String state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {

    final colors = switch (state) {
      'correct' => (
          const Color(0x4D10B981),
          const Color(0x4D059669),
          const Color(0xFF10B981),
          const Color(0xFF6EE7B7),
        ),
      'wrong' => (
          const Color(0x4DF43F5E),
          const Color(0x4DE11D48),
          const Color(0xFFF43F5E),
          const Color(0xFFFDA4AF),
        ),
      'filled' => (
          palette.gradientStart,
          palette.gradientEnd,
          palette.border,
          palette.text,
        ),
      _ => (
          palette.gradientStart,
          palette.gradientEnd,
          palette.border,
          AppColors.onDark,
        ),
    };

    final neonColor = switch (state) {
      'correct' => const Color(0x3310B981),
      'wrong' => const Color(0x33F43F5E),
      _ => palette.border.withValues(alpha: 0.2),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.$1, colors.$2],
            ),
            borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
            border: Border.all(color: colors.$3, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: neonColor,
                blurRadius: state == 'filled' ||
                        state == 'correct' ||
                        state == 'wrong'
                    ? 16
                    : 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            maxLength: 1,
            cursorColor: colors.$4,
            style: TextStyle(
              color: colors.$4,
              fontSize: fontSize,
              fontWeight: AppFonts.bold,
              fontFamily: AppFonts.bahij,
            ),
            decoration: const InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
            ),
            inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
            onChanged: onChanged,
          ),
        ),
        if (state == 'correct')
          const Positioned(
            top: -8,
            right: -8,
            child: _FeedbackBadge(
              color: Color(0xFF10B981),
              icon: Icons.check_rounded,
            ),
          ),
        if (state == 'wrong')
          const Positioned(
            top: -8,
            right: -8,
            child: _FeedbackBadge(
              color: Color(0xFFF43F5E),
              icon: Icons.close_rounded,
            ),
          ),
      ],
    );
  }
}

class _ExamLetterInput extends StatefulWidget {
  const _ExamLetterInput({
    required this.size,
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
    this.mobile = false,
  });

  final double size;
  final String state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final bool mobile;

  @override
  State<_ExamLetterInput> createState() => _ExamLetterInputState();
}

class _ExamLetterInputState extends State<_ExamLetterInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final mobile = widget.mobile;

    final (Color bg, Color border, Color text, List<BoxShadow> shadows) =
        switch (widget.state) {
      'correct' => (
          AppColors.cardGreenBg,
          AppColors.cardGreenBorder,
          AppColors.cardGreenIcon,
          mobile
              ? const <BoxShadow>[]
              : const [
                  BoxShadow(color: AppColors.cardGreenGlowOuter, blurRadius: 20),
                  BoxShadow(
                    color: AppColors.cardGreenGlowInner,
                    blurRadius: 15,
                    spreadRadius: -4,
                  ),
                ],
        ),
      'wrong' => (
          AppColors.cardRedBg,
          AppColors.cardRedBorder,
          AppColors.cardRedIcon,
          mobile
              ? const <BoxShadow>[]
              : const [
                  BoxShadow(color: AppColors.cardRedGlowOuter, blurRadius: 20),
                  BoxShadow(
                    color: AppColors.cardRedGlowInner,
                    blurRadius: 15,
                    spreadRadius: -4,
                  ),
                ],
        ),
      'filled' => (
          AppColors.cardBlueBg.withValues(alpha: 0.6),
          AppColors.cardBlueBorder,
          AppColors.onDark,
          mobile
              ? const <BoxShadow>[]
              : const [
                  BoxShadow(color: AppColors.cardBlueGlowOuter, blurRadius: 25),
                  BoxShadow(
                    color: AppColors.cardBlueGlowInner,
                    blurRadius: 10,
                    spreadRadius: -4,
                  ),
                ],
        ),

      _ => (
          AppColors.cardBlueBg.withValues(alpha: 0.4),
          AppColors.overlayWhite10,
          AppColors.onDark,
          (!mobile && focused)
              ? const [
                  BoxShadow(color: AppColors.cardBlueGlowOuter, blurRadius: 25),
                  BoxShadow(
                    color: AppColors.cardBlueGlowInner,
                    blurRadius: 10,
                    spreadRadius: -4,
                  ),
                ]
              : const <BoxShadow>[],
        ),
    };

    final borderColor =
        widget.state == 'empty' && focused ? AppColors.cardBlueBorder : border;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.shadcnLg),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Theme(

        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLength: 1,
          cursorColor: AppColors.onDark,
          cursorWidth: 1.5,
          style: TextStyle(
            color: text,
            fontSize: 24,
            fontWeight: AppFonts.bold,
            fontFamily: AppFonts.bahij,
            height: 1.0,
          ),
          decoration: const InputDecoration(
            counterText: '',
            filled: false,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

class _FeedbackBadge extends StatelessWidget {
  const _FeedbackBadge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, size: 13, color: Colors.white),
    );
  }
}
