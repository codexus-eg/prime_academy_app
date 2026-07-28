import 'package:http/http.dart' as http;

String resolvePresignedUploadUrl(String presignedUrl) => presignedUrl;

Future<int?> putPresignedBytes({
  required String url,
  required List<int> bytes,
  required String contentType,
}) async {
  final response = await http.put(
    Uri.parse(url),
    headers: {'Content-Type': contentType},
    body: bytes,
  );
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return null;
  }
  return response.statusCode;
}
