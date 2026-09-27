import 'dart:math';

typedef Json = Map<String, Object?>;

String newUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

void requireUuid(String value, String field) {
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(value)) {
    throw FormatException('$field must be a canonical lowercase UUID.');
  }
}

void requireText(String value, String field, {int max = 4096}) {
  if (value.trim().isEmpty || value.length > max)
    throw FormatException('$field must contain 1–$max characters.');
}

void requirePositive(num value, String field, {bool zero = false}) {
  if (!value.isFinite || (zero ? value < 0 : value <= 0))
    throw FormatException(
      '$field must be ${zero ? 'nonnegative' : 'positive'} and finite.',
    );
}

Json asJson(Object? value, [String field = 'object']) {
  if (value is! Map<String, Object?>)
    throw FormatException('$field must be an object.');
  return value;
}

String stringField(Json json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('$key must be a string.');
  return value;
}

int intField(Json json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

double doubleField(Json json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite)
    throw FormatException('$key must be a finite number.');
  return value.toDouble();
}

DateTime dateField(Json json, String key) {
  final text = stringField(json, key);
  final parsed = DateTime.tryParse(text);
  if (parsed == null || !parsed.isUtc)
    throw FormatException('$key must be an ISO-8601 timestamp with timezone.');
  return parsed;
}

List<T> listField<T>(Json json, String key, T Function(Object?) parse) {
  final value = json[key];
  if (value is! List<Object?>) throw FormatException('$key must be an array.');
  return value.map(parse).toList();
}

String wireName(Enum value) => value.name.replaceAllMapped(
  RegExp('[A-Z]'),
  (m) => '_${m[0]!.toLowerCase()}',
);
T enumField<T extends Enum>(Json json, String key, List<T> values) {
  final value = stringField(json, key);
  for (final candidate in values) {
    if (wireName(candidate) == value) return candidate;
  }
  throw FormatException(
    '$key must be one of: ${values.map(wireName).join(', ')}.',
  );
}

Object? freezeJson(Object? value) {
  if (value == null ||
      value is String ||
      value is bool ||
      value is num && value.isFinite)
    return value;
  if (value is List<Object?>)
    return List<Object?>.unmodifiable(value.map(freezeJson));
  if (value is Map<String, Object?>)
    return Map<String, Object?>.unmodifiable(
      value.map((k, v) => MapEntry(k, freezeJson(v))),
    );
  throw const FormatException('Document contains an unsupported JSON value.');
}
