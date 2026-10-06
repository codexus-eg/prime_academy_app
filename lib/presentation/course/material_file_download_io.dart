import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'material_download_result.dart';

const _primeAcademyFolderName = 'prime academy';

/// Mobile/desktop: download into `prime academy` folder and return the saved path.
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

  final bytes = Uint8List.fromList(response.bodyBytes);
  final safeName = _sanitizeFileName(fileName);

  await _ensureStoragePermissionIfNeeded();

  final folder = await _resolvePrimeAcademyFolder();
  final target = await _uniqueFile(folder, safeName);
  await target.writeAsBytes(bytes, flush: true);

  if (!await target.exists() || await target.length() <= 0) {
    throw MaterialDownloadException('فشل حفظ الملف على الجهاز');
  }

  return MaterialDownloadResult(
    savedPath: target.path,
    folderPath: folder.path,
  );
}

Future<void> _ensureStoragePermissionIfNeeded() async {
  if (!Platform.isAndroid) return;

  // Needed when writing / opening public Download/prime academy on older Android.
  final storage = await Permission.storage.status;
  if (storage.isGranted || storage.isLimited) return;

  if (storage.isDenied || storage.isRestricted) {
    await Permission.storage.request();
  }
}

Future<Directory> _resolvePrimeAcademyFolder() async {
  final candidates = <Directory>[];

  // Prefer public Download so "فتح المجلد" can hand off to the system Files app.
  if (Platform.isAndroid) {
    candidates.add(
      Directory('/storage/emulated/0/Download/$_primeAcademyFolderName'),
    );
  }

  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      candidates.add(Directory('${downloads.path}/$_primeAcademyFolderName'));
    }
  } catch (_) {}

  if (Platform.isAndroid) {
    try {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        candidates.add(Directory('${external.path}/$_primeAcademyFolderName'));
      }
    } catch (_) {}
  }

  final docs = await getApplicationDocumentsDirectory();
  candidates.add(Directory('${docs.path}/$_primeAcademyFolderName'));

  Object? lastError;
  for (final dir in candidates) {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final probe = File(
        '${dir.path}/.prime_academy_write_${DateTime.now().millisecondsSinceEpoch}',
      );
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return dir;
    } catch (e) {
      lastError = e;
    }
  }

  throw MaterialDownloadException(
    'تعذّر إنشاء مجلد "$_primeAcademyFolderName". ${lastError ?? ''}'.trim(),
  );
}

Future<File> _uniqueFile(Directory folder, String fileName) async {
  var file = File('${folder.path}/$fileName');
  if (!await file.exists()) return file;

  final dot = fileName.lastIndexOf('.');
  final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
  final ext = dot > 0 ? fileName.substring(dot) : '';

  for (var i = 1; i < 1000; i++) {
    file = File('${folder.path}/$stem ($i)$ext');
    if (!await file.exists()) return file;
  }
  return File(
    '${folder.path}/${stem}_${DateTime.now().millisecondsSinceEpoch}$ext',
  );
}

String _sanitizeFileName(String fileName) {
  var name = fileName.trim();
  if (name.isEmpty) name = 'material.pdf';
  name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  if (!name.contains('.')) name = '$name.pdf';
  return name;
}
