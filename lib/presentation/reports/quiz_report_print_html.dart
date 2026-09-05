import 'package:flutter/widgets.dart' show TextDirection;
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/config/cdn_config.dart';
import '../../core/widgets/quiz_html_text.dart';
import '../../data/quizzes/answered_question_display.dart';
import '../../data/quizzes/answered_question_models.dart';

abstract final class QuizReportPrintHtml {

  static String get _logoUrl =>
      '${CdnConfig.productionStaticBaseUrl}prime_academy.svg';

  static String get _fontSemiLightUrl =>
      'https://primeacademy.education/assets/fonts/Bahij_TheSansArabic-SemiLight.woff2';

  static String get _fontBoldUrl =>
      'https://primeacademy.education/assets/fonts/Bahij_TheSansArabic-Bold.woff2';

  static String get styles => '''
    @font-face {
      font-family: "bahij";
      src: url("$_fontSemiLightUrl") format("woff2");
      font-weight: 300;
      font-style: normal;
      font-display: swap;
    }
    @font-face {
      font-family: "bahij";
      src: url("$_fontBoldUrl") format("woff2");
      font-weight: 700;
      font-style: normal;
      font-display: swap;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "bahij", serif;
      font-weight: 300;
      direction: ltr;
      color: #111827;
      background: #fff;
    }
    .report-root {
      max-width: 72rem;
      margin: 0 auto;
      background: #fff;
      padding: 1.5rem;
      direction: ltr;
      font-family: "bahij", serif;
    }
    .header-card {
      border: 2px solid #e5e7eb;
      border-radius: 0.5rem;
      padding: 2rem;
      margin-bottom: 1.5rem;
    }
    .header-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 1.5rem;
    }
    .logo {
      width: 10rem;
      height: auto;
      object-fit: contain;
      margin-bottom: 1rem;
    }
    .meta-row {
      display: flex;
      gap: 0.75rem;
      align-items: center;
      margin-top: 0.75rem;
    }
    .meta-label {
      font-weight: 700;
      color: #1f2937;
      width: 7rem;
      font-size: 0.875rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .meta-value { color: #374151; }
    .meta-value.strong { font-weight: 500; }
    .accuracy-box {
      text-align: center;
      border-radius: 0.75rem;
      padding: 1.5rem;
      box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
      min-width: 8.75rem;
    }
    .accuracy-label {
      font-size: 0.75rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      opacity: 0.9;
    }
    .accuracy-value {
      font-size: 3rem;
      font-weight: 900;
      color: #000;
      margin: 0;
      line-height: 1.1;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 1.5rem;
      margin-bottom: 1.5rem;
    }
    .stat-card {
      border: 2px solid #d1d5db;
      border-radius: 0.5rem;
      padding: 1.5rem;
      text-align: center;
      background: #fff;
      box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    }
    .stat-card.correct {
      border-color: #bbf7d0;
      background: #f0fdf4;
    }
    .stat-card.wrong {
      border-color: #fecaca;
      background: #fef2f2;
    }
    .stat-label {
      color: #6b7280;
      font-size: 0.75rem;
      margin-bottom: 0.75rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-weight: 600;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
    }
    .stat-card.correct .stat-label { color: #4b5563; }
    .stat-card.wrong .stat-label { color: #4b5563; }
    .stat-value {
      font-size: 3rem;
      font-weight: 900;
      color: #1f2937;
      margin: 0;
      line-height: 1.1;
    }
    .stat-card.correct .stat-value { color: #15803d; }
    .stat-card.wrong .stat-value { color: #b91c1c; }
    .icon-ok { color: #16a34a; }
    .icon-bad { color: #dc2626; }
    .table-wrap {
      border: 2px solid #1f2937;
      border-radius: 0.5rem;
      overflow: hidden;
      box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    }
    table {
      width: 100%;
      border-collapse: collapse;
    }
    thead tr {
      background: linear-gradient(to right, #1f2937, #374151);
      color: #fff;
      border-bottom: 2px solid #111827;
    }
    th {
      padding: 1rem 1.25rem;
      font-weight: 700;
      font-size: 0.875rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      text-align: left;
    }
    th.center, td.center { text-align: center; }
    th.num { width: 5rem; }
    th.pts { width: 7rem; }
    th.status { width: 8rem; }
    tbody tr {
      border-bottom: 1px solid #e5e7eb;
      page-break-inside: avoid;
    }
    tbody tr.row-ok { background: rgba(240, 253, 244, 0.3); }
    tbody tr.row-alt { background: #f9fafb; }
    tbody tr.row-plain { background: #fff; }
    td {
      padding: 1rem 1.25rem;
      vertical-align: top;
      color: #374151;
      text-align: left;
    }
    td.num-cell {
      color: #1f2937;
      font-weight: 600;
    }
    .q-title {
      font-weight: 500;
      color: #111827;
      line-height: 1.625;
      margin-bottom: 0.75rem;
    }
    .student-box {
      font-size: 0.875rem;
      padding-top: 0.75rem;
      border-top: 1px solid #e5e7eb;
      background: rgba(249, 250, 251, 0.5);
      padding: 0.75rem;
      border-radius: 0.25rem;
    }
    .student-row { display: flex; gap: 0.5rem; }
    .student-label {
      font-weight: 700;
      color: #374151;
      min-width: 120px;
    }
    .student-ok { color: #15803d; font-weight: 500; }
    .student-plain { color: #1f2937; }
    .pts-pill {
      display: inline-block;
      background: #dbeafe;
      color: #1e40af;
      font-weight: 700;
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.875rem;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-weight: 600;
      font-size: 0.875rem;
    }
    .badge-ok { background: #dcfce7; color: #15803d; }
    .badge-bad { background: #fee2e2; color: #b91c1c; }
    .correct-hint {
      font-size: 0.75rem;
      color: #4b5563;
      margin-top: 0.5rem;
    }
    .correct-hint strong { font-weight: 600; }
    .correct-hint .ans { color: #15803d; }
    .footer-card {
      margin-top: 1.5rem;
      padding: 1.5rem;
      border: 2px solid #1f2937;
      border-radius: 0.5rem;
      background: linear-gradient(to bottom right, #f3f4f6, #f9fafb);
      box-shadow: 0 1px 2px rgba(0,0,0,0.05);
      text-align: center;
    }
    .footer-label {
      font-weight: 700;
      color: #1f2937;
      font-size: 0.875rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-right: 1rem;
    }
    .footer-score {
      font-size: 1.5rem;
      font-weight: 900;
      color: #1f2937;
    }
  ''';

