import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'web_media_types.dart';

bool isWebFilePickerSupported() => true;

Future<PickedFile?> pickWebFile({required String accept}) async {
  final lowerAccept = accept.toLowerCase();

  if (lowerAccept.contains('image/') && !lowerAccept.contains('pdf')) {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty ? file.name : 'image.jpg';
    return PickedFile(
      bytes: bytes,
      name: name,
      size: bytes.length,
      mimeType: _mimeFromName(name),
    );
  }

  if (lowerAccept.contains('pdf') || lowerAccept.contains('video/')) {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: lowerAccept.contains('pdf')
          ? ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'webm']
          : ['mp4', 'mov', 'webm', 'mkv', 'pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    final name = file.name.isNotEmpty ? file.name : 'attachment';
    return PickedFile(
      bytes: bytes,
      name: name,
      size: bytes.length,
      mimeType: _mimeFromName(name),
    );
  }

  final result = await FilePicker.platform.pickFiles(
    type: lowerAccept.contains('pdf') ? FileType.custom : FileType.any,
    allowedExtensions:
        lowerAccept.contains('pdf') ? ['pdf', 'jpg', 'jpeg', 'png', 'webp'] : null,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) return null;
  final name = file.name.isNotEmpty ? file.name : 'attachment';
  return PickedFile(
    bytes: bytes,
    name: name,
    size: bytes.length,
    mimeType: _mimeFromName(name),
  );
}

String _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.mp4')) return 'video/mp4';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.mkv')) return 'video/x-matroska';
  if (lower.endsWith('.mp3')) return 'audio/mpeg';
  if (lower.endsWith('.m4a')) return 'audio/mp4';
  if (lower.endsWith('.wav')) return 'audio/wav';
  if (lower.endsWith('.aac')) return 'audio/aac';
  return 'image/jpeg';
}

WebAudioRecorder createWebAudioRecorder() => _MobileAudioRecorder();

class _MobileAudioRecorder implements WebAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  String? _path;

  @override
  bool get isSupported => true;

  @override
  Future<bool> start() async {
    if (await _recorder.isRecording()) return false;

    final permitted = await _recorder.hasPermission();
    if (!permitted) return false;

    final dir = await getTemporaryDirectory();
    _path =
        '${dir.path}/chat_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _path!,
    );
    return true;
  }

  @override
  void cancel() {
    unawaited(_discardRecording());
  }

  Future<void> _discardRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}

    final path = _path;
    _path = null;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  @override
  Future<RecordedAudio?> stop() async {
    if (!await _recorder.isRecording()) return null;

    final path = await _recorder.stop();
    final filePath = path ?? _path;
    _path = null;
    if (filePath == null) return null;

    final file = File(filePath);
    if (!await file.exists()) return null;

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return RecordedAudio(
        bytes: bytes,
        mimeType: 'audio/mp4',
        extension: 'm4a',
      );
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    unawaited(_discardRecording());
    unawaited(_recorder.dispose());
  }
}
