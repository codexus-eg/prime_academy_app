import 'dart:js_interop';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import 'material_download_result.dart';

/// Web: fetch → blob → `<a download>` (browser Downloads folder).
Future<MaterialDownloadResult> downloadMaterialFile({
  required String url,
  required String fileName,
}) async {
  if (url.isEmpty) {
    throw MaterialDownloadException('رابط الملف غير صالح');
  }

  final response = await http.get(Uri.parse(url));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw MaterialDownloadException(
      'تعذّر تنزيل الملف (${response.statusCode})',
    );
  }

  final bytes = response.bodyBytes;
  final mime = response.headers['content-type'] ?? 'application/octet-stream';
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final safeName = fileName.trim().isEmpty ? 'material.pdf' : fileName.trim();
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = safeName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(objectUrl);

  return MaterialDownloadResult(
    savedPath: safeName,
    folderPath: 'Downloads',
  );
}
