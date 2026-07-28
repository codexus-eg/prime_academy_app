abstract final class UploadMime {
  static const supportedChatMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
    'video/mp4',
    'video/x-matroska',
    'audio/webm',
    'audio/ogg',
    'audio/mp4',
  };

  static String normalizeChatMime({
    required String mimeType,
    required String filename,
  }) {
    final trimmed = mimeType.split(';').first.trim().toLowerCase();
    if (trimmed.isNotEmpty && trimmed != 'application/octet-stream') {
      return _mapKnownAliases(trimmed);
    }
    return _mimeFromFilename(filename);
  }

  static String normalizeProfileImageMime({
    required String mimeType,
    required String filename,
  }) {
    var normalized = normalizeChatMime(
      mimeType: mimeType,
      filename: filename,
    );
    if (normalized == 'image/heic' || normalized == 'image/heif') {
      normalized = 'image/jpeg';
    }
    return normalized;
  }

  static bool isSupportedProfileImageMime(String mimeType) =>
      supportedProfileImageMimeTypes.contains(mimeType);

  static const supportedProfileImageMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static bool isSupportedChatMime(String mimeType) =>
      supportedChatMimeTypes.contains(mimeType);

  static String mapKnownAliases(String mimeType) => _mapKnownAliases(mimeType);

  static String _mapKnownAliases(String mimeType) {
    switch (mimeType) {
      case 'image/jpg':
        return 'image/jpeg';
      case 'video/quicktime':
        return 'video/mp4';
      case 'video/webm':
        return 'video/x-matroska';
      default:
        return mimeType;
    }
  }

  static String _mimeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/x-matroska';
    if (lower.endsWith('.mkv')) return 'video/x-matroska';
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.ogg')) return 'audio/ogg';
    return 'image/jpeg';
  }
}
