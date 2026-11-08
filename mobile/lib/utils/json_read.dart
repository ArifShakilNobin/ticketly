/// Tolerant readers used by every `fromJson` so a malformed payload degrades
/// to a sensible default instead of throwing at runtime.
library;

String? stringOrNull(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String stringOr(dynamic value, String fallback) =>
    stringOrNull(value) ?? fallback;

double? doubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

double doubleOr(dynamic value, double fallback) =>
    doubleOrNull(value) ?? fallback;

int? intOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

int intOr(dynamic value, int fallback) => intOrNull(value) ?? fallback;

bool boolOr(dynamic value, bool fallback) {
  if (value is bool) return value;
  return fallback;
}

List<String> stringList(dynamic value) {
  if (value is! List) return <String>[];
  final result = <String>[];
  for (final item in value) {
    final text = stringOrNull(item);
    if (text != null) result.add(text);
  }
  return result;
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value
        .map((dynamic key, dynamic item) =>
            MapEntry<String, dynamic>(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) =>
    value is List ? value : const <dynamic>[];

/// Parses `yyyy-MM-dd` or a full ISO timestamp into a local [DateTime].
DateTime? dateTimeOrNull(dynamic value) {
  if (value is! String) return null;
  final raw = value.trim();
  if (raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed?.toLocal();
}

/// Like [dateTimeOrNull] but always reduced to the date part. Used for values
/// the backend serialises as a `LocalDate`, e.g. `travelDate`.
DateTime? dateOrNull(dynamic value) {
  final parsed = dateTimeOrNull(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

/// Normalises `HH:mm`, `H:m` and `HH:mm:ss` into `HH:mm`.
String? timeOrNull(dynamic value) {
  if (value is! String) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.parse(match.group(1)!).toString().padLeft(2, '0');
  return '$hour:${match.group(2)!}';
}

/// Formats a date the way the backend expects it: `yyyy-MM-dd`.
String apiDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
