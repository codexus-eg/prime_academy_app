import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';

class ExamReadyIcon extends StatelessWidget {
  const ExamReadyIcon({
    super.key,
    required this.svg,
    required this.size,
    required this.color,
    this.glow = false,
  });

  final String svg;
  final double size;
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    Widget paintedIcon() {
      return SvgPicture.string(
        svg,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    if (!glow) return paintedIcon();

    // Web wrapper: `text-[#007bff] drop-shadow-[0_0_6px_rgba(0,123,255,0.6)]`
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Opacity(
              opacity: 0.6,
              child: paintedIcon(),
            ),
          ),
          paintedIcon(),
        ],
      ),
    );
  }
}

class ExamCheckeredFlagIcon extends StatelessWidget {
  const ExamCheckeredFlagIcon({super.key, this.size = 20});

  final double size;

  /// Game Icons `GiCheckeredFlag` (react-icons/gi, viewBox 512×512).
  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" fill="currentColor" stroke="currentColor" stroke-width="0">
  <path d="M375.7 20.11l-15.6 3.53c5.5 24.18 10.9 48.4 16.4 72.61-12.4-1.91-22.7-3.61-34-5.36l6.5 28.91c12.4 1.6 22.6 3.6 34 5.3l7.6 33.6c9.4 41.6 18.9 83.3 28.3 124.9-12.4-1.9-22.6-3.7-34-5.4l6.5 28.8c12.3 2.1 22.7 3.4 34 5.4 13.6 59.8 27 119.7 40.6 179.5l15.6-3.7c-37.4-162.5-73.8-328.9-105.9-468.09zM391.4 307c-12.9-1.9-23.9-3.4-33.7-4l7.4 32.9h.4c12.2 1.3 22.5 3.1 33.5 4.7zm-33.7-4l-6.7-29.5c-14.4-1.5-24.2-1.5-32.7.3l7 31.3c10.4-2.4 20.6-2.9 32.4-2.1zm-32.4 2.1c-10.3 2.4-19.7 6.3-30.1 12l7.4 32.7c9.8-5.2 20.1-11.2 29.8-13.4zm-30.1 12l-6.6-29.5c-7.8 4.8-17.2 11.1-28.6 18.8l6.5 28.9c10.8-7.4 20.2-13.4 28.7-18.2zm-28.7 18.2c-10.3 7-18.9 13-28.4 19.5l7.6 33.2c10-7.2 18.8-13.1 28.3-19.6zm-28.4 19.5l-6.5-28.9c-10.8 7.4-20.1 13.4-28.7 18.2l6.7 29.5c7.8-4.8 17.2-11.1 28.5-18.8zm-28.5 18.8c-12.3 7.5-21.2 11.7-29.7 13.7l7 31.2c10.4-2.4 19.8-6.4 30.1-12.1zm-29.7 13.7l-7.1-31.2c-10.3 2.3-20.5 2.8-32.3 2.1l6.7 29.5c14.3 1.5 24.1 1.5 32.7-.4zm-32.7.4c-9.1-.9-20.3-2.6-33.9-4.7l7.6 33.6s16 2.9 33.7 4zm-33.9-4.7l-6.5-28.8c-12.35-2-22.71-3.4-34.02-5.4l6.53 28.8c12.36 1.8 22.69 3.8 33.99 5.4zm-6.5-28.8c12.9 1.9 23.9 3.4 33.7 4l-7.5-32.9c-9.1-1-20.2-2.6-33.8-4.7zm-7.6-33.6l-6.52-28.9c-12.39-1.8-22.66-3.7-34.02-5.3l6.52 28.8c12.35 2 22.71 3.4 34.02 5.4zm-6.52-28.9c12.82 2 23.92 3.5 33.72 4.1l-7.5-32.9c-9.1-1-20.19-2.6-33.82-4.7zm-7.6-33.6l-6.52-28.9c-12.38-1.8-22.66-3.6-34.02-5.2l6.52 28.8c12.38 1.9 22.64 3.7 34.02 5.3zm-6.52-28.9c12.89 2 23.94 3.5 33.74 4.1l-7.5-33c-9.07-.9-20.22-2.5-33.84-4.7zm-7.6-33.6l-6.52-28.8c-12.33-2.1-22.71-3.3-34.02-5.3l6.52 28.9c12.36 1.9 22.66 3.6 34.02 5.2zm-6.52-28.8c12.89 2 23.93 3.5 33.72 4l-7.45-32.9c-11.72-2.1-24.9-3.3-33.87-4.7zm33.72 4l6.64 29.5c14.4 1.6 24.2 1.5 32.7-.4l-7-31.2c-10.4 2.4-20.6 2.9-32.34 2.1zm32.24-2.1c10.4-2.3 19.8-6.3 30.2-12l-7.5-32.9c-12.3 7.5-21.2 11.7-29.7 13.7zm-7-31.2c-.1 0-.1 0 0 0zm37.2 19.2l6.6 29.5c7.8-4.8 17.2-11 28.6-18.8l-6.6-28.8c-10.7 7.3-20.1 13.4-28.6 18.1zm28.6-18.1c10.3-7 18.9-13.1 28.5-19.4l-7.6-33.66c-10.4 7.05-19 13.01-28.5 19.56zm28.5-19.4l6.5 28.7c10.8-7.3 20.1-13.4 28.7-18.1l-6.7-29.5c-7.8 4.8-17.2 11.1-28.5 18.9zm28.5-18.9c12.3-7.55 21.2-11.74 29.7-13.68l-7-31.2c-11.1 3-21.8 7.36-30.1 11.95zm29.7-13.68l7.1 31.28c10.3-2.4 20.5-2.9 32.3-2.2l-6.7-29.53c-14.3-1.51-24.1-1.48-32.7.45zm32.7-.45c9.1.97 20.3 2.59 33.9 4.72l-7.6-33.59s-16.1-2.91-33.7-4.03zm6.7 29.53l7.4 32.8c9.2 1 20.3 2.6 33.9 4.8l-7.6-33.5c-12.9-2-23.9-3.5-33.7-4.1zm41.3 37.6l6.5 28.8c12.4 1.9 22.7 3.7 34.1 5.3l-6.6-28.8c-12.4-1.9-22.7-3.7-34-5.3zm6.5 28.8c-12.8-2-23.9-3.5-33.7-4l7.5 33c9.1.9 20.2 2.5 33.8 4.6zm7.6 33.6l6.6 28.9c12.4 2 22.7 3.4 34 5.3l-6.5-28.9c-12.4-1.8-22.7-3.7-34.1-5.3zm6.6 28.9c-12.9-2-24-3.5-33.8-4l7.5 32.9c9.1.8 20.2 2.6 33.9 4.7zm-33.8-4l-6.6-29.5c-14.4-1.6-24.2-1.5-32.7.4l7 31.1c10.3-2.3 20.6-2.8 32.3-2zm-32.3 2c-10.3 2.5-19.8 6.4-30.1 12l7.5 33c12.3-7.5 21.1-11.8 29.7-13.8zm-30.1 12l-6.7-29.5c-7.8 4.9-17.1 11-28.5 18.9l6.5 28.8c10.8-7.3 20.1-13.5 28.7-18.2zm-28.7 18.2c-10.5 6.9-18.7 13.2-28.4 19.5l7.6 33.6c10.4-7 19-13 28.4-19.5zM224 292.2l-6.5-28.8c-10.8 7.3-20.1 13.4-28.7 18.2l6.7 29.5c7.8-4.8 17.1-11.1 28.5-18.9zm-28.5 18.9c-12.3 7.5-21.2 11.7-29.7 13.6l7 31.4c10.3-2.4 19.8-6.4 30.1-12zm-29.7 13.6l-7.1-31.1c-10.3 2.3-20.5 2.8-32.2 2.1l6.5 29.5c14.4 1.5 24.2 1.5 32.8-.5zm-7.1-31.1c10.3-2.4 19.8-6.2 30.1-11.9l-7.4-33.1c-12.3 7.7-21.2 11.9-29.8 13.7zm-7.1-31.3l-7-31.2c-10.3 2.4-20.5 3-32.2 2.2l6.6 29.5c14.3 1.5 24.1 1.5 32.6-.5zm-7-31.2c10.3-2.3 19.7-6.3 30.1-12l-7.5-32.9c-12.3 7.6-21.1 11.9-29.7 13.7zm30.1-12l6.7 29.5c7.8-4.6 17.1-11 28.5-18.8l-6.5-28.8c-10.8 7.3-20.1 13.4-28.7 18.1zm28.7-18c10.2-7.2 18.9-13 28.4-19.5l-7.6-33.7c-10.3 7.2-19 13.1-28.4 19.6zm28.4-19.5l6.5 28.8c10.8-7.3 20.1-13.4 28.7-18.1l-6.7-29.5c-7.8 4.7-17.1 11-28.5 18.8zm28.5-18.9c12.3-7.6 21.2-11.8 29.7-13.6l-7-31.2c-10.3 2.2-19.8 6.1-30.1 11.8zm29.7-13.6l7.1 31.1c10.3-2.3 20.5-2.9 32.3-2.1l-6.7-29.5c-14.3-1.6-24.1-1.5-32.7.5zm7.1 31.1c-10.3 2.4-19.8 6.4-30.1 12l7.4 32.9c12.3-7.5 21.2-11.8 29.8-13.6zm-58.8 30.1c-10.3 7.1-19 13-28.4 19.5l7.6 33.7c10.3-7.2 18.9-13 28.4-19.5z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ExamReadyIcon(
      svg: _svg,
      size: size,
      color: AppColors.examAccentBlue,
      glow: true,
    );
  }
}

