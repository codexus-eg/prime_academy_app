import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../../core/config/api_config.dart';

String resolvePresignedUploadUrl(String presignedUrl) {
  if (kDebugMode) {
    return '${ApiConfig.webDevProxyOrigin}/r2-put?url=${Uri.encodeComponent(presignedUrl)}';
  }
  return presignedUrl;
}

Future<int?> putPresignedBytes({
  required String url,
  required List<int> bytes,
  required String contentType,
}) async {
  final uploadUrl = resolvePresignedUploadUrl(url);

  try {
    final response = await web.window
        .fetch(
          uploadUrl.toJS,
          web.RequestInit(
            method: 'PUT',
            headers: {'Content-Type': contentType}.jsify()! as web.HeadersInit,
            body: Uint8List.fromList(bytes).toJS,
          ),
        )
        .toDart;

    if (response.status >= 200 && response.status < 300) {
      return null;
    }
    return response.status;
  } catch (_) {
    return -1;
  }
}
