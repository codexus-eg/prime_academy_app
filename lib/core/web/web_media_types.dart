import 'dart:typed_data';

class PickedFile {
  const PickedFile({
    required this.bytes,
    required this.name,
    required this.size,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String name;
  final int size;
  final String mimeType;
}

class RecordedAudio {
  const RecordedAudio({
    required this.bytes,
    required this.mimeType,
    required this.extension,
  });

  final Uint8List bytes;
  final String mimeType;
  final String extension;
}

abstract class WebAudioRecorder {
  bool get isSupported;

  Future<bool> start();

  Future<void> pause();

  Future<void> resume();

  void cancel();

  Future<RecordedAudio?> stop();

  void dispose();
}
