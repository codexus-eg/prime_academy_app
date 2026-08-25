import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/web/web_media.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'lesson_aside_title_header.dart';
import 'lesson_chat_ui.dart';
import '../../../data/auth/auth_session.dart';
import '../../../data/courses/user_course.dart';
import '../../../data/sse/sse_service.dart';
import '../../../data/chat/chat_models.dart';
import '../../../data/upload/upload_api.dart';
import '../../../data/upload/upload_mime.dart';

const _pageSize = 20;

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
  var _paused = false;
  var _recordSeconds = 0;
  RecordedAudio? _recordedAudio;
  Timer? _recordTimer;
  Timer? _pollTimer;
  var _optimisticId = -1;
  final _localAudioBytes = <int, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(_onScroll);
    if (widget.chatId > 0) {
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
  }

  @override
  void dispose() {
    if (widget.chatId > 0) {
      ChatLiveHub.instance.unsubscribe(widget.chatId);
    }
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
    if (widget.chatId <= 0) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _hasMore = false;
      });
      return;
    }
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
    _recordedAudio = null;
    setState(() {
      _recording = true;
      _paused = false;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_paused) setState(() => _recordSeconds++);
    });
  }

  Future<void> _pauseRecording() async {
    await _recorder?.pause();
    if (mounted) setState(() => _paused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder?.resume();
    if (mounted) setState(() => _paused = false);
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    _recorder?.cancel();
    _recorder = null;
    setState(() {
      _recording = false;
      _paused = false;
      _recordSeconds = 0;
      _recordedAudio = null;
    });
  }

  Future<void> _stopRecordingToPreview() async {
    final recorder = _recorder;
    if (recorder == null) return;
    _recordTimer?.cancel();

    final recorded = await recorder.stop();
    _recorder = null;
    if (!mounted) return;
    setState(() {
      _recording = false;
      _paused = false;
      _recordedAudio = recorded;
    });
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopRecordingToPreview();
    } else {
      await _startRecording();
    }
  }

  Future<void> _sendComposer() async {
    if (_sending) return;
    if (_recording) {
      await _stopRecordingToPreview();
    }
    final recorded = _recordedAudio;
    if (recorded != null) {
      setState(() => _recordedAudio = null);
      await _uploadAndSend(
        bytes: recorded.bytes,
        name: 'recording.${recorded.extension}',
        mimeType: recorded.mimeType,
      );
      return;
    }
    await _sendMessage();
  }

  Future<void> _editMessage(ChatMessage message) async {
    if (message.isAudioMessage) return;

    final controller = TextEditingController(text: message.message);
    final updated = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => LessonEditMessageDialog(controller: controller),
    );
    controller.dispose();
    if (updated == null || updated == message.message) return;
    if (updated.isEmpty && message.media == null) return;

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

  LessonChatUser _displayUserFor(ChatMessage message, bool isMine) {
    if (isMine) {
      return LessonChatUser(
        name: _currentUser?.name ?? 'أنا',
        imageUrl: null,
        role: _currentUser?.role ?? 1,
      );
    }

    final teacher = widget.teacher;
    return LessonChatUser(
      name: teacher?.name ?? 'المعلم',
      imageUrl: teacher?.imageUrl,
      role: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LessonAsideShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonAsideTitleHeader(
            title: 'اسألني لايف',
            onClose: widget.onClose,
          ),
          const SizedBox(height: AppSpacing.lessonAsideInnerGap),
          Expanded(child: _buildMessages()),
          const SizedBox(height: AppSpacing.lessonAsideInnerGap),
          LessonChatInputBar(
            controller: _messageController,
            focusNode: _focusNode,
            sending: _sending,
            recording: _recording,
            paused: _paused,
            hasPreview: _recordedAudio != null,
            recordSeconds: _recordSeconds,
            onSend: _sendComposer,
            onAttach: _pickAndUploadFile,
            onToggleRecord: _toggleRecording,
            onPauseRecord: _pauseRecording,
            onResumeRecord: _resumeRecording,
            onCancelRecord: _cancelRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.accentIconMuted,
            ),
          ),
        ),
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
      return ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 24,
        ),
        children: [
          Text(
            'يمكنك كتابة سؤالك هنا',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLg.copyWith(color: AppColors.gray300),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      itemCount: _messages.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppSpacing.lessonChatMessageGap),
      itemBuilder: (context, index) {
        if (_loadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentIconMuted,
                ),
              ),
            ),
          );
        }

        final msgIndex = _loadingMore ? index - 1 : index;
        final message = _messages[msgIndex];
        final isMine = message.senderId == _currentUser?.id;

        return Align(
          alignment: isMine
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: LessonChatBubble(
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
        );
      },
    );
  }
}
