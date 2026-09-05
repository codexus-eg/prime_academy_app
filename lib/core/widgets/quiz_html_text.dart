import 'package:flutter/material.dart';

class QuizHtmlText extends StatelessWidget {
  const QuizHtmlText({
    super.key,
    required this.html,
    this.baseStyle,
    this.textAlign = TextAlign.center,
    this.blockParagraphs = false,
  });

  final String html;
  final TextStyle? baseStyle;
  final TextAlign textAlign;

  /// When true, each HTML `<p>` (or blank-line) becomes its own block with
  /// web-like `1em` gap — used for reading passages.
  final bool blockParagraphs;

  static const _allowedTags = {
    'p',
    'strong',
    'b',
    'mark',
    'br',
    'span',
    'em',
    'i',
    'u',
    'div',
  };

  static final _tagPattern = RegExp(
    r'<(/?)(p|strong|b|mark|br|span|em|i|u|div)([^>]*)>|([^<]+)',
    caseSensitive: false,
  );

  /// Any HTML tag (used to strip unsupported ones like `<a>`).
  static final _anyTagPattern = RegExp(
    r'</?([a-zA-Z][\w:-]*)\b[^>]*>',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final normalized = sanitizeHtml(html);
    final plain = plainText(normalized);
    final direction = _detectDirection(plain);
    final style = baseStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.6,
        );

    if (blockParagraphs) {
      return Directionality(
        textDirection: direction,
        child: _buildParagraphBlocks(normalized, style),
      );
    }

    var children = _parse(normalized, style);
    if (_hasHtmlArtifacts(children)) {
      children = [TextSpan(text: plain, style: style)];
    }

