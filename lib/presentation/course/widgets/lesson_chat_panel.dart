import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/web/web_media.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons/custom_button.dart';
import '../../../data/auth/auth_session.dart';
import '../../../data/courses/user_course.dart';
import '../../../data/sse/sse_service.dart';
import '../../../data/chat/chat_models.dart';
import '../../../data/upload/upload_api.dart';
import '../../../data/upload/upload_mime.dart';

const _pageSize = 20;
const _maxMessageLength = 1000;

class LessonChatPanel extends StatefulWidget {
  const LessonChatPanel({
    super.key,
    required this.chatId,
    required this.courseId,
    this.teacher,
    this.onClose,
  });

  final int chatId;
  final int courseId;
  final ModuleTeacher? teacher;
  final VoidCallback? onClose;

  @override
  State<LessonChatPanel> createState() => _LessonChatPanelState();
}

class _LessonChatPanelState extends State<LessonChatPanel> {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = const [];
  AuthUser? _currentUser;
  var _loading = true;
  var _sending = false;
  var _loadingMore = false;
  var _hasMore = true;
  var _page = 1;
  String? _errorMessage;

  WebAudioRecorder? _recorder;
  var _recording = false;
  var _recordSeconds = 0;
  Timer? _recordTimer;
  Timer? _pollTimer;
  var _optimisticId = -1;
  final _localAudioBytes = <int, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_onScroll);
    ChatLiveHub.instance.subscribe(
      chatId: widget.chatId,
      onMessage: _onLiveMessage,
      onEdited: _onLiveEdited,
      onDeleted: _onLiveDeleted,
    );
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      unawaited(_pollLatest());
    });
  }

  @override
  void dispose() {
    ChatLiveHub.instance.unsubscribe(widget.chatId);
    _pollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _recordTimer?.cancel();
    _recorder?.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _currentUser = await AuthSession.load();
    if (mounted) setState(() {});
    await _loadMessages(reset: true);
  }

  void _onLiveMessage(ChatMessage message) {
    if (!mounted || message.chatId != widget.chatId) return;
    if (_messages.any((m) => m.id == message.id)) return;

    final pendingIndex = _messages.lastIndexWhere(
      (m) => m.isPending && m.senderId == message.senderId,
    );
    if (pendingIndex >= 0) {
      _replaceMessage(
        _messages[pendingIndex].id,
        _mergeServerMessage(message, _messages[pendingIndex]),
      );
      return;
    }

    _insertMessage(message);
  }

  void _onLiveEdited(ChatMessage message) {
    if (!mounted || message.chatId != widget.chatId) return;
    setState(() {
      _messages = [
        for (final item in _messages)
          item.id == message.id ? message : item,
      ];
    });
  }

  void _onLiveDeleted(int messageId) {
    if (!mounted) return;
    setState(() {
      _messages = _messages.where((m) => m.id != messageId).toList();
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= 120;
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels <= 80) {
      _loadMessages(reset: false);
    }
  }

  Future<void> _pollLatest() async {
    if (_loading || _loadingMore || !mounted) return;
    try {
      final fetched = await ChatApi.fetchMessages(
        chatId: widget.chatId,
        page: 1,
      );
      if (!mounted || fetched.isEmpty) return;

      final existingIds = _messages.map((m) => m.id).toSet();
      final incoming = fetched.reversed
          .where((message) => !existingIds.contains(message.id))
          .toList();
      if (incoming.isEmpty) return;

      final nearBottom = _isNearBottom();
      setState(() => _messages = [..._messages, ...incoming]);
      if (nearBottom) _scrollToBottom();
    } catch (_) {

    }
  }

  Future<void> _loadMessages({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _errorMessage = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    final previousMaxExtent = !reset && _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : null;

    try {
      final page = reset ? 1 : _page + 1;
      final fetched = await ChatApi.fetchMessages(
        chatId: widget.chatId,
        page: page,
      );

      if (!mounted) return;
      final batch = fetched.reversed.toList();

      setState(() {
        if (reset) {
          _messages = batch;
          _page = 1;
        } else {
          _messages = [...batch, ..._messages];
          _page = page;
        }
        _hasMore = fetched.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
      });

      if (reset) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else if (previousMaxExtent != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final diff =
              _scrollController.position.maxScrollExtent - previousMaxExtent;
          _scrollController.jumpTo(_scrollController.position.pixels + diff);
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذّر تحميل الرسائل';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _insertMessage(ChatMessage message, {bool scroll = true}) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == message.id);
      if (index >= 0) {
        final updated = [..._messages];
        updated[index] = message;
        _messages = updated;
      } else {
        _messages = [..._messages, message];
      }
    });
    if (scroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _replaceMessage(int previousId, ChatMessage message) {
    final localBytes = _localAudioBytes.remove(previousId);
    if (localBytes != null) {
      _localAudioBytes[message.id] = localBytes;
    }

    setState(() {
      final index = _messages.indexWhere((m) => m.id == previousId);
      if (index >= 0) {
        final updated = [..._messages];
        updated[index] = message;
        _messages = updated;
        return;
      }
      if (!_messages.any((m) => m.id == message.id)) {
        _messages = [..._messages, message];
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _removeMessage(int messageId) {
    _localAudioBytes.remove(messageId);
    setState(() {
      _messages = _messages.where((m) => m.id != messageId).toList();
    });
  }

  ChatMessage _mergeServerMessage(
    ChatMessage server,
    ChatMessage? optimistic, {
    ChatMediaUpload? uploadedMedia,
  }) {
    final fallbackMedia = optimistic?.media;
    final media = server.media ??
        (uploadedMedia == null
            ? fallbackMedia
            : ChatMedia(
                id: server.id,
                url: uploadedMedia.key,
                mimeType: uploadedMedia.mimeType,
                filename: uploadedMedia.name,
              ));

    if (media == null) return server;
    return server.copyWith(media: media, isPending: false);
  }

  ChatMessage _buildOptimisticMessage({
    required String text,
    ChatMediaUpload? media,
  }) {
    final optimisticId = _optimisticId--;
    return ChatMessage(
      id: optimisticId,
      chatId: widget.chatId,
      senderId: _currentUser?.id ?? 0,
      message: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      senderRole: _currentUser?.role,
      media: media == null
          ? null
          : ChatMedia(
              id: optimisticId,
              url: media.key,
              mimeType: media.mimeType,
              filename: media.name,
            ),
      isPending: true,
    );
  }

  Future<void> _performSend({
    required String text,
    ChatMediaUpload? media,
    ChatMessage? optimistic,
  }) async {
    final response = await ChatApi.sendMessage(
      chatId: widget.chatId,
      message: text,
      courseId: widget.courseId,
      media: media,
    );
    if (!mounted) return;

    final message = _mergeServerMessage(
      response,
      optimistic,
      uploadedMedia: media,
    );

    if (optimistic != null) {
      _replaceMessage(optimistic.id, message);
    } else {
      _insertMessage(message);
    }
    _messageController.clear();
  }

  Future<void> _sendMessage({ChatMediaUpload? media}) async {
    final text = _messageController.text.trim();
    if ((text.isEmpty && media == null) || _sending) return;

    setState(() => _sending = true);
    final pendingText = text;
    final optimistic = _buildOptimisticMessage(text: pendingText, media: media);
    _insertMessage(optimistic);
    if (media == null) _messageController.clear();

    try {
      await _performSend(
        text: pendingText,
        media: media,
        optimistic: optimistic,
      );
    } on ApiException catch (error) {
      _removeMessage(optimistic.id);
      if (media == null && mounted) {
        _messageController.text = pendingText;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      _removeMessage(optimistic.id);
      if (media == null && mounted) {
        _messageController.text = pendingText;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر إرسال الرسالة')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _uploadAndSend({
    required List<int> bytes,
    required String name,
    required String mimeType,
  }) async {
    if (_sending) return;

    final normalizedMime = UploadMime.normalizeChatMime(
      mimeType: mimeType,
      filename: name,
    );
    if (!UploadMime.isSupportedChatMime(normalizedMime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نوع الملف غير مدعوم')),
        );
      }
      return;
    }

    final media = ChatMediaUpload(
      key: 'pending',
      name: name,
      size: bytes.length,
      mimeType: normalizedMime,
    );
    final optimistic = _buildOptimisticMessage(text: '', media: media);

    setState(() => _sending = true);
    if (normalizedMime.startsWith('audio/')) {
      _localAudioBytes[optimistic.id] = Uint8List.fromList(bytes);
    }
    _insertMessage(optimistic);

    try {
      final presigned = await UploadApi.getPresignedUrlForFile(
        contentType: normalizedMime,
        filename: name,
      );
      await UploadApi.uploadBytes(
        url: presigned.url,
        bytes: bytes,
        contentType: normalizedMime,
      );

      await UploadApi.registerAttachmentUpload(presigned.key);

      final uploadedMedia = ChatMediaUpload(
        key: presigned.key,
        name: name,
        size: bytes.length,
        mimeType: normalizedMime,
      );

      _replaceMessage(
        optimistic.id,
        optimistic.copyWith(
          media: ChatMedia(
            id: optimistic.id,
            url: presigned.key,
            mimeType: normalizedMime,
            filename: name,
          ),
          isPending: true,
        ),
      );

      await _performSend(
        text: '',
        media: uploadedMedia,
        optimistic: optimistic,
      );
    } on ApiException catch (error) {
      _removeMessage(optimistic.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      _removeMessage(optimistic.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر رفع الملف')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    if (_sending) return;

    final picked = await pickWebFile(
      accept: 'image/*,application/pdf,video/*',
    );
    if (picked == null) return;

    final mimeType = UploadMime.normalizeChatMime(
      mimeType: picked.mimeType,
      filename: picked.name,
    );
    if (!UploadMime.isSupportedChatMime(mimeType)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نوع الملف غير مدعوم')),
        );
      }
      return;
    }
    await _uploadAndSend(
      bytes: picked.bytes,
      name: picked.name,
      mimeType: mimeType,
    );
  }

  Future<void> _startRecording() async {
    if (_recording || _sending) return;

    final recorder = createWebAudioRecorder();
    if (!recorder.isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('التسجيل الصوتي غير مدعوم على هذا الجهاز'),
          ),
        );
      }
      return;
    }

    final started = await recorder.start();
    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الوصول إلى الميكروفون')),
        );
      }
      return;
    }

    _recorder = recorder;
    setState(() {
      _recording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    _recorder?.cancel();
    _recorder = null;
    setState(() {
      _recording = false;
      _recordSeconds = 0;
    });
  }

  Future<void> _stopRecordingAndSend() async {
    final recorder = _recorder;
    if (recorder == null) return;
    _recordTimer?.cancel();

    final recorded = await recorder.stop();
    _recorder = null;
    setState(() => _recording = false);

    if (recorded == null) return;

    await _uploadAndSend(
      bytes: recorded.bytes,
      name: 'recording.${recorded.extension}',
      mimeType: recorded.mimeType,
    );
  }

  Future<void> _editMessage(ChatMessage message) async {
    if (message.isAudioMessage) return;

    final controller = TextEditingController(text: message.message);
    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: _maxMessageLength,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated == null || updated.isEmpty || updated == message.message) {
      return;
    }

    try {
      final saved = await ChatApi.editMessage(
        chatId: widget.chatId,
        messageId: message.id,
        message: updated,
      );
      _onLiveEdited(saved);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ChatApi.deleteMessage(
        chatId: widget.chatId,
        messageId: message.id,
      );
      _onLiveDeleted(message.id);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  _ChatUserDisplay _displayUserFor(ChatMessage message, bool isMine) {
    if (isMine) {
      return _ChatUserDisplay(
        name: _currentUser?.name ?? 'أنا',
        imageUrl: null,
        role: _currentUser?.role ?? 1,
      );
    }

    final teacher = widget.teacher;
    return _ChatUserDisplay(
      name: teacher?.name ?? 'المعلم',
      imageUrl: teacher?.imageUrl,
      role: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.coursePageBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(onClose: widget.onClose),
          Expanded(child: _buildMessages()),
          _ChatInputBar(
            controller: _messageController,
            focusNode: _focusNode,
            sending: _sending,
            recording: _recording,
            recordSeconds: _recordSeconds,
            onSend: () => _sendMessage(),
            onAttach: _pickAndUploadFile,
            onStartRecord: _startRecording,
            onStopRecord: _stopRecordingAndSend,
            onCancelRecord: _cancelRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: AppTypography.bodyLg),
            TextButton(
              onPressed: () => _loadMessages(reset: true),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'يمكنك كتابة سؤالك هنا',
          style: AppTypography.bodyLg.copyWith(color: AppTheme.muted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.base),
      itemCount: _messages.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_loadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final msgIndex = _loadingMore ? index - 1 : index;
        final message = _messages[msgIndex];
        final isMine = message.senderId == _currentUser?.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.base),
          child: Align(
            alignment: isMine
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: _ChatBubble(
              message: message,
              isMine: isMine,
              user: _displayUserFor(message, isMine),
              localAudioBytes: _localAudioBytes[message.id],
              onEdit: isMine && !message.isAudioMessage && !message.isPending
                  ? () => _editMessage(message)
                  : null,
              onDelete: isMine && !message.isPending
                  ? () => _deleteMessage(message)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _ChatUserDisplay {
  const _ChatUserDisplay({
    required this.name,
    required this.role,
    this.imageUrl,
  });

  final String name;
  final String? imageUrl;
  final int role;

  String get roleLabel => role == 2 ? 'معلم' : 'طالب';
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1.1, color: AppTheme.homeHeaderBorder),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        child: Row(
          children: [
            if (onClose != null)
              CustomButton.icon(
                onPressed: onClose,
                icon: Icons.close,
                height: 40,
                width: 40,
                borderRadius: AppRadius.borderMd,
                foregroundColor: AppColors.onDark.withValues(alpha: 0.95),
                variant: CustomButtonVariant.text,
              ),
            Expanded(
              child: Text(
                'أسألنى لايف',
                textAlign: TextAlign.center,
                style: AppTypography.size20.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.bold,
                ),
              ),
            ),
            if (onClose != null) const SizedBox(width: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.user,
    this.localAudioBytes,
    this.onEdit,
    this.onDelete,
  });

  final ChatMessage message;
  final bool isMine;
  final _ChatUserDisplay user;
  final Uint8List? localAudioBytes;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final media = message.media;

    return Opacity(
      opacity: message.isPending ? 0.72 : 1,
      child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mainBg3,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMine && (onEdit != null || onDelete != null))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: AppColors.tabInactive.withValues(alpha: 0.8),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      if (onDelete != null)
                        const PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChatAvatar(user: user),
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
                        const SizedBox(height: AppSpacing.xxs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: user.role == 2
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  )
                                : null,
                            color: user.role == 2 ? null : AppColors.mainBg,
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Text(
                            user.roleLabel,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onDark,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (message.message.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.mainBg,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Text(
                      message.message,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                ),
              ],
              if (media != null) ...[
                const SizedBox(height: AppSpacing.sm),
                if (media.mimeType.startsWith('image/'))
                  _ChatImageAttachment(url: media.resolvedUrl)
                else if (media.mimeType.startsWith('video/'))
                  _ChatVideoAttachment(url: media.resolvedUrl)
                else if (media.mimeType.startsWith('audio/'))
                  _ChatAudioAttachment(
                    url: media.resolvedUrl,
                    localBytes: localAudioBytes,
                    isPending: message.isPending,
                  )
                else if (media.mimeType == 'application/pdf')
                  _ChatPdfAttachment(url: media.resolvedUrl)
              ],
              if (message.createdAt.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text(
                    _formatChatDate(message.createdAt),
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.tabInactive,
                    ),
                  ),
                ),
              ],
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
    return DateFormat('dd MMM yyyy, hh:mm a', 'en').format(parsed.toLocal());
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.user});

  final _ChatUserDisplay user;

  @override
  Widget build(BuildContext context) {
    final imageUrl = user.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.mainBg,
      child: Icon(
        user.role == 2 ? Icons.school_outlined : Icons.person_outline,
        color: user.role == 2 ? const Color(0xFFEAB308) : AppColors.onDark,
      ),
    );
  }
}

class _ChatImageAttachment extends StatelessWidget {
  const _ChatImageAttachment({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          barrierColor: Colors.black87,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(AppSpacing.base),
            child: Stack(
              children: [
                InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}

class _ChatPdfAttachment extends StatelessWidget {
  const _ChatPdfAttachment({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mainBg,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: AppRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, color: AppColors.blue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'فتح في علامة تبويب جديدة',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.blue,
                    decoration: TextDecoration.underline,
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

class _ChatVideoAttachment extends StatefulWidget {
  const _ChatVideoAttachment({required this.url});

  final String url;

  @override
  State<_ChatVideoAttachment> createState() => _ChatVideoAttachmentState();
}

class _ChatVideoAttachmentState extends State<_ChatVideoAttachment> {
  late final VideoPlayerController _controller;
  var _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
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
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              IconButton(
                iconSize: 48,
                color: Colors.white70,
                onPressed: () => setState(() => _controller.play()),
                icon: const Icon(Icons.play_circle_outline),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.sending,
    required this.recording,
    required this.recordSeconds,
    this.onAttach,
    this.onStartRecord,
    this.onStopRecord,
    this.onCancelRecord,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onStartRecord;
  final VoidCallback? onStopRecord;
  final VoidCallback? onCancelRecord;
  final bool sending;
  final bool recording;
  final int recordSeconds;

  String get _timeLabel {
    final m = (recordSeconds ~/ 60).toString();
    final s = (recordSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: recording ? _buildRecordingRow() : _buildInputRow(),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        if (onAttach != null) ...[
          CustomButton.icon(
            onPressed: sending ? null : onAttach,
            icon: Icons.attach_file_rounded,
            height: 48,
            width: 48,
            borderRadius: BorderRadius.circular(AppRadius.full),
            variant: CustomButtonVariant.text,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !sending,
            maxLength: _maxMessageLength,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: 'اكتب سؤالك...',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        if (onStartRecord != null) ...[
          CustomButton.icon(
            onPressed: sending ? null : onStartRecord,
            icon: Icons.mic_none_rounded,
            height: 48,
            width: 48,
            borderRadius: BorderRadius.circular(AppRadius.full),
            variant: CustomButtonVariant.text,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        CustomButton.icon(
          onPressed: sending ? null : onSend,
          icon: sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
          height: 48,
          width: 48,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ],
    );
  }

  Widget _buildRecordingRow() {
    return Row(
      children: [
        CustomButton.icon(
          onPressed: onCancelRecord,
          icon: Icons.delete_outline_rounded,
          height: 48,
          width: 48,
          borderRadius: BorderRadius.circular(AppRadius.full),
          variant: CustomButtonVariant.text,
          foregroundColor: const Color(0xFFF87171),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Row(
            children: [
              const _RecordingDot(),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'جارٍ التسجيل  $_timeLabel',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onDark,
                  fontWeight: AppFonts.semibold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CustomButton.icon(
          onPressed: sending ? null : onStopRecord,
          icon: sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
          height: 48,
          width: 48,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ],
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.25).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChatAudioAttachment extends StatefulWidget {
  const _ChatAudioAttachment({
    required this.url,
    this.localBytes,
    this.isPending = false,
  });

  final String url;
  final Uint8List? localBytes;
  final bool isPending;

  @override
  State<_ChatAudioAttachment> createState() => _ChatAudioAttachmentState();
}

class _ChatAudioAttachmentState extends State<_ChatAudioAttachment> {
  final _player = AudioPlayer();
  var _playing = false;

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }

    setState(() => _playing = true);
    try {
      if (widget.localBytes != null) {
        await _player.play(BytesSource(widget.localBytes!));
      } else {
        await _player.play(UrlSource(widget.url));
      }
      await _player.onPlayerComplete.first;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تشغيل الصوت')),
        );
      }
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isPending
        ? (_playing ? 'إيقاف' : 'جارٍ الإرسال...')
        : (_playing ? 'إيقاف' : 'تشغيل الصوت');

    return Material(
      color: AppColors.mainBg,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: widget.isPending && widget.localBytes == null ? null : _toggle,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isPending && !_playing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _playing
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                  color: AppColors.blue,
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodySm.copyWith(color: AppColors.onDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
