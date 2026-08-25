import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/chat/chat_models.dart';

class LessonChatUser {
  const LessonChatUser({
    required this.name,
    required this.role,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;
  final int role;

  String get roleLabel => role == 1 ? 'طالب' : 'معلم';
}

class LessonChatBubble extends StatelessWidget {
  const LessonChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.user,
    this.localAudioBytes,
    this.onEdit,
    this.onDelete,
  });

  final ChatMessage message;
  final bool isMine;
  final LessonChatUser user;
  final Uint8List? localAudioBytes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final media = message.media;
    final maxBubbleWidth = math.min(
      MediaQuery.sizeOf(context).width * 0.8,
      640.0,
    );

    return Opacity(
      opacity: message.isPending ? 0.72 : 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: math.min(
            AppSpacing.lessonChatBubbleMinWidth,
            maxBubbleWidth,
          ),
          maxWidth: maxBubbleWidth,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.mainBg3,
            borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.lg,
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(user: user),
                    if (message.message.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.base),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.mainBg,
                          borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.base),
                          child: Text(
                            message.message,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onDark,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (media != null) ...[
                      const SizedBox(height: AppSpacing.base),
                      if (media.mimeType.startsWith('image/'))
                        LessonChatImageAttachment(url: media.resolvedUrl)
                      else if (media.mimeType.startsWith('video/'))
                        LessonChatVideoAttachment(url: media.resolvedUrl)
                      else if (media.mimeType.startsWith('audio/'))
                        LessonChatAudioAttachment(
                          url: media.resolvedUrl,
                          localBytes: localAudioBytes,
                          isPending: message.isPending,
                        )
                      else if (media.mimeType == 'application/pdf')
                        LessonChatPdfAttachment(url: media.resolvedUrl),
                    ],
                    if (message.createdAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatChatDate(message.createdAt),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.gray300,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isMine && (onEdit != null || onDelete != null))
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _MessageMenu(
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatChatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM dd, yyyy, hh:mm a', 'en_US').format(parsed.toLocal());
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final LessonChatUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(user: user),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.semibold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppGradients.chatRoleBadge,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    user.roleLabel,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onDark,
                      fontWeight: AppFonts.semibold,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final LessonChatUser user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: AppSpacing.lessonChatAvatarSize,
          height: AppSpacing.lessonChatAvatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _FallbackAvatar(user: user),
        ),
      );
    }
    return _FallbackAvatar(user: user);
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.user});

  final LessonChatUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.lessonChatAvatarSize,
      height: AppSpacing.lessonChatAvatarSize,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.borderSubtle,
        shape: BoxShape.circle,
      ),
      child: Icon(
        user.role == 2 ? Icons.school : Icons.school_outlined,
        size: 30,
        color: user.role == 2 ? const Color(0xFFEAB308) : AppColors.onDark,
      ),
    );
  }
}

class _MessageMenu extends StatelessWidget {
  const _MessageMenu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      iconSize: 16,
      icon: Icon(
        Icons.more_vert,
        size: 16,
        color: AppColors.onDark.withValues(alpha: 0.7),
      ),
      color: AppColors.selected,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
      ),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            height: 36,
            child: Text(
              'تعديل',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onDark),
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            height: 36,
            child: Text(
              'حذف',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onDark),
            ),
          ),
      ],
    );
  }
}

class LessonChatImageAttachment extends StatefulWidget {
  const LessonChatImageAttachment({super.key, required this.url});

  final String url;

  @override
  State<LessonChatImageAttachment> createState() =>
      _LessonChatImageAttachmentState();
}

