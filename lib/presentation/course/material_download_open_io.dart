import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import 'material_download_result.dart';

const _filesChannel = MethodChannel('prime.academy/files');

/// Opens the download folder when the OS allows it; otherwise opens the file.
Future<bool> openMaterialDownloadLocation(MaterialDownloadResult result) async {
  final folder = result.folderPath.trim();
  final filePath = result.savedPath.trim();
  if (folder.isEmpty || folder == 'Downloads') return false;

  try {
    if (Platform.isMacOS) {
      final r = await Process.run('open', [folder]);
      if (r.exitCode == 0) return true;
      if (filePath.isNotEmpty) {
        final fileResult = await Process.run('open', ['-R', filePath]);
        return fileResult.exitCode == 0;
      }
      return false;
    }
    if (Platform.isWindows) {
      final r = await Process.run('explorer', [folder]);
      return r.exitCode == 0;
    }
    if (Platform.isLinux) {
      final r = await Process.run('xdg-open', [folder]);
      return r.exitCode == 0;
    }

    if (Platform.isAndroid) {
      final storage = await Permission.storage.status;
      if (storage.isDenied || storage.isRestricted) {
        await Permission.storage.request();
      }

      try {
        final opened = await _filesChannel.invokeMethod<bool>(
          'openFolder',
          <String, dynamic>{'path': folder},
        );
        if (opened == true) return true;
      } on PlatformException {
        // Fall through to open the saved file.
      }

      if (filePath.isEmpty) return false;
      final openResult = await OpenFilex.open(filePath);
      return openResult.type == ResultType.done;
    }

    if (Platform.isIOS) {
      if (filePath.isEmpty) return false;
      // iOS cannot deep-link into Files for an app folder; open the file instead.
      final openResult = await OpenFilex.open(filePath);
      return openResult.type == ResultType.done;
    }
  } catch (_) {}

  return false;
}

bool get canOpenMaterialDownloadLocation => true;