    return Directionality(
      textDirection: direction,
      child: RichText(
        textAlign: textAlign,
        text: TextSpan(style: style, children: children),
      ),
    );
  }

  Widget _buildParagraphBlocks(String html, TextStyle style) {
    final blocks = splitParagraphs(html);
    final gap = style.fontSize ?? 14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          RichText(
            textAlign: textAlign,
            text: TextSpan(
              style: style,
              children: _spansForBlock(blocks[i], style),
            ),
          ),
        ],
      ],
    );
  }

  List<InlineSpan> _spansForBlock(String block, TextStyle style) {
    var children = _parse(block, style);
    if (_hasHtmlArtifacts(children)) {
      children = [TextSpan(text: plainText(block), style: style)];
    }
    return children;
  }

  /// Splits HTML into visual paragraphs, matching browser `<p>` / blank lines.
  static List<String> splitParagraphs(String html) {
    final normalized = sanitizeHtml(html);
    if (normalized.isEmpty) return const [];

    final pRe = RegExp(
      r'<p\b[^>]*>(.*?)</p>',
      caseSensitive: false,
      dotAll: true,
    );
    final matches = pRe.allMatches(normalized).toList();
    if (matches.isNotEmpty) {
      final blocks = <String>[];
      var cursor = 0;
      for (final match in matches) {
        _addIfContent(blocks, normalized.substring(cursor, match.start));
        _addIfContent(blocks, match.group(1) ?? '');
        cursor = match.end;
      }
      _addIfContent(blocks, normalized.substring(cursor));
      return blocks.isEmpty ? [normalized] : blocks;
    }

    final doubleBr = RegExp(
      r'(?:<br\s*/?\>\s*){2,}',
      caseSensitive: false,
    );
    if (doubleBr.hasMatch(normalized)) {
      return normalized
          .split(doubleBr)
          .map((s) => s.trim())
          .where((s) => _stripTags(s).isNotEmpty)
          .toList();
    }

    final withBreaks = normalized.replaceAll(
      RegExp(r'<br\s*/?\>', caseSensitive: false),
      '\n',
    );
    if (RegExp(r'\n\s*\n').hasMatch(withBreaks)) {
      return withBreaks
          .split(RegExp(r'\n\s*\n'))
          .map((s) => s.trim())
          .where((s) => _stripTags(s).isNotEmpty)
          .toList();
    }

    return [normalized];
  }

  static void _addIfContent(List<String> blocks, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    if (_stripTags(trimmed).isEmpty) return;
    blocks.add(trimmed);
  }

  static TextDirection detectTextDirection(String html) =>
      _detectDirection(plainText(html));

  /// First Strong Isolate + Pop Directional Isolate.
  /// Keeps mixed Arabic/English segments from reversing each other.
  static String bidiIsolate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    return '\u2068$trimmed\u2069';
  }

  /// Visible text only — never raw HTML tags/attributes.
  static String plainText(String html) =>
      _decodeEntities(_stripTags(sanitizeHtml(html)))
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  /// Keep supported formatting tags; drop everything else (e.g. `<a>`) while
  /// preserving inner text so quiz prompts never show source code.
  static String sanitizeHtml(String input) {
    var s = _normalizeHtml(input);

    // <a href="...">label</a> → label
    s = s.replaceAllMapped(
      RegExp(r'<a\b[^>]*>(.*?)</a>', caseSensitive: false, dotAll: true),
      (match) => match.group(1) ?? '',
    );

    // Strip any remaining / unknown tags; keep allowlisted markup intact.
    s = s.replaceAllMapped(_anyTagPattern, (match) {
      final tag = match.group(1)?.toLowerCase() ?? '';
      if (_allowedTags.contains(tag)) return match.group(0)!;
      return '';
    });

    return s;
  }

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
          text.contains('href=') ||
          text.contains('target=') ||
          text.contains('rel=') ||
          text.contains('noopener') ||
          text.contains('<') ||
          text.contains('</') ||
          RegExp(r'^/?p\s', caseSensitive: false).hasMatch(text) ||
          RegExp(r'^/?a\s', caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  static String _stripTags(String input) =>
      input.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Matches web `getTextDirection`: language of the *input* is the first
  /// strong letter after stripping HTML — not a majority count of letters.
  /// Mixed Arabic+English prompts that start in Arabic stay RTL (`سؤال`).
  static TextDirection _detectDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    for (final rune in text.runes) {
      if (_isRtl(rune)) return TextDirection.rtl;
      if (_isLtr(rune)) return TextDirection.ltr;
    }
    return TextDirection.rtl;
  }

  /// Web `RTL_CHAR_REGEX`: `\u0591-\u07FF`, `\u200F`, `\u202B`, `\u202E`,
  /// `\uFB1D-\uFDFD`, `\uFE70-\uFEFC`.
  static bool _isRtl(int codeUnit) =>
      (codeUnit >= 0x0591 && codeUnit <= 0x07FF) ||
      codeUnit == 0x200F ||
      codeUnit == 0x202B ||
      codeUnit == 0x202E ||
      (codeUnit >= 0xFB1D && codeUnit <= 0xFDFD) ||
      (codeUnit >= 0xFE70 && codeUnit <= 0xFEFC);

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
          // Leftover markup between matches → never paint raw tags.
          if (_looksLikeRawMarkup(text)) {
            final cleaned = _decodeEntities(_stripTags(text));
            if (cleaned.isNotEmpty) {
              spans.add(TextSpan(text: cleaned, style: stack.last));
            }
          } else {
            spans.add(TextSpan(text: _decodeEntities(text), style: stack.last));
          }
        }
      }

      final closing = match.group(1) == '/';
      final tag = match.group(2)?.toLowerCase();

      if (tag == null) {
        final text = match.group(4);
        if (text != null && text.isNotEmpty) {
          if (_looksLikeRawMarkup(text)) {
            final cleaned = _decodeEntities(_stripTags(text));
            if (cleaned.isNotEmpty) {
              spans.add(TextSpan(text: cleaned, style: stack.last));
            }
          } else {
            spans.add(TextSpan(text: _decodeEntities(text), style: stack.last));
          }
        }
      } else if (closing) {
        if (stack.length > 1) stack.removeLast();
      } else if (tag == 'br') {
        spans.add(const TextSpan(text: '\n'));
      } else if (tag == 'p' || tag == 'div') {
        if (spans.isNotEmpty && spans.last is TextSpan) {
          final lastSpan = spans.last as TextSpan;
          if (lastSpan.text != null && !lastSpan.text!.endsWith('\n')) {
            spans.add(const TextSpan(text: '\n\n'));
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
        if (_looksLikeRawMarkup(tail)) {
          final cleaned = _decodeEntities(_stripTags(tail));
          if (cleaned.isNotEmpty) {
            spans.add(TextSpan(text: cleaned, style: stack.last));
          }
        } else {
          spans.add(TextSpan(text: _decodeEntities(tail), style: stack.last));
        }
      }
    }

    if (spans.isEmpty) {
      return [TextSpan(text: plainText(source), style: base)];
    }
    return spans;
  }

  static bool _looksLikeRawMarkup(String text) =>
      text.contains('<') ||
      text.contains('href=') ||
      text.contains('target=') ||
      text.contains('style=');

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

  static String _decodeEntities(String text) => text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
        final code = int.tryParse(m.group(1)!);
        if (code == null) return m.group(0)!;
        return String.fromCharCode(code);
      });
}