  static String build({
    required QuizAttemptReview review,
    required double accuracy,
    required int totalQuestions,
  }) {
    final dateLabel = DateFormat(
      'E, MMM d, y, h:mm a',
      'en_US',
    ).format(DateTime.now());
    final rows = _flattenQuestions(review.answeredQuestions);
    final buffer = StringBuffer();

    buffer.writeln('<div class="report-root">');

    buffer
      ..writeln('<div class="header-card"><div class="header-row">')
      ..writeln('<div>')
      ..writeln(
        '<img class="logo" src="${_escape(_logoUrl)}" alt="شعار برايم أكاديمي" />',
      )
      ..writeln(
        '<div class="meta-row"><span class="meta-label">التاريخ</span>'
        '<span class="meta-value">: ${_escape(dateLabel)}</span></div>',
      )
      ..writeln(
        '<div class="meta-row"><span class="meta-label">الطالب</span>'
        '<span class="meta-value strong">: ${_escape(review.studentName ?? "-")}</span></div>',
      )
      ..writeln('</div>')
      ..writeln(
        '<div class="accuracy-box">'
        '<p class="accuracy-label">الدقة</p>'
        '<p class="accuracy-value">${accuracy.toStringAsFixed(2)}%</p>'
        '</div>',
      )
      ..writeln('</div></div>');

    buffer
      ..writeln('<div class="stats-grid">')
      ..writeln(
        '<div class="stat-card">'
        '<p class="stat-label">إجمالي الأسئلة</p>'
        '<p class="stat-value">$totalQuestions</p>'
        '</div>',
      )
      ..writeln(
        '<div class="stat-card correct">'
        '<p class="stat-label"><span class="icon-ok">✓</span> صحيح</p>'
        '<p class="stat-value">${review.correctCount ?? 0}</p>'
        '</div>',
      )
      ..writeln(
        '<div class="stat-card wrong">'
        '<p class="stat-label"><span class="icon-bad">✕</span> خطأ</p>'
        '<p class="stat-value">${review.inCorrectCount ?? 0}</p>'
        '</div>',
      )
      ..writeln('</div>');

    buffer
      ..writeln('<div class="table-wrap"><table><thead><tr>')
      ..writeln('<th class="num">الرقم</th>')
      ..writeln('<th>السؤال والإجابة</th>')
      ..writeln('<th class="center pts">النقاط</th>')
      ..writeln('<th class="center status">الحالة</th>')
      ..writeln('</tr></thead><tbody>');

    for (var i = 0; i < rows.length; i++) {
      final item = rows[i];
      final q = item.question;
      final isCorrect = q.isCorrect;
      final studentRaw = q.studentAnswerLines.join(', ');
      final student = studentRaw.isEmpty ? 'لم تتم الإجابة' : studentRaw;
      final correct = q.correctAnswerLines.join(', ');
      final title = _questionTitle(q.plainTitle);
      final rowClass = isCorrect
          ? 'row-ok'
          : (i.isEven ? 'row-plain' : 'row-alt');

      buffer
        ..writeln('<tr class="$rowClass">')
        ..writeln('<td class="num-cell">${_escape(item.number)}</td>')
        ..writeln('<td>')
        ..writeln(
          '<div class="q-title" dir="${_dirOf(title)}">${_escape(title)}</div>',
        )
        ..writeln('<div class="student-box"><div class="student-row">')
        ..writeln('<span class="student-label">إجابة الطالب:</span>')
        ..writeln(
          '<span class="${isCorrect ? "student-ok" : "student-plain"}" dir="${_dirOf(student)}">'
          '${_escape(student)}</span>',
        )
        ..writeln('</div></div></td>')
        ..writeln(
          '<td class="center"><span class="pts-pill">${q.awardedPoints}</span></td>',
        )
        ..writeln('<td class="center">');

      if (isCorrect) {
        buffer.writeln(
          '<div class="badge badge-ok"><span class="icon-ok">✓</span> صحيح</div>',
        );
      } else {
        buffer
          ..writeln(
            '<div class="badge badge-bad"><span class="icon-bad">✕</span> خطأ</div>',
          )
          ..writeln(
            '<div class="correct-hint"><strong>الإجابة الصحيحة: </strong>'
            '<span class="ans" dir="${_dirOf(correct)}">${_escape(correct.isEmpty ? "-" : correct)}</span></div>',
          );
      }

      buffer.writeln('</td></tr>');
    }

    buffer.writeln('</tbody></table></div>');

    buffer
      ..writeln('<div class="footer-card">')
      ..writeln(
        '<span class="footer-label">الدرجة الكلية:</span>'
        '<span class="footer-score">${review.pointsAwarded ?? 0}/ ${review.score ?? 0}</span>',
      )
      ..writeln('</div>');

    buffer.writeln('</div>');
    return buffer.toString();
  }

  static int countQuestions(List<AnsweredQuizQuestion> questions) {
    return _flattenQuestions(questions).length;
  }

  static String _questionTitle(String plain) {
    final trimmed = plain.trim();
    if (trimmed.isEmpty) return '';
    final sliced =
        trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
    return '$sliced...';
  }

  static List<_PrintRow> _flattenQuestions(
    List<AnsweredQuizQuestion> questions,
  ) {
    final rows = <_PrintRow>[];
    var index = 0;
    for (final q in questions) {
      index++;
      if (q.isPassage && q.childQuestions.isNotEmpty) {
        for (var i = 0; i < q.childQuestions.length; i++) {
          rows.add(_PrintRow('$index.${i + 1}', q.childQuestions[i]));
        }
      } else if (!q.isPassage) {
        rows.add(_PrintRow('$index', q));
      }
    }
    return rows;
  }

  static String _dirOf(String text) {
    return QuizHtmlText.detectTextDirection(text) == TextDirection.rtl
        ? 'rtl'
        : 'ltr';
  }

  static String _escape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}

class _PrintRow {
  const _PrintRow(this.number, this.question);

  final String number;
  final AnsweredQuizQuestion question;
}
