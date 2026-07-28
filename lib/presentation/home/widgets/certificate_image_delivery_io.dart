import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> deliverCertificateImage({
  required Uint8List pngBytes,
  required String fileName,
  String? shareText,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(pngBytes);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      text: shareText,
    ),
  );
}
