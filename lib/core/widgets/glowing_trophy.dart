import 'dart:ui';

import 'package:flutter/material.dart';

class GlowingTrophy extends StatelessWidget {
  const GlowingTrophy({
    super.key,
    required this.asset,
    this.width = 128,
    this.height = 120,
  });

  final String asset;
  final double width;
  final double height;

  static const _glow = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [

          Transform.scale(
            scale: 1.08,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Image.asset(
                asset,
                width: width,
                height: height,
                fit: BoxFit.contain,
                color: _glow.withValues(alpha: 0.65),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),

          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Image.asset(
              asset,
              width: width,
              height: height,
              fit: BoxFit.contain,
              color: _glow.withValues(alpha: 0.35),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          Image.asset(
            asset,
            width: width,
            height: height,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