class ExamRunningIcon extends StatelessWidget {
  const ExamRunningIcon({super.key, this.size = 20});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 416 512">
  <path fill="#000000" d="M272 96c26.51 0 48-21.49 48-48S298.51 0 272 0s-48 21.49-48 48 21.49 48 48 48zM113.69 317.47l-14.8 34.52H32c-17.67 0-32 14.33-32 32s14.33 32 32 32h77.45c19.25 0 36.58-11.44 44.11-29.09l8.79-20.52-10.67-6.3c-17.32-10.23-30.06-25.37-37.99-42.61zM384 223.99h-44.03l-26.06-53.25c-12.5-25.55-35.45-44.23-61.78-50.94l-71.08-21.14c-28.3-6.8-57.77-.55-80.84 17.14l-39.67 30.41c-14.03 10.75-16.69 30.83-5.92 44.86s30.84 16.66 44.86 5.92l39.69-30.41c7.67-5.89 17.44-8 25.27-6.14l14.7 4.37-37.46 87.39c-12.62 29.48-1.31 64.01 26.3 80.31l84.98 50.17-27.47 87.73c-5.28 16.86 4.11 34.81 20.97 40.09 3.19 1 6.41 1.48 9.58 1.48 13.61 0 26.23-8.77 30.52-22.45l31.64-101.06c5.91-20.77-2.89-43.08-21.64-54.39l-61.24-36.14 31.31-78.28 20.27 41.43c8 16.34 24.92 26.89 43.11 26.89H384c17.67 0 32-14.33 32-32s-14.33-31.99-32-31.99z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ExamReadyIcon(
      svg: _svg,
      size: size,
      color: AppColors.examAccentBlue,
      glow: true,
    );
  }
}

