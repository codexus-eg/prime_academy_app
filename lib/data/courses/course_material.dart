import '../../core/config/api_config.dart';

class CourseMaterialFileData {
  const CourseMaterialFileData({
    required this.filename,
    required this.url,
    this.mimeType,
    this.size,
  });

  final String filename;
  final String url;
  final String? mimeType;
  final int? size;

  factory CourseMaterialFileData.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'] as String? ?? '';
    return CourseMaterialFileData(
      filename: json['filename'] as String? ?? 'ملف',
      url: rawUrl.isEmpty ? '' : ApiConfig.mediaUrl(rawUrl),
      mimeType: json['mime_type'] as String?,
      size: json['size'] is int
          ? json['size'] as int
          : int.tryParse('${json['size']}'),
    );
  }
}

class CourseMaterial {
  const CourseMaterial({
    required this.id,
    required this.solved,
    required this.fileData,
  });

  final int id;
  final bool solved;
  final CourseMaterialFileData fileData;

  factory CourseMaterial.fromJson(Map<String, dynamic> json) {
    final fileDataRaw = json['fileData'];
    final fileData = fileDataRaw is Map<String, dynamic>
        ? CourseMaterialFileData.fromJson(fileDataRaw)
        : const CourseMaterialFileData(filename: 'ملف', url: '');

    return CourseMaterial(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      solved: json['solved'] == true,
      fileData: fileData,
    );
  }
}

class CourseMaterialsResponse {
  const CourseMaterialsResponse({
    required this.courseName,
    required this.files,
  });

  final String courseName;
  final List<CourseMaterial> files;

  factory CourseMaterialsResponse.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    final files = filesRaw is List
        ? filesRaw
            .whereType<Map<String, dynamic>>()
            .map(CourseMaterial.fromJson)
            .toList()
        : const <CourseMaterial>[];

    return CourseMaterialsResponse(
      courseName: json['course_name'] as String? ?? 'المذكرات',
      files: files,
    );
  }
}
