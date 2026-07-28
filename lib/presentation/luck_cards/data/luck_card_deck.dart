import '../../../core/theme/app_quiz_palette.dart';
import '../models/luck_card_question.dart';

abstract final class LuckCardDeck {
  static const questions = [
    LuckCardQuestion(
      prompt:
          'The two countries have agreed to engage in cultural exchanges in an effort to better understanding and reduce ...... between them.',
      correctIndex: 1,
      options: [
        LuckAnswerOption(text: 'recuperate', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'borders', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'smuggle', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'overtake', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
    LuckCardQuestion(
      prompt:
          'If we had more time, we ------- many other places in the city.',
      correctIndex: 1,
      options: [
        LuckAnswerOption(text: 'will visit', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'would visit', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'can visit', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(
          text: 'would have visited',
          palette: LuckAnswerPaletteSlot.orange,
        ),
      ],
    ),
    LuckCardQuestion(
      prompt: 'She said that she ------- to the party last night.',
      correctIndex: 2,
      options: [
        LuckAnswerOption(text: 'goes', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'will go', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'went', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'had gone', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
    LuckCardQuestion(
      prompt: 'The scientist made a remarkable ------- in cancer research.',
      correctIndex: 0,
      options: [
        LuckAnswerOption(text: 'breakthrough', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'breakdown', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'outbreak', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'takeover', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
    LuckCardQuestion(
      prompt: 'You should always ------- your seat belt before driving.',
      correctIndex: 0,
      options: [
        LuckAnswerOption(text: 'fasten', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'loosen', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'ignore', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'remove', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
    LuckCardQuestion(
      prompt: 'The government plans to ------- taxes on luxury goods.',
      correctIndex: 1,
      options: [
        LuckAnswerOption(text: 'lower', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'raise', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'abolish', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'ignore', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
    LuckCardQuestion(
      prompt: 'His speech was so ------- that everyone applauded.',
      correctIndex: 2,
      options: [
        LuckAnswerOption(text: 'boring', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'confusing', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'inspiring', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'lengthy', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
    LuckCardQuestion(
      prompt: 'The company decided to ------- its operations overseas.',
      correctIndex: 3,
      options: [
        LuckAnswerOption(text: 'limit', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'reduce', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'pause', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'expand', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
    LuckCardQuestion(
      prompt: 'Students must ------- all assignments before the deadline.',
      correctIndex: 0,
      options: [
        LuckAnswerOption(text: 'submit', palette: LuckAnswerPaletteSlot.pink),
        LuckAnswerOption(text: 'delay', palette: LuckAnswerPaletteSlot.blue),
        LuckAnswerOption(text: 'skip', palette: LuckAnswerPaletteSlot.violet),
        LuckAnswerOption(text: 'forget', palette: LuckAnswerPaletteSlot.orange),
      ],
    ),
  ];
}