class ExamClockIcon extends StatelessWidget {
  const ExamClockIcon({super.key, this.size = 16});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none">
  <circle stroke="#000000" stroke-width="2" cx="12" cy="12" r="10"/>
  <polyline stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" points="12 6 12 12 16 14"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ExamReadyIcon(
      svg: _svg,
      size: size,
      color: AppColors.examAccentBlue,
    );
  }
}

class ExamPlayFillIcon extends StatelessWidget {
  const ExamPlayFillIcon({super.key, this.size = 24});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <path fill="#000000" d="m11.596 8.697-6.363 3.692c-.54.313-1.233-.066-1.233-.697V4.308c0-.63.692-1.01 1.233-.696l6.363 3.692a.802.802 0 0 1 0 1.393"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ExamReadyIcon(
      svg: _svg,
      size: size,
      color: AppColors.primary,
    );
  }
}

class ExamBoxArrowRightIcon extends StatelessWidget {
  const ExamBoxArrowRightIcon({super.key, this.size = 20});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <path fill="#000000" fill-rule="evenodd" d="M10 12.5a.5.5 0 0 1-.5.5h-8a.5.5 0 0 1-.5-.5v-9a.5.5 0 0 1 .5-.5h8a.5.5 0 0 1 .5.5v2a.5.5 0 0 0 1 0v-2A1.5 1.5 0 0 0 9.5 2h-8A1.5 1.5 0 0 0 0 3.5v9A1.5 1.5 0 0 0 1.5 14h8a1.5 1.5 0 0 0 1.5-1.5v-2a.5.5 0 0 0-1 0z"/>
  <path fill="#000000" fill-rule="evenodd" d="M15.854 8.354a.5.5 0 0 0 0-.708l-3-3a.5.5 0 0 0-.708.708L14.293 7.5H5.5a.5.5 0 0 0 0 1h8.793l-2.147 2.146a.5.5 0 0 0 .708.708z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ExamReadyIcon(
      svg: _svg,
      size: size,
      color: AppColors.onDark,
    );
  }
}