class _LessonChatImageAttachmentState extends State<LessonChatImageAttachment> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog<void>(
            context: context,
            barrierColor: Colors.black54,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(AppSpacing.base),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.secondaryBg,
                  borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                    ),
                    child: Image.network(widget.url, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          );
        },
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1,
          duration: AppDurations.tab,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: AppSpacing.lessonChatMediaMaxHeight,
              ),
              child: Image.network(widget.url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class LessonChatPdfAttachment extends StatelessWidget {
  const LessonChatPdfAttachment({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () =>
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Text(
            'فتح في علامة تبويب جديدة',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.accentIconMuted400,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.accentIconMuted400,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSpacing.lessonChatMediaMaxHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray500),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Center(
              child: IconButton(
                onPressed: () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.blue,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LessonChatVideoAttachment extends StatefulWidget {
  const LessonChatVideoAttachment({super.key, required this.url});

  final String url;

  @override
  State<LessonChatVideoAttachment> createState() =>
      _LessonChatVideoAttachmentState();
}

class _LessonChatVideoAttachmentState extends State<LessonChatVideoAttachment> {
  late final VideoPlayerController _controller;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      })
      ..setVolume(1)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox(
        height: AppSpacing.lessonChatMediaMaxHeight,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentIconMuted,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: AppSpacing.lessonChatMediaMaxHeight,
        ),
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio == 0
              ? 16 / 9
              : _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.blue,
                  bufferedColor: AppColors.gray500,
                  backgroundColor: AppColors.mainBg3,
                ),
              ),
              Center(
                child: IconButton(
                  iconSize: 48,
                  color: Colors.white70,
                  onPressed: () {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  },
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LessonChatAudioAttachment extends StatefulWidget {
  const LessonChatAudioAttachment({
    super.key,
    required this.url,
    this.localBytes,
    this.isPending = false,
  });

  final String url;
  final Uint8List? localBytes;
  final bool isPending;

  @override
  State<LessonChatAudioAttachment> createState() =>
      _LessonChatAudioAttachmentState();
}

class _LessonChatAudioAttachmentState extends State<LessonChatAudioAttachment> {
  final _player = AudioPlayer();
  var _playing = false;
  var _duration = Duration.zero;
  var _position = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _posSub = _player.onPositionChanged.listen((d) {
      if (mounted) setState(() => _position = d);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    unawaited(_posSub?.cancel());
    unawaited(_durSub?.cancel());
    unawaited(_completeSub?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }

    setState(() => _playing = true);
    try {
      if (_position == Duration.zero) {
        if (widget.localBytes != null) {
          await _player.play(BytesSource(widget.localBytes!));
        } else {
          await _player.play(UrlSource(widget.url));
        }
      } else {
        await _player.resume();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _playing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تشغيل الصوت')),
        );
      }
    }
  }

  String _remainingLabel() {
    final total = _duration.inSeconds;
    final current = _position.inSeconds;
    final remaining = math.max(total - current, 0);
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(AppRadius.tailwindXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 15,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _WaveformPainter(progress: progress),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isPending && !_playing ? 'جارٍ الإرسال...' : _remainingLabel(),
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            IconButton(
              onPressed:
                  widget.isPending && widget.localBytes == null ? null : _toggle,
              icon: widget.isPending && !_playing && widget.localBytes == null
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _playing ? Icons.pause : Icons.play_arrow,
                      size: 20,
                      color: AppColors.onDark,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 2.0;
    const gap = 2.0;
    final count = math.max(((size.width + gap) / (barWidth + gap)).floor(), 1);
    final played = Paint()..color = AppColors.blue;
    final rest = Paint()..color = const Color(0xFFCCCCCC);

    for (var i = 0; i < count; i++) {
      final t = i / count;
      final heightFactor = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(i * 0.85));
      final barHeight = size.height * heightFactor;
      final x = i * (barWidth + gap);
      final y = (size.height - barHeight) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1),
        ),
        t <= progress ? played : rest,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class LessonChatInputBar extends StatelessWidget {
  const LessonChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.sending,
    required this.recording,
    required this.paused,
    required this.hasPreview,
    required this.recordSeconds,
    this.onAttach,
    this.onToggleRecord,
    this.onPauseRecord,
    this.onResumeRecord,
    this.onCancelRecord,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onToggleRecord;
  final VoidCallback? onPauseRecord;
  final VoidCallback? onResumeRecord;
  final VoidCallback? onCancelRecord;
  final bool sending;
  final bool recording;
  final bool paused;
  final bool hasPreview;
  final int recordSeconds;

  String get _timeLabel {
    final m = recordSeconds ~/ 60;
    final s = (recordSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (recording)
              Expanded(
                child: _RecordingBar(
                  timeLabel: _timeLabel,
                  paused: paused,
                  onDelete: onCancelRecord,
                  onPause: onPauseRecord,
                  onResume: onResumeRecord,
                ),
              )
            else if (hasPreview)
              Expanded(
                child: _RecordingBar(
                  timeLabel: 'Preview recording',
                  paused: true,
                  isPreview: true,
                  onDelete: onCancelRecord,
                  onPause: null,
                  onResume: null,
                ),
              )
            else
              Expanded(
                child: _MessageField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !sending,
                  onSubmit: onSend,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            _RoundActionButton(
              icon: Icons.attach_file,
              onTap: sending || recording || paused ? null : onAttach,
            ),
            const SizedBox(width: AppSpacing.sm),
            _RoundActionButton(
              icon: Icons.mic,
              pulsing: recording && !paused,
              danger: recording,
              onTap: sending ? null : onToggleRecord,
            ),
            const SizedBox(width: AppSpacing.sm),
            _RoundActionButton(
              icon: Icons.send,
              onTap: sending ? null : onSend,
              dimmed: sending,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  const _MessageField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.lessonChatInputHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mainBg3,
          borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          maxLength: 1000,
          maxLines: 1,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSubmit(),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onDark),
          cursorColor: AppColors.onDark,
          decoration: const InputDecoration(
            counterText: '',
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.timeLabel,
    required this.paused,
    required this.onDelete,
    this.onPause,
    this.onResume,
    this.isPreview = false,
  });

  final String timeLabel;
  final bool paused;
  final bool isPreview;
  final VoidCallback? onDelete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.lessonChatInputHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mainBg3,
          borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                icon: const Icon(Icons.delete, size: 20, color: AppColors.onDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: isPreview
                    ? Text(
                        timeLabel,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onDark,
                        ),
                      )
                    : _PulseLine(active: !paused),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isPreview ? '' : timeLabel,
                style: AppTypography.bodySm.copyWith(color: AppColors.onDark),
              ),
              if (!isPreview) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: paused ? onResume : onPause,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: Icon(
                    paused ? Icons.play_arrow : Icons.pause,
                    size: 20,
                    color: AppColors.onDark,
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

class _PulseLine extends StatefulWidget {
  const _PulseLine({required this.active});

  final bool active;

  @override
  State<_PulseLine> createState() => _PulseLineState();
}

class _PulseLineState extends State<_PulseLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatefulWidget {
  const _RoundActionButton({
    required this.icon,
    this.onTap,
    this.pulsing = false,
    this.danger = false,
    this.dimmed = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool pulsing;
  final bool danger;
  final bool dimmed;

  @override
  State<_RoundActionButton> createState() => _RoundActionButtonState();
}

class _RoundActionButtonState extends State<_RoundActionButton>
    with SingleTickerProviderStateMixin {
  var _hovered = false;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _RoundActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final bg = widget.danger
        ? const Color(0xFFEF4444)
        : _hovered && enabled
            ? AppColors.mainBg
            : AppColors.mainBg3;

    final button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: widget.dimmed || !enabled ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue, width: 2),
            ),
            child: Icon(widget.icon, size: 14, color: AppColors.onDark),
          ),
        ),
      ),
    );

    if (!widget.pulsing) return button;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(_pulse),
      child: button,
    );
  }
}

class LessonEditMessageDialog extends StatelessWidget {
  const LessonEditMessageDialog({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.secondaryBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.shadcnMd),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.dialogBorder, width: 2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Text(
                  'تعديل الرسالة',
                  style: AppTypography.size20.copyWith(
                    color: AppColors.onDark,
                    fontWeight: AppFonts.semibold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.onDark),
                    decoration: InputDecoration(
                      hintText: 'قم بتعديل الرسالة هنا...',
                      hintStyle: AppTypography.bodyMd.copyWith(
                        color: AppColors.gray500,
                      ),
                      filled: true,
                      fillColor: AppColors.secondaryBg,
                      contentPadding: const EdgeInsets.all(12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.shadcnMd),
                        borderSide: const BorderSide(
                          color: AppColors.gray500,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.shadcnMd),
                        borderSide: const BorderSide(
                          color: AppColors.gray500,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFB91C1C),
                          foregroundColor: AppColors.onDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: const Text('إلغاء'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.secondaryCard,
                          foregroundColor: AppColors.onDark,
                          minimumSize: const Size(67, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: const Text('تعديل'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
