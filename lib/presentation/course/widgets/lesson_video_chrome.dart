import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

/// Vidstack `DefaultVideoLayout` analogue used by the web MP4 and YouTube
/// players: play, seek, mute, speed, optional quality, fullscreen.
class LessonVideoChrome extends StatefulWidget {
  const LessonVideoChrome({
    super.key,
    required this.started,
    required this.playing,
    required this.controlsVisible,
    required this.isFullscreen,
    required this.muted,
    required this.playbackRate,
    required this.position,
    required this.duration,
    required this.seeking,
    required this.seekValue,
    required this.onTogglePlay,
    required this.onToggleControls,
    required this.onToggleMute,
    required this.onRateChanged,
    required this.onFullscreen,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    this.buffering = false,
    this.loading = false,
    this.thumbnailUrl,
    this.errorMessage,
    this.onRetry,
    this.qualityLabel,
    this.qualities = const [],
    this.onQualityChanged,
  });

  final bool started;
  final bool playing;
  final bool buffering;
  final bool loading;
  final bool controlsVisible;
  final bool isFullscreen;
  final bool muted;
  final double playbackRate;
  final Duration position;
  final Duration duration;
  final bool seeking;
  final double seekValue;
  final String? thumbnailUrl;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleControls;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onRateChanged;
  final VoidCallback onFullscreen;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final String? qualityLabel;
  final List<String> qualities;
  final ValueChanged<String>? onQualityChanged;

  static const rates = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  static const sliderColor = AppColors.courseTitleGradientStart;

  static String formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  State<LessonVideoChrome> createState() => _LessonVideoChromeState();
}

class _LessonVideoChromeState extends State<LessonVideoChrome> {
  _ChromeMenu _menu = _ChromeMenu.none;

  void _closeMenu() {
    if (_menu != _ChromeMenu.none) setState(() => _menu = _ChromeMenu.none);
  }

