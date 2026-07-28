import 'package:flutter/material.dart';

class QuizHtmlText extends StatelessWidget {
  const QuizHtmlText({
    super.key,
    required this.html,
    this.baseStyle,
    this.textAlign = TextAlign.center,
  });

  final String html;
  final TextStyle? baseStyle;
  final TextAlign textAlign;

  static final _tagPattern = RegExp(
    r'<(/?)(p|strong|b|mark|br|span|em|i|u|div)([^>]*)>|([^<]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeHtml(html);
    final plain = _stripTags(normalized);
    final direction = _detectDirection(plain);
    final style = baseStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.6,
        );

    var children = _parse(normalized, style);
    if (_hasHtmlArtifacts(children)) {
      children = [TextSpan(text: _decodeEntities(plain), style: style)];
    }

    return Directionality(
      textDirection: direction,
      child: RichText(
        textAlign: textAlign,
        text: TextSpan(style: style, children: children),
      ),
    );
  }

  static TextDirection detectTextDirection(String html) =>
      _detectDirection(_stripTags(html));

  static String plainText(String html) => _stripTags(html);

  static String _normalizeHtml(String input) {
    var s = input.trim();
    if (RegExp(r'^(p|div|span)(\s|>)', caseSensitive: false).hasMatch(s)) {
      s = '<$s';
    }
    return s;
  }

  static bool _hasHtmlArtifacts(List<InlineSpan> spans) {
    for (final span in spans) {
      if (span is! TextSpan || span.text == null) continue;
      final text = span.text!;
      if (text.contains('style="') ||
          text.contains('text-align') ||
          RegExp(r'^/?p\s', caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  static String _stripTags(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static TextDirection _detectDirection(String text) {
    var rtl = 0;
    var ltr = 0;
    for (final rune in text.runes) {
      if (_isRtl(rune)) {
        rtl++;
      } else if (_isLtr(rune)) {
        ltr++;
      }
    }
    if (rtl == 0 && ltr == 0) return TextDirection.ltr;
    return rtl >= ltr ? TextDirection.rtl : TextDirection.ltr;
  }

  static bool _isRtl(int codeUnit) =>
      (codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
      (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
      (codeUnit >= 0x08A0 && codeUnit <= 0x08FF) ||
      (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
      (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF);

  static bool _isLtr(int codeUnit) =>
      (codeUnit >= 0x0041 && codeUnit <= 0x005A) ||
      (codeUnit >= 0x0061 && codeUnit <= 0x007A);

  List<InlineSpan> _parse(String source, TextStyle base) {
    final spans = <InlineSpan>[];
    final stack = <TextStyle>[base];
    var last = 0;

    for (final match in _tagPattern.allMatches(source)) {
      if (match.start > last) {
        final text = source.substring(last, match.start);
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: _decodeEntities(text), style: stack.last));
        }
      }

      final closing = match.group(1) == '/';
      final tag = match.group(2)?.toLowerCase();

      if (tag == null) {
        final text = match.group(4);
        if (text != null && text.isNotEmpty) {
          spans.add(TextSpan(text: _decodeEntities(text), style: stack.last));
        }
      } else if (closing) {
        if (stack.length > 1) stack.removeLast();
      } else if (tag == 'br') {
        spans.add(const TextSpan(text: '\n'));
      } else if (tag == 'p' || tag == 'div') {
        if (spans.isNotEmpty && spans.last is TextSpan) {
          final last = spans.last as TextSpan;
          if (last.text != null && !last.text!.endsWith('\n')) {
            spans.add(const TextSpan(text: '\n'));
          }
        }
        stack.add(stack.last);
      } else {
        stack.add(_styleForTag(tag, match.group(3) ?? '', stack.last));
      }

      last = match.end;
    }

    if (last < source.length) {
      final tail = source.substring(last);
      if (tail.isNotEmpty) {
        spans.add(TextSpan(text: _decodeEntities(tail), style: stack.last));
      }
    }

    if (spans.isEmpty) {
      return [TextSpan(text: _decodeEntities(_stripTags(source)), style: base)];
    }
    return spans;
  }

  TextStyle _styleForTag(String tag, String attrs, TextStyle parent) {
    return switch (tag) {
      'strong' || 'b' => parent.copyWith(fontWeight: FontWeight.bold),
      'em' || 'i' => parent.copyWith(fontStyle: FontStyle.italic),
      'u' => parent.copyWith(decoration: TextDecoration.underline),
      'mark' => parent.copyWith(
          backgroundColor: _parseMarkColor(attrs) ?? const Color(0xFF06B6D4),
          color: parent.color,
        ),
      _ => parent,
    };
  }

  Color? _parseMarkColor(String attrs) {
    final hex = RegExp(r'#([0-9a-fA-F]{6})').firstMatch(attrs)?.group(1);
    if (hex == null) return null;
    return Color(int.parse('FF$hex', radix: 16));
  }

  String _decodeEntities(String text) => text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}
