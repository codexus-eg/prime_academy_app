import '../../core/config/api_config.dart';

class ModuleMaterial {
  const ModuleMaterial({
    required this.id,
    required this.filename,
    required this.url,
    required this.accessWithoutEnrollment,
    this.createdAt,
  });

  final int id;
  final String filename;

  final String url;
  final bool accessWithoutEnrollment;
  final DateTime? createdAt;

  factory ModuleMaterial.fromJson(Map<String, dynamic> json) {
    final fileData = json['fileData'];
    final rawUrl =
        fileData is Map<String, dynamic> ? (fileData['url'] as String? ?? '') : '';
    final filename = fileData is Map<String, dynamic>
        ? (fileData['filename'] as String? ?? 'ملف')
        : 'ملف';

    return ModuleMaterial(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      filename: filename,
      url: rawUrl.isEmpty ? '' : ApiConfig.mediaUrl(rawUrl),
      accessWithoutEnrollment: json['access_without_enrollment'] == true,
      createdAt: DateTime.tryParse('${json['created_at']}'),
    );
  }
}
