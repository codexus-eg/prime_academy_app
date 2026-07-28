import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

abstract class QuizReportPdfDeliverySession {
  Future<void> complete(List<int> bytes);
  void cancel();
}

class _ShareQuizReportPdfDeliverySession
    implements QuizReportPdfDeliverySession {
  _ShareQuizReportPdfDeliverySession(this.fileName);

  final String fileName;

  @override
  Future<void> complete(List<int> bytes) {
    return SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType: 'application/pdf',
          ),
        ],
        subject: 'تقرير الاختبار',
      ),
    );
  }

  @override
  void cancel() {}
}

QuizReportPdfDeliverySession startQuizReportPdfDelivery({
  required String fileName,
}) {
  return _ShareQuizReportPdfDeliverySession(fileName);
}