/// Bootstrap Icons `BsCheckCircleFill` (viewBox 16×16).
class ExamCheckCircleFillIcon extends StatelessWidget {
  const ExamCheckCircleFillIcon({
    super.key,
    this.size = 24,
    this.color = const Color(0xFF4ADE80),
  });

  final double size;
  final Color color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <path fill="currentColor" d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0m-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ExamReadyIcon(svg: _svg, size: size, color: color);
  }
}

/// Bootstrap Icons `BsXCircleFill` (viewBox 16×16).
class ExamXCircleFillIcon extends StatelessWidget {
  const ExamXCircleFillIcon({
    super.key,
    this.size = 24,
    this.color = const Color(0xFFF87171),
  });

  final double size;
  final Color color;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <path fill="currentColor" d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0M5.354 4.646a.5.5 0 1 0-.708.708L7.293 8l-2.647 2.646a.5.5 0 0 0 .708.708L8 8.707l2.646 2.647a.5.5 0 0 0 .708-.708L8.707 8l2.647-2.646a.5.5 0 0 0-.708-.708L8 7.293z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ExamReadyIcon(svg: _svg, size: size, color: color);
  }
}

class ExamPennantFilledIcon extends StatelessWidget {
  const ExamPennantFilledIcon({
    super.key,
    required this.size,
    this.isComplete = false,
  });

  final double size;
  final bool isComplete;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
  <path stroke="none" d="M0 0h24v24H0z" fill="none"/>
  <path d="M10 2a1 1 0 0 1 .993 .883l.007 .117v.35l8.406 3.736c.752 .335 .79 1.365 .113 1.77l-.113 .058l-8.406 3.735v7.351h1a1 1 0 0 1 .117 1.993l-.117 .007h-4a1 1 0 0 1 -.117 -1.993l.117 -.007h1v-17a1 1 0 0 1 1 -1z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final color = AppColors.examAccentBlue;
    final icon = SvgPicture.string(
      _svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: isComplete ? 6 : 4,
            sigmaY: isComplete ? 6 : 4,
          ),
          child: Opacity(
            opacity: isComplete ? 0.85 : 0.55,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                color.withValues(alpha: isComplete ? 0.9 : 0.7),
                BlendMode.srcIn,
              ),
              child: SvgPicture.string(
                _svg,
                width: size,
                height: size,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 1.5),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Opacity(
              opacity: 0.35,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.string(
                  _svg,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        icon,
      ],
    );
  }
}

class ExamChevronUpIcon extends StatelessWidget {
  const ExamChevronUpIcon({super.key, required this.size});

  final double size;

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" fill="currentColor">
  <path d="M233.4 105.4c12.5-12.5 32.8-12.5 45.3 0l192 192c12.5 12.5 12.5 32.8 0 45.3s-32.8 12.5-45.3 0L256 173.3 86.6 342.6c-12.5 12.5-32.8 12.5-45.3 0s-12.5-32.8 0-45.3l192-192z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        Colors.white.withValues(alpha: 0.6),
        BlendMode.srcIn,
      ),
    );
  }
}
