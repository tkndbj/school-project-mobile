/// Display name for a person record where every part is optional.
String? personName({
  String? first,
  String? last,
  String? preferred,
  String? title,
}) {
  final given = (preferred?.trim().isNotEmpty ?? false) ? preferred : first;
  final parts = [
    title,
    given,
    last,
  ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
  final name = parts.join(' ');
  return name.isEmpty ? null : name;
}

/// `null` for blank input, otherwise the trimmed value.
String? blankToNull(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Mirrors the database `email_address` domain check.
bool isValidEmail(String value) =>
    value.length <= 320 && _emailPattern.hasMatch(value.trim());
