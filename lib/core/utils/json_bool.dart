/// Parses JSON / MySQL-style boolean values from API payloads.
///
/// Accepts `true`/`false`, `1`/`0`, and common string forms so TINYINT(1)
/// fields (e.g. `mark_all_answers_correct`) are not lost when the backend
/// serializes them as numbers.
bool parseApiBool(dynamic value, {bool fallback = false}) {
  if (value == true || value == 1) return true;
  if (value == false || value == 0) return false;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}
