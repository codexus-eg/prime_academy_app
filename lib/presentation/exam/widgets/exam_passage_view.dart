import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/quiz_html_text.dart';
import '../../../data/quizzes/answered_question_models.dart';
import '../../../data/quizzes/unit_quiz_question.dart';

typedef ExamPassageMarkChild = Future<void> Function({
  required String questionId,
  required String type,
  required Object answers,
});

class ExamPassageView extends StatefulWidget {
  const ExamPassageView({
    super.key,
    required this.question,
    required this.questionBuilder,
    required this.onMarkChild,
    required this.onPassageComplete,
    required this.onChildIndexChange,
  });

  final UnitPassageQuestion question;
  final Widget Function(UnitQuizQuestion child, ExamPassageMarkChild markChild)
      questionBuilder;
  final ExamPassageMarkChild onMarkChild;
  final Future<void> Function() onPassageComplete;
  final ValueChanged<int> onChildIndexChange;

  @override
  State<ExamPassageView> createState() => _ExamPassageViewState();
}

class _ExamPassageViewState extends State<ExamPassageView> {
  static const _desktopBreakpoint = 768.0;

  _PassageTab _mobileTab = _PassageTab.passage;
  _PassageViewMode _viewMode = _PassageViewMode.list;
  var _activePassage = 0;
  int? _currentQuestionIndex;
  final _answeredIds = <String>{};
  var _submitting = false;

  List<UnitQuizQuestion> get _unansweredQuestions => widget
      .question.childQuestions
      .where((q) => !_answeredIds.contains(q.id))
      .toList();

  UnitQuizQuestion? get _currentQuestion {
    final index = _currentQuestionIndex;
    if (index == null) return null;
    final unanswered = _unansweredQuestions;
    if (index < 0 || index >= unanswered.length) return null;
    return unanswered[index];
  }

