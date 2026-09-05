import 'package:flutter/material.dart';

import '../../../core/theme/app_durations.dart';
import '../../../core/widgets/quiz_html_text.dart';

/// Web `hover:scale-[1.02]` / card `hover:shadow-2xl` — also on touch.
class ReviewHoverHighlight extends StatefulWidget {
  const ReviewHoverHighlight({
    super.key,
    required this.builder,
    this.scale = 1,
  });

  final Widget Function(BuildContext context, bool highlighted) builder;
  final double scale;

  @override
  State<ReviewHoverHighlight> createState() => _ReviewHoverHighlightState();
}

class _ReviewHoverHighlightState extends State<ReviewHoverHighlight> {
  var _highlighted = false;

  void _setHighlighted(bool value) {
    if (_highlighted == value) return;
    setState(() => _highlighted = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHighlighted(true),
      onExit: (_) => _setHighlighted(false),
      child: Listener(
        onPointerDown: (_) => _setHighlighted(true),
        onPointerUp: (_) => _setHighlighted(false),
        onPointerCancel: (_) => _setHighlighted(false),
        child: AnimatedScale(
          scale: _highlighted && widget.scale != 1 ? widget.scale : 1,
          duration: AppDurations.hoverScale,
          curve: Curves.easeOut,
          child: widget.builder(context, _highlighted),
        ),
      ),
    );
  }
}

/// Mixed Arabic+English as one bidi run — matches web `<p dir={getTextDirection}>`.
///
/// Do not split into per-word widgets: that isolates each word from the Unicode
/// bidi algorithm and reverses phrases like `تيار الهواء او الماء`.
class ReviewFlowingText extends StatelessWidget {
  const ReviewFlowingText({
    super.key,
    required this.text,
    required this.style,
    this.leading,
  });

  final String text;
  final TextStyle style;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final plain = QuizHtmlText.plainText(text);
    final direction = QuizHtmlText.detectTextDirection(plain);
    final align =
        direction == TextDirection.rtl ? TextAlign.right : TextAlign.left;

    final textWidget = Directionality(
      textDirection: direction,
      child: Text(
        plain,
        style: style,
        textAlign: align,
        softWrap: true,
      ),
    );

    if (leading == null) return textWidget;

    return Directionality(
      textDirection: direction,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading!,
          const SizedBox(width: 8),
          Expanded(child: textWidget),
        ],
      ),
    );
  }
}
