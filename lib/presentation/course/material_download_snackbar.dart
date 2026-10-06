import 'package:flutter/material.dart';

import 'material_download_open.dart';
import 'material_download_result.dart';

void showMaterialDownloadSuccessSnackBar(
  BuildContext context,
  MaterialDownloadResult result,
) {
  final messenger = ScaffoldMessenger.of(context);
  final showOpen = canOpenMaterialDownloadLocation &&
      result.folderPath.isNotEmpty &&
      result.folderPath != 'Downloads';

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 8),
      content: const Text('تم التحميل'),
      action: showOpen
          ? SnackBarAction(
              label: 'فتح المجلد',
              onPressed: () async {
                final opened = await openMaterialDownloadLocation(result);
                if (opened) return;
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تعذّر فتح المجلد. جرّب Files → Download → prime academy، أو تحقق من صلاحيات التخزين.',
                    ),
                    duration: Duration(seconds: 6),
                  ),
                );
              },
            )
          : null,
    ),
  );
}
