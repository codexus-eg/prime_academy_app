import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> deliverCertificateImage({
  required Uint8List pngBytes,
  required String fileName,
  String? shareText,
}) async {
  final blob = web.Blob(
    [pngBytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);

  final printWindow = web.window.open('', '_blank');
  if (printWindow != null) {
    final doc = printWindow.document;
    doc.title = fileName;

    final style = doc.createElement('style') as web.HTMLStyleElement;
    style.textContent = '''
      body { margin: 0; background: transparent; display: flex; justify-content: center; }
      img { max-width: 100%; height: auto; }
      @media print {
        @page { margin: 0; size: auto; }
        body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      }
    ''';
    doc.head?.append(style);

    final img = doc.createElement('img') as web.HTMLImageElement;
    img.src = url;

    var printed = false;
    void tryPrint() {
      if (printed) return;
      printed = true;
      Future<void>.delayed(const Duration(milliseconds: 300)).then((_) {
        printWindow.print();
        printWindow.close();
        web.URL.revokeObjectURL(url);
      });
    }

    img.onload = ((web.Event _) => tryPrint()).toJS;
    doc.body?.append(img);
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
