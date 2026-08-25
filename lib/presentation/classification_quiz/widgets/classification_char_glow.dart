import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class ClassificationCharGlow extends StatelessWidget {
  const ClassificationCharGlow({
    super.key,
    required this.imageAsset,
    this.maxSize = 375,
    this.imageOffsetX = 0,
  });

  final String imageAsset;
  final double maxSize;
  final double imageOffsetX;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final size = math.min(width - 48, maxSize);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: size * 0.22,
            right: size * 0.205,
            child: _GlowBlob(
              color: const Color(0xFF62A3F0),
              width: size * 0.305,
              height: size * 0.305,
            ),
          ),
          Positioned(
            bottom: size * 0.21,
            left: size * 0.145,
            child: _GlowBlob(
              color: const Color(0xFF2C0E4B),
              width: size * 0.365,
              height: size * 0.37,
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Transform.translate(
              offset: Offset(imageOffsetX, 0),
              child: Image.asset(
                imageAsset,
                width: size,
                height: size,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
