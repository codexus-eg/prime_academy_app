import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_html_text.dart';

class ExamEssayInput extends StatefulWidget {
  const ExamEssayInput({
    super.key,
    required this.questionTitle,
    required this.controller,
    required this.onAnswerChange,
    this.isSubmitted = false,
    this.isCorrect,
    this.enabled = true,
  });

  final String questionTitle;
  final TextEditingController controller;
  final ValueChanged<bool> onAnswerChange;
  final bool isSubmitted;
  final bool? isCorrect;
  final bool enabled;

  @override
  State<ExamEssayInput> createState() => _ExamEssayInputState();
}

class _ExamEssayInputState extends State<ExamEssayInput> {
  final _focusNode = FocusNode();
  var _focused = false;

  static const _labelColor = Color(0xB39AA0A7);
  static const _placeholderColor = Color(0x669AA0A7);

  static const _fieldHeight = 160.0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant ExamEssayInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
  }

  void _onTextChange() {
    widget.onAnswerChange(widget.controller.text.trim().isNotEmpty);
    setState(() {});
  }

  TextDirection _resolveDirection(String text) {
    final source = text.trim().isNotEmpty
        ? text
        : QuizHtmlText.plainText(widget.questionTitle);
    return RegExp(r'[\u0600-\u06FF]').hasMatch(source)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 768;
    final direction = _resolveDirection(widget.controller.text);
    final showWrong = widget.isSubmitted && widget.isCorrect == false;
    final showCorrect = widget.isSubmitted && widget.isCorrect == true;

    final borderColor = showWrong
        ? AppColors.cardRedBorder
        : showCorrect
            ? AppColors.cardGreenBorder
            : AppColors.cardBlueBorder;
    final fillColor = showWrong
        ? AppColors.cardRedBg
        : showCorrect
            ? AppColors.cardGreenBg
            : AppColors.cardBlueBg;

    final List<BoxShadow>? boxShadow = mobile
        ? null
        : showWrong
            ? const [
                BoxShadow(
                  color: AppColors.cardRedGlowOuter,
                  blurRadius: 20,
                ),
              ]
            : showCorrect
                ? const [
                    BoxShadow(
                      color: AppColors.cardGreenGlowOuter,
                      blurRadius: 20,
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
                    if (_focused && !widget.isSubmitted) ...const [
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
                  ];

    return LayoutBuilder(
      builder: (context, constraints) {

        final parentW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : width;
        final fieldWidth = parentW >= 640 ? parentW * 0.8 : parentW * 0.95;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: fieldWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اكتب اجابتك',
                  style: AppTypography.bodySm.copyWith(
                    color: _labelColor,
                    fontWeight: AppFonts.medium,
                    letterSpacing: 0.4,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: boxShadow,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: const InputDecorationTheme(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        isDense: true,
                      ),
                    ),
                    child: SizedBox(
                      height: _fieldHeight,
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled && !widget.isSubmitted,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textDirection: direction,
                        textAlign: direction == TextDirection.rtl
                            ? TextAlign.right
                            : TextAlign.left,
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onDark,
                          height: 1.5,
                        ),
                        cursorColor: AppColors.onDark,
                        decoration: const InputDecoration(
                          hintText: '...',
                          hintStyle: TextStyle(color: _placeholderColor),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
