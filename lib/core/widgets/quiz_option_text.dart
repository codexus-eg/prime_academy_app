import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'quiz_html_text.dart';

/// Centered option label used by exam / luck / classification answer cards.
///
/// Rules:
/// - Never break a word mid-character — wrap only on whitespace.
/// - Long single words scale down via [FittedBox] + [softWrap: false].
/// - Multi-word answers shrink [baseStyle] to fit the longest token, then wrap.
class QuizOptionText extends StatelessWidget {
  const QuizOptionText({
    super.key,
    required this.html,
    required this.baseStyle,
    this.textAlign = TextAlign.center,
    this.minFontSize = 9,
  });

  final String html;
  final TextStyle baseStyle;
  final TextAlign textAlign;

  /// Floor for auto-scaling multi-word blocks.
  final double minFontSize;

  @override
  Widget build(BuildContext context) {
    final sanitized = QuizHtmlText.sanitizeHtml(html);
    final plain = QuizHtmlText.plainText(sanitized);
    if (plain.isEmpty) return const SizedBox.shrink();

    final direction = QuizHtmlText.detectTextDirection(plain);
    final hasRichMarkup = _hasRichMarkup(sanitized);
    final singleWord = !_containsWhitespace(plain);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _resolveMaxWidth(constraints, context);
        final maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : double.infinity;

        if (hasRichMarkup) {
          final style = scaleOptionStyle(
            sample: plain,
            style: baseStyle,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            textAlign: textAlign,
            textDirection: direction,
            minFontSize: minFontSize,
          );
          return _wrap(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            direction: direction,
            child: QuizHtmlText(
              html: sanitized,
              baseStyle: style,
              textAlign: textAlign,
            ),
          );
        }

        if (singleWord) {
          // FittedBox + softWrap:false guarantees the whole token stays on one
          // line (matches web MCQ cells — no "testtesttes" + "t" splits).
          return _wrap(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            direction: direction,
            child: Text(
              plain,
              style: baseStyle,
              textAlign: textAlign,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          );
        }

        final style = scaleOptionStyle(
          sample: plain,
          style: baseStyle,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          textAlign: textAlign,
          textDirection: direction,
          minFontSize: minFontSize,
        );

        return _wrap(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          direction: direction,
          child: Text(
            plain,
            style: style,
            textAlign: textAlign,
            softWrap: true,
            overflow: TextOverflow.fade,
          ),
        );
      },
    );
  }

  Widget _wrap({
    required double maxWidth,
    required double maxHeight,
    required TextDirection direction,
    required Widget child,
  }) {
    return Align(
      alignment: Alignment.center,
      child: Directionality(
        textDirection: direction,
        child: SizedBox(
          width: maxWidth,
          height: maxHeight.isFinite ? maxHeight : null,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: _alignmentFor(textAlign),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  static Alignment _alignmentFor(TextAlign align) {
    return switch (align) {
      TextAlign.left || TextAlign.start => Alignment.centerLeft,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.center,
    };
  }

  /// Never treat the full screen as the cell width — that skips scaling and
  /// causes mid-word wraps inside narrow MCQ squares.
  static double _resolveMaxWidth(BoxConstraints constraints, BuildContext context) {
    if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      return constraints.maxWidth;
    }
    final screen = MediaQuery.sizeOf(context).width;
    // Typical 2-col phone MCQ cell ≈ (screen - gutters - gap) / 2.
    return math.max(72, (screen - 80) / 2);
  }

  static bool _containsWhitespace(String text) =>
      RegExp(r'\s').hasMatch(text);

  bool _hasRichMarkup(String sanitized) {
    return RegExp(
      r'<\s*(strong|b|em|i|u|mark)\b',
      caseSensitive: false,
    ).hasMatch(sanitized);
  }

  /// Public for unit tests — picks a font size where the longest token fits
  /// in [maxWidth] and the full block fits in [maxHeight].
  static TextStyle scaleOptionStyle({
    required String sample,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextAlign textAlign,
    required TextDirection textDirection,
    double minFontSize = 9,
  }) {
    final maxFont = style.fontSize ?? 16;
    if (maxWidth <= 0 || sample.isEmpty) return style;

    final longest = _longestToken(sample);
    var lo = minFontSize;
    var hi = maxFont;
    var best = minFontSize;

    for (var i = 0; i < 12; i++) {
      final mid = (lo + hi) / 2;
      final candidate = style.copyWith(fontSize: mid, height: style.height ?? 1.25);
      if (_fits(
        sample: sample,
        longest: longest,
        style: candidate,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        textAlign: textAlign,
        textDirection: textDirection,
      )) {
        best = mid;
        lo = mid;
      } else {
        hi = mid;
      }
    }

    var fontSize = best;
    final minStyle = style.copyWith(fontSize: fontSize, height: style.height ?? 1.25);
    final wordWidth = _measureWidth(
      longest,
      minStyle,
      textDirection: textDirection,
      maxWidth: maxWidth,
      maxLines: 1,
    );
    if (wordWidth > maxWidth && wordWidth > 0) {
      fontSize = math.max(6, fontSize * (maxWidth / wordWidth) * 0.95);
    }

    if ((fontSize - maxFont).abs() < 0.15) return style;
    return style.copyWith(fontSize: fontSize);
  }

  static bool _fits({
    required String sample,
    required String longest,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
    required TextAlign textAlign,
    required TextDirection textDirection,
  }) {
    final wordWidth = _measureWidth(
      longest,
      style,
      textDirection: textDirection,
      maxWidth: maxWidth,
      maxLines: 1,
    );
    if (wordWidth > maxWidth * 0.95) return false;

    if (!maxHeight.isFinite || maxHeight <= 0) return true;

    final block = TextPainter(
      text: TextSpan(text: sample, style: style),
      textDirection: textDirection,
      textAlign: textAlign,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return block.height <= maxHeight + 0.5;
  }

  static double _measureWidth(
    String text,
    TextStyle style, {
    required TextDirection textDirection,
    required double maxWidth,
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: maxLines,
    );
    // Intrinsic width for single-line tokens — layout(maxWidth:) can report a
    // clipped width even when the word still overflows onto a second line.
    if (maxLines == 1) {
      painter.layout();
    } else {
      painter.layout(maxWidth: maxWidth);
    }
    return painter.width;
  }

  static String _longestToken(String sample) {
    final tokens = sample
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return sample;
    return tokens.reduce((a, b) => a.length >= b.length ? a : b);
  }
}
