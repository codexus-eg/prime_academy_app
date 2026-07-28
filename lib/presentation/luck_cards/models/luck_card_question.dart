import '../../../core/theme/app_quiz_palette.dart';

class LuckAnswerOption {
  const LuckAnswerOption({
    required this.text,
    required this.palette,
  });

  final String text;
  final LuckAnswerPaletteSlot palette;
}

class LuckCardQuestion {
  const LuckCardQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.points = 10,
  });

  final String prompt;
  final List<LuckAnswerOption> options;
  final int correctIndex;
  final int points;
}

enum LuckCardPickResult { unopened, correct, wrong }
