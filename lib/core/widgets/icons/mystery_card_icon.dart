import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MysteryCardIcon extends StatelessWidget {
  const MysteryCardIcon({
    super.key,
    this.size = 30,
    this.cardColor = const Color(0xCCFFFFFF),
    this.symbolColor = const Color(0xE6000000),
  });

  final double size;
  final Color cardColor;
  final Color symbolColor;

  @override
  Widget build(BuildContext context) {
    final card = _color(cardColor);
    final symbol = _color(symbolColor);
    return SvgPicture.string(
      '''
<svg viewBox="0 0 680 680" xmlns="http://www.w3.org/2000/svg">
  <g transform="rotate(-12, 340, 370)">
    <rect x="155" y="185" width="245" height="330" rx="20" fill="$card"/>
    <rect x="155" y="185" width="245" height="330" rx="20" fill="none" stroke="$symbol" stroke-width="4"/>
    <rect x="172" y="202" width="211" height="296" rx="14" fill="none" stroke="$symbol" stroke-width="2"/>
    <polygon points="277,270 289,308 325,308 297,330 308,368 277,347 246,368 257,330 229,308 265,308" fill="$symbol"/>
  </g>
  <g transform="rotate(8, 380, 360)">
    <rect x="255" y="160" width="245" height="330" rx="20" fill="$card"/>
    <rect x="255" y="160" width="245" height="330" rx="20" fill="none" stroke="$symbol" stroke-width="4"/>
    <rect x="272" y="177" width="211" height="296" rx="14" fill="none" stroke="$symbol" stroke-width="2"/>
    <circle cx="375" cy="325" r="78" fill="$symbol"/>
    <circle cx="408" cy="305" r="58" fill="$card"/>
  </g>
</svg>
''',
      width: size,
      height: size,
    );
  }

  String _color(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}
