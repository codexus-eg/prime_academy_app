import 'material_download_result.dart';

/// Web browsers manage Downloads themselves; folder open is not supported.
Future<bool> openMaterialDownloadLocation(MaterialDownloadResult result) async {
  return false;
}

bool get canOpenMaterialDownloadLocation => false;
