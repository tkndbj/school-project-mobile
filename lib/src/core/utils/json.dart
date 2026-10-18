/// Strictly typed accessors for JSON returned by PostgREST.
///
/// Models parse their JSON through these helpers so a contract change in the
/// database fails loudly (a [FormatException] naming the key) instead of
/// producing silently wrong data.
typedef Json = Map<String, dynamic>;

extension JsonRead on Json {
  String requireString(String key) {
    final value = this[key];
    if (value is String) return value;
    throw FormatException('Expected string for "$key", got $value');
  }

  String? optString(String key) {
    final value = this[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('Expected string for "$key", got $value');
  }

  int requireInt(String key) {
    final value = this[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected int for "$key", got $value');
  }

  int? optInt(String key) => this[key] == null ? null : requireInt(key);

  /// Postgres `numeric` values arrive as JSON numbers (or strings for very
  /// large values).
  double? optDouble(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected number for "$key", got $value');
  }

  bool requireBool(String key) {
    final value = this[key];
    if (value is bool) return value;
    throw FormatException('Expected bool for "$key", got $value');
  }

  bool? optBool(String key) => this[key] == null ? null : requireBool(key);

  /// `timestamptz` → local [DateTime].
  DateTime requireDateTime(String key) =>
      DateTime.parse(requireString(key)).toLocal();

  DateTime? optDateTime(String key) =>
      this[key] == null ? null : requireDateTime(key);

  /// Postgres `date` (YYYY-MM-DD) → [DateTime] at local midnight.
  DateTime? optDate(String key) {
    final value = optString(key);
    if (value == null) return null;
    final parsed = DateTime.parse(value);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Json? optObject(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is Map) return value.cast<String, dynamic>();
    throw FormatException('Expected object for "$key", got $value');
  }

  List<Json> optObjectList(String key) {
    final value = this[key];
    if (value == null) return const [];
    if (value is List) {
      return [for (final item in value) (item as Map).cast<String, dynamic>()];
    }
    throw FormatException('Expected list for "$key", got $value');
  }

  List<String> optStringList(String key) {
    final value = this[key];
    if (value == null) return const [];
    if (value is List) return [for (final item in value) item as String];
    throw FormatException('Expected list for "$key", got $value');
  }
}

/// Parses a list of JSON objects returned by `select()` or a set-returning RPC.
List<T> parseList<T>(Object? data, T Function(Json json) fromJson) {
  if (data is! List) {
    throw FormatException('Expected a JSON list, got ${data.runtimeType}');
  }
  return [for (final item in data) fromJson((item as Map).cast())];
}
