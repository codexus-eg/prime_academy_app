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

/// Keeps each word on one line and lets later lines use the full width,
/// including the space under [leading] (web: wrap below the status icon).
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
    final words =
        plain.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Directionality(
          textDirection: direction,
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ?leading,
              for (final word in words)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      word,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: style,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
