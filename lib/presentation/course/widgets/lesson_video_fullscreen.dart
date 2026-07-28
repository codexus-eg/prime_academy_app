import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

export 'lesson_video_fullscreen_stub.dart'
    if (dart.library.html) 'lesson_video_fullscreen_web.dart';

class LessonVideoFullscreenPage extends StatefulWidget {
  const LessonVideoFullscreenPage({
    super.key,
    required this.child,
    this.onClose,
  });

  final Widget child;
  final VoidCallback? onClose;

  @override
  State<LessonVideoFullscreenPage> createState() =>
      _LessonVideoFullscreenPageState();
}

class _LessonVideoFullscreenPageState extends State<LessonVideoFullscreenPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _close() {
    widget.onClose?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: widget.child),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'إغلاق ملء الشاشة',
                onPressed: _close,
                icon: const Icon(
                  Icons.fullscreen_exit_rounded,
                  color: AppColors.onDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonVideoFullscreenButton extends StatelessWidget {
  const LessonVideoFullscreenButton({
    super.key,
    required this.onPressed,
    this.isFullscreen = false,
    this.size = 24,
  });

  final VoidCallback onPressed;
  final bool isFullscreen;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(size * 0.2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.scrim80,
          ),
          child: Icon(
            isFullscreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            color: AppColors.onDark,
            size: size,
          ),
        ),
      ),
    );
  }
}

Future<void> openLessonVideoFullscreenRoute(
  BuildContext context, {
  required WidgetBuilder builder,
  VoidCallback? onClose,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return LessonVideoFullscreenPage(
          onClose: onClose,
          child: builder(context),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}
