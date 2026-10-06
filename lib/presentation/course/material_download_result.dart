class MaterialDownloadResult {
  const MaterialDownloadResult({
    required this.savedPath,
    required this.folderPath,
  });

  /// Full path of the saved file (or browser download name on web).
  final String savedPath;

  /// Folder that contains the file (`…/prime academy`).
  final String folderPath;
}

class MaterialDownloadException implements Exception {
  MaterialDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}
