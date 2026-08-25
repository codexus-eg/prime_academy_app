import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'web_media_types.dart';

bool isWebFilePickerSupported() => true;

Future<PickedFile?> pickWebFile({required String accept}) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  input.click();

  await input.onChange.first;
  final file = input.files?.item(0);
  if (file == null) return null;

  final bytes = await _readBlob(file);
  return PickedFile(
    bytes: bytes,
    name: file.name,
    size: file.size,
    mimeType: file.type,
  );
}

WebAudioRecorder createWebAudioRecorder() => _WebAudioRecorder();

Future<Uint8List> _readBlob(web.Blob blob) async {
  final completer = Completer<Uint8List>();
  final reader = web.FileReader();
  reader.addEventListener(
    'loadend',
    ((web.Event _) {
      final result = reader.result;
      if (result != null) {
        final buffer = result as JSArrayBuffer;
        completer.complete(Uint8List.view(buffer.toDart));
      } else {
        completer.completeError(StateError('empty file'));
      }
    }).toJS,
  );
  reader.readAsArrayBuffer(blob);
  return completer.future;
}

bool _isIosBrowser() {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod');
}

class _WebAudioRecorder implements WebAudioRecorder {
  web.MediaRecorder? _recorder;
  final List<web.Blob> _chunks = [];
  String _mime = 'audio/webm';

  @override
  bool get isSupported => true;

  @override
  Future<bool> start() async {
    try {
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;

      _chunks.clear();
      final candidates = _isIosBrowser()
          ? ['audio/mp4', 'audio/webm', 'audio/ogg']
          : ['audio/webm', 'audio/ogg', 'audio/mp4'];
      _mime = candidates.firstWhere(
        (type) => web.MediaRecorder.isTypeSupported(type),
        orElse: () => '',
      );
      final recorder = _mime.isEmpty
          ? web.MediaRecorder(stream)
          : web.MediaRecorder(
              stream,
              web.MediaRecorderOptions(mimeType: _mime),
            );

      recorder.ondataavailable = ((web.BlobEvent event) {
        final data = event.data;
        if (data.size > 0) _chunks.add(data);
      }).toJS;
      recorder.start();

      _recorder = recorder;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> pause() async {
    final recorder = _recorder;
    if (recorder == null) return;
    try {
      if (recorder.state == 'recording') recorder.pause();
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    final recorder = _recorder;
    if (recorder == null) return;
    try {
      if (recorder.state == 'paused') recorder.resume();
    } catch (_) {}
  }

  @override
  void cancel() {
    _stopTracks();
    _chunks.clear();
    _recorder = null;
  }

  @override
  Future<RecordedAudio?> stop() async {
    final recorder = _recorder;
    if (recorder == null) return null;

    final completer = Completer<void>();
    recorder.onstop = ((web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;
    try {
      recorder.stop();
      recorder.stream.getTracks().toDart.forEach((t) => t.stop());
    } catch (_) {
      if (!completer.isCompleted) completer.complete();
    }
    await completer.future;

    _recorder = null;

    if (_chunks.isEmpty) return null;

    final recorderMime = recorder.mimeType.split(';').first.trim();
    final mime = recorderMime.isNotEmpty
        ? recorderMime
        : (_mime.isNotEmpty
            ? _mime
            : (_isIosBrowser() ? 'audio/mp4' : 'audio/webm'));
    final blob = web.Blob(
      _chunks.toJS,
      web.BlobPropertyBag(type: mime),
    );

    try {
      final bytes = await _readBlob(blob);
      final ext = mime.contains('ogg')
          ? 'ogg'
          : mime.contains('mp4')
              ? 'm4a'
              : 'webm';
      return RecordedAudio(bytes: bytes, mimeType: mime, extension: ext);
    } finally {
      _chunks.clear();
    }
  }

  @override
  void dispose() {
    _stopTracks();
  }

  void _stopTracks() {
    final recorder = _recorder;
    if (recorder == null) return;
    try {
      if (recorder.state != 'inactive') recorder.stop();
      recorder.stream.getTracks().toDart.forEach((t) => t.stop());
    } catch (_) {}
  }
}
