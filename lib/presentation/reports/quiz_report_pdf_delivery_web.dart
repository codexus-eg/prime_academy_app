import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

abstract class QuizReportPdfDeliverySession {
  Future<void> complete(List<int> bytes);
  void cancel();
}

class _WebQuizReportPdfDeliverySession implements QuizReportPdfDeliverySession {
  _WebQuizReportPdfDeliverySession(this.fileName, this._tab);

  final String fileName;
  final web.Window? _tab;

  @override
  Future<void> complete(List<int> bytes) async {
    final blob = web.Blob(
      [Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);

    if (_tab != null) {
      _tab.location.href = url;
      return;
    }

    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  @override
  void cancel() {
    _tab?.close();
  }
}

QuizReportPdfDeliverySession startQuizReportPdfDelivery({
  required String fileName,
}) {
  final tab = web.window.open('', '_blank');
  if (tab != null) {
    tab.document.title = 'جاري تحميل النتائج';
    tab.document.documentElement?.setAttribute('dir', 'rtl');
    tab.document.documentElement?.setAttribute('lang', 'ar');
    final body = tab.document.body;
    if (body != null) {
      body.style.margin = '0';
      body.style.backgroundColor = '#0f1217';
      body.style.color = '#e5e7eb';
      body.style.fontFamily = "'Segoe UI', Tahoma, sans-serif";
      body.style.display = 'flex';
      body.style.alignItems = 'center';
      body.style.justifyContent = 'center';
      body.style.minHeight = '100vh';
      body.textContent = 'جاري تحميل النتائج...';
    }
  }

  return _WebQuizReportPdfDeliverySession(fileName, tab);
}