  @override
  void didUpdateWidget(covariant ExamPassageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _resetState();
    }
  }

  void _resetState() {
    _mobileTab = _PassageTab.passage;
    _viewMode = _PassageViewMode.list;
    _activePassage = 0;
    _currentQuestionIndex = null;
    _answeredIds.clear();
    _submitting = false;
    widget.onChildIndexChange(-1);
  }

  void _selectQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
      _viewMode = _PassageViewMode.question;
      _mobileTab = _PassageTab.questions;
    });
    _syncChildIndex();
  }

  void _backToList() {
    setState(() {
      _viewMode = _PassageViewMode.list;
      _currentQuestionIndex = null;
      _mobileTab = _PassageTab.questions;
    });
    widget.onChildIndexChange(-1);
  }

  void _syncChildIndex() {
    final current = _currentQuestion;
    if (current == null) {
      widget.onChildIndexChange(-1);
      return;
    }
    final index =
        widget.question.childQuestions.indexWhere((q) => q.id == current.id);
    widget.onChildIndexChange(index);
  }

  Future<void> _handleChildSubmit({
    required String questionId,
    required String type,
    required Object answers,
  }) async {
    if (_submitting) return;
    _submitting = true;
    try {
      await widget.onMarkChild(
        questionId: questionId,
        type: type,
        answers: answers,
      );
      if (!mounted) return;

      setState(() => _answeredIds.add(questionId));

      if (_answeredIds.length >= widget.question.childQuestions.length) {
        await widget.onPassageComplete();
        return;
      }

      final remaining = _unansweredQuestions;
      if (remaining.isEmpty) {
        _backToList();
      } else {
        setState(() {
          _currentQuestionIndex = 0;
          _viewMode = _PassageViewMode.question;
        });
        _syncChildIndex();
      }
    } finally {
      _submitting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _desktopBreakpoint;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDesktop) ...[
              _MobileTabs(
                unansweredCount: _unansweredQuestions.length,
                activeTab: _mobileTab,
                onTabChanged: (tab) => setState(() => _mobileTab = tab),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildQuestionsSide(
                            isMobileLayout: false,
                            listTitle:
                                'الأسئلة (${_unansweredQuestions.length})',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildPassageSide(
                            isMobileLayout: false,
                          ),
                        ),
                      ],
                    )
                  : _mobileTab == _PassageTab.questions
                      ? _buildQuestionsSide(
                          isMobileLayout: true,
                          listTitle: 'الأسئلة',
                        )
                      : _buildPassageSide(
                          isMobileLayout: true,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSide({
    required bool isMobileLayout,
    required String listTitle,
  }) {
    if (_viewMode == _PassageViewMode.list) {
      return _PassagePanel(
        isMobileLayout: isMobileLayout,
        borderColor: _PassageTokens.questionsBorder.withValues(alpha: 0.5),
        backgroundColor: _PassageTokens.questionsBg.withValues(alpha: 0.2),
        glowColor: _PassageTokens.questionsGlow,
        header: _PanelHeader(
          badge: 'Q',
          badgeColor: _PassageTokens.questionsIcon,
          title: listTitle,
          isMobileLayout: isMobileLayout,
        ),
        child: _QuestionsList(
          questions: _unansweredQuestions,
          onSelect: _selectQuestion,
          isMobileLayout: isMobileLayout,
        ),
      );
    }

    final current = _currentQuestion;
    return _PassagePanel(
      isMobileLayout: isMobileLayout,
      borderColor: _PassageTokens.questionsBorder.withValues(alpha: 0.5),
      backgroundColor: _PassageTokens.questionsBg.withValues(alpha: 0.2),
      glowColor: _PassageTokens.questionsGlow,
      header: _BackHeader(onBack: _backToList, isMobileLayout: isMobileLayout),
      child: current == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: widget.questionBuilder(current, _handleChildSubmit),
              ),
            ),
    );
  }

  Widget _buildPassageSide({
    required bool isMobileLayout,
  }) {
    final passages = widget.question.passages;
    // Same instruction as web desktop PanelHeader — never the short "فقرة 1".
    final title = passages.length > 1
        ? 'اقرأ الفقرات وأجب عن الأسئلة التالية'
        : 'اقرأ الفقرة وأجب عن الأسئلة التالية';

    return _PassagePanel(
      isMobileLayout: isMobileLayout,
      borderColor: _PassageTokens.passageBorder.withValues(alpha: 0.5),
      backgroundColor: _PassageTokens.passageBg,
      glowColor: _PassageTokens.passageGlow,
      header: _PanelHeader(
        badge: 'P',
        badgeColor: _PassageTokens.passageIcon,
        title: title,
        isMobileLayout: isMobileLayout,
      ),
      belowHeader: passages.length > 1
          ? _PassageTabs(
              count: passages.length,
              activeIndex: _activePassage,
              onChanged: (index) => setState(() => _activePassage = index),
              isMobileLayout: isMobileLayout,
            )
          : null,
      child: passages.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Text(
                  stripQuizHtml(widget.question.title),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.625,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: QuizHtmlText(
                html: passages[_activePassage.clamp(0, passages.length - 1)],
                textAlign: TextAlign.start,
                blockParagraphs: true,
                baseStyle: AppTypography.bodySm.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.625,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }
}

enum _PassageTab { questions, passage }

enum _PassageViewMode { list, question }

abstract final class _PassageTokens {
  static const questionsBg = Color(0xFF091C3F);
  static const questionsBorder = Color(0xFF0076F5);
  static const questionsIcon = Color(0xFF007BFF);
  static const questionsGlow = Color(0x66007BFF);

  static const passageBg = Color(0xFF250D38);
  static const passageBorder = Color(0xFF7B4CF0);
  static const passageIcon = Color(0xFF8B5CF6);
  static const passageGlow = Color(0x668B5CF6);

  static const tealBg = Color(0xFF082823);
  static const tealBorder = Color(0xFF12B09E);

  static const cardIconColors = [
    Color(0xFF007BFF),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
  ];
}

class _MobileTabs extends StatelessWidget {
  const _MobileTabs({
    required this.unansweredCount,
    required this.activeTab,
    required this.onTabChanged,
  });

  final int unansweredCount;
  final _PassageTab activeTab;
  final ValueChanged<_PassageTab> onTabChanged;

  @override
  Widget build(BuildContext context) {

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _PassageTokens.questionsBg,
          border: Border.all(
            color: _PassageTokens.questionsBorder,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                label: 'الأسئلة ($unansweredCount)',
                selected: activeTab == _PassageTab.questions,
                selectedFill: _PassageTokens.questionsIcon.withValues(alpha: 0.2),
                onTap: () => onTabChanged(_PassageTab.questions),
              ),
            ),
            Expanded(
              child: _TabButton(
                label: 'الفقرات',
                selected: activeTab == _PassageTab.passage,
                selectedFill: _PassageTokens.passageIcon.withValues(alpha: 0.2),
                onTap: () => onTabChanged(_PassageTab.passage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.selectedFill,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedFill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedFill : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                fontWeight: AppFonts.semibold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassagePanel extends StatelessWidget {
  const _PassagePanel({
    required this.isMobileLayout,
    required this.borderColor,
    required this.backgroundColor,
    required this.glowColor,
    required this.header,
    required this.child,
    this.belowHeader,
  });

  final bool isMobileLayout;
  final Color borderColor;
  final Color backgroundColor;
  final Color glowColor;
  final Widget header;
  final Widget? belowHeader;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.tailwindXl);

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isMobileLayout
              ? null
              : [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.4),
                    blurRadius: 5,
                  ),
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!isMobileLayout) const _GlassStrips(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                ?belowHeader,
                Expanded(child: child),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassStrips extends StatelessWidget {
  const _GlassStrips();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.5,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x0DFFFFFF),
                      Color(0x03FFFFFF),
                      Colors.transparent,
                    ],
                    stops: [0, 0.4, 1],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.25,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.isMobileLayout,
  });

  final String badge;
  final Color badgeColor;
  final String title;
  final bool isMobileLayout;

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMobileLayout
              ? const Color(0xF00A0E1C)
              : Colors.black.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              _LedBadge(
                label: badge,
                color: badgeColor,
                glow: !isMobileLayout,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: AppFonts.semibold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedBadge extends StatelessWidget {
  const _LedBadge({
    required this.label,
    required this.color,
    this.glow = true,
  });

  final String label;
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 10)]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PassageTabs extends StatelessWidget {
  const _PassageTabs({
    required this.count,
    required this.activeIndex,
    required this.onChanged,
    required this.isMobileLayout,
  });

  final int count;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final bool isMobileLayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Material(
              color: activeIndex == i
                  ? _PassageTokens.tealBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: activeIndex == i
                        ? Border.all(color: _PassageTokens.tealBorder)
                        : null,
                    boxShadow: !isMobileLayout && activeIndex == i
                        ? [
                            BoxShadow(
                              color: _PassageTokens.tealBorder
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'فقرة ${i + 1}',
                    style: AppTypography.badge.copyWith(
                      fontSize: 12,
                      color: activeIndex == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
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

class _BackHeader extends StatelessWidget {
  const _BackHeader({
    required this.onBack,
    required this.isMobileLayout,
  });

  final VoidCallback onBack;
  final bool isMobileLayout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMobileLayout
              ? const Color(0xF00A0E1C)
              : Colors.black.withValues(alpha: 0.3),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            label: Text(
              'العودة إلى القائمة',
              style: AppTypography.bodySm.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionsList extends StatelessWidget {
  const _QuestionsList({
    required this.questions,
    required this.onSelect,
    required this.isMobileLayout,
  });

  final List<UnitQuizQuestion> questions;
  final ValueChanged<int> onSelect;
  final bool isMobileLayout;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'تمت الإجابة على جميع الأسئلة',
          style: AppTypography.bodyMd.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final iconColor = _PassageTokens
            .cardIconColors[index % _PassageTokens.cardIconColors.length];
        final letter = String.fromCharCode(65 + index);
        final type = _passageTypeChip(question.type);
        final title = stripQuizHtml(question.title);
        // Web `dir="auto"`: punctuation follows the question language.
        final titleDirection = QuizHtmlText.detectTextDirection(title);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(index),
            hoverColor: Colors.white.withValues(alpha: 0.04),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _LedBadge(
                        label: letter,
                        color: iconColor,
                        glow: !isMobileLayout,
                      ),
                      const SizedBox(width: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type.icon,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type.label,
                              style: AppTypography.badge.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: AppFonts.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: titleDirection,
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      style: AppTypography.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.375,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

({IconData icon, String label}) _passageTypeChip(String type) {
  return switch (type) {
    'mcq' => (icon: Icons.check_box_outlined, label: 'اختيار من متعدد'),
    'essay' => (icon: Icons.notes_rounded, label: 'مقالي'),
    'fill-blank' => (icon: Icons.edit_outlined, label: 'اكمل'),
    'match' || 'matching' => (icon: Icons.link_rounded, label: 'توصيل'),
    're-order' || 're_order' || 'reorder' => (
        icon: Icons.format_list_numbered_rounded,
        label: 'ترتيب',
      ),
    _ => (icon: Icons.help_outline_rounded, label: 'مجهول'),
  };
}