  @override
  void didUpdateWidget(covariant LessonVideoChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controlsVisible && _menu != _ChromeMenu.none) {
      _menu = _ChromeMenu.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorMessage;
    if (error != null) {
      return _ErrorOverlay(message: error, onRetry: widget.onRetry);
    }
    if (widget.loading && !widget.started) {
      return const _LoadingOverlay();
    }
    if (!widget.started) {
      return _Poster(
        thumbnailUrl: widget.thumbnailUrl,
        onPlay: widget.onTogglePlay,
      );
    }

    final totalSeconds = widget.duration.inMilliseconds / 1000;
    final currentSeconds =
        widget.seeking ? widget.seekValue : widget.position.inMilliseconds / 1000;
    final maxSeconds = totalSeconds <= 0 ? 1.0 : totalSeconds;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!widget.playing && widget.thumbnailUrl != null)
            _Poster(
              thumbnailUrl: widget.thumbnailUrl,
              onPlay: widget.onTogglePlay,
              dim: true,
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _closeMenu();
                widget.onToggleControls();
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          if (widget.buffering) const _LoadingOverlay(),
          AnimatedOpacity(
            opacity: widget.controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !widget.controlsVisible,
              child: _ControlsLayer(
                playing: widget.playing,
                muted: widget.muted,
                playbackRate: widget.playbackRate,
                isFullscreen: widget.isFullscreen,
                currentSeconds: currentSeconds.clamp(0, maxSeconds),
                maxSeconds: maxSeconds,
                durationSeconds: widget.duration.inSeconds,
                menu: _menu,
                qualityLabel: widget.qualityLabel,
                qualities: widget.qualities,
                onTogglePlay: widget.onTogglePlay,
                onToggleMute: widget.onToggleMute,
                onFullscreen: widget.onFullscreen,
                onSeekStart: widget.onSeekStart,
                onSeekChanged: widget.onSeekChanged,
                onSeekEnd: widget.onSeekEnd,
                onOpenMenu: (menu) => setState(() => _menu = menu),
                onRateChanged: (rate) {
                  widget.onRateChanged(rate);
                  _closeMenu();
                },
                onQualityChanged: widget.onQualityChanged == null
                    ? null
                    : (quality) {
                        widget.onQualityChanged!(quality);
                        _closeMenu();
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChromeMenu { none, settings, speed, quality }

class _ControlsLayer extends StatelessWidget {
  const _ControlsLayer({
    required this.playing,
    required this.muted,
    required this.playbackRate,
    required this.isFullscreen,
    required this.currentSeconds,
    required this.maxSeconds,
    required this.durationSeconds,
    required this.menu,
    required this.onTogglePlay,
    required this.onToggleMute,
    required this.onFullscreen,
    required this.onSeekStart,
    required this.onSeekChanged,
    required this.onSeekEnd,
    required this.onOpenMenu,
    required this.onRateChanged,
    this.qualityLabel,
    this.qualities = const [],
    this.onQualityChanged,
  });

  final bool playing;
  final bool muted;
  final double playbackRate;
  final bool isFullscreen;
  final double currentSeconds;
  final double maxSeconds;
  final int durationSeconds;
  final _ChromeMenu menu;
  final String? qualityLabel;
  final List<String> qualities;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleMute;
  final VoidCallback onFullscreen;
  final ValueChanged<double> onSeekStart;
  final ValueChanged<double> onSeekChanged;
  final ValueChanged<double> onSeekEnd;
  final ValueChanged<_ChromeMenu> onOpenMenu;
  final ValueChanged<double> onRateChanged;
  final ValueChanged<String>? onQualityChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66000000),
            Color(0x00000000),
            Color(0xE6000000),
          ],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: _ChromeIconButton(
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: isFullscreen ? 56 : 48,
              onTap: onTogglePlay,
            ),
          ),
          if (menu == _ChromeMenu.speed)
            _MenuCard(
              title: 'Speed',
              onBack: () => onOpenMenu(_ChromeMenu.settings),
              children: [
                for (final rate in LessonVideoChrome.rates)
                  _MenuRow(
                    label: rate == 1.0 ? 'Normal' : '${_rateLabel(rate)}x',
                    selected: playbackRate == rate,
                    onTap: () => onRateChanged(rate),
                  ),
              ],
            )
          else if (menu == _ChromeMenu.quality)
            _MenuCard(
              title: 'Quality',
              onBack: () => onOpenMenu(_ChromeMenu.settings),
              children: [
                for (final quality in qualities)
                  _MenuRow(
                    label: quality,
                    selected: qualityLabel == quality,
                    onTap: onQualityChanged == null
                        ? null
                        : () => onQualityChanged!(quality),
                  ),
              ],
            )
          else if (menu == _ChromeMenu.settings)
            _MenuCard(
              title: 'Settings',
              children: [
                _MenuRow(
                  label: 'Speed',
                  trailing: playbackRate == 1.0
                      ? 'Normal'
                      : '${_rateLabel(playbackRate)}x',
                  onTap: () => onOpenMenu(_ChromeMenu.speed),
                ),
                if (qualities.isNotEmpty)
                  _MenuRow(
                    label: 'Quality',
                    trailing: qualityLabel ?? 'Auto',
                    onTap: () => onOpenMenu(_ChromeMenu.quality),
                  ),
              ],
            ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.5,
                    activeTrackColor: LessonVideoChrome.sliderColor,
                    inactiveTrackColor: const Color(0x66FFFFFF),
                    thumbColor: LessonVideoChrome.sliderColor,
                    overlayColor: const Color(0x330E3995),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: currentSeconds,
                    max: maxSeconds,
                    onChangeStart: onSeekStart,
                    onChanged: onSeekChanged,
                    onChangeEnd: onSeekEnd,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  child: Row(
                    children: [
                      _BarIcon(
                        icon: playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        onTap: onTogglePlay,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        LessonVideoChrome.formatTime(currentSeconds.round()),
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onDark,
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      Text(
                        ' / ${LessonVideoChrome.formatTime(durationSeconds)}',
                        style: AppTypography.bodySm.copyWith(
                          color: const Color(0xB3FFFFFF),
                          fontSize: 12,
                          height: 1,
                        ),
                      ),
                      const Spacer(),
                      _BarIcon(
                        icon: muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        onTap: onToggleMute,
                      ),
                      _BarIcon(
                        icon: Icons.settings_rounded,
                        onTap: () => onOpenMenu(
                          menu == _ChromeMenu.none
                              ? _ChromeMenu.settings
                              : _ChromeMenu.none,
                        ),
                      ),
                      _BarIcon(
                        icon: isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        onTap: onFullscreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _rateLabel(double rate) {
    if (rate == rate.roundToDouble()) return rate.toStringAsFixed(0);
    return rate.toString();
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.children,
    this.onBack,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 72,
      child: Material(
        color: const Color(0xF21A1A1A),
        elevation: 8,
        borderRadius: BorderRadius.circular(AppRadius.smPlus),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                  child: Row(
                    children: [
                      if (onBack != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onBack,
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      else
                        const SizedBox(width: 8),
                      Text(
                        title,
                        style: AppTypography.bodySm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.label,
    this.trailing,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String? trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (selected)
              const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            else
              const SizedBox(width: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySm.copyWith(color: Colors.white),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.bodySm.copyWith(
                  color: const Color(0xB3FFFFFF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC000000),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.thumbnailUrl,
    required this.onPlay,
    this.dim = false,
  });

  final String? thumbnailUrl;
  final VoidCallback onPlay;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: thumbnailUrl == null || thumbnailUrl!.isEmpty
                ? const SizedBox.expand()
                : Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: Colors.black),
                  ),
          ),
          ColoredBox(color: dim ? const Color(0x66000000) : const Color(0x40000000)),
          Center(
            child: _ChromeIconButton(
              icon: Icons.play_arrow_rounded,
              size: 56,
              onTap: onPlay,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: ColoredBox(
        color: Color(0x66000000),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xCC000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LessonVideoPlayerShell extends StatelessWidget {
  const LessonVideoPlayerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: AppRadius.borderTailwindXl,
        child: ColoredBox(color: Colors.black, child: child),
      ),
    );
  }
}
