import 'dart:convert';

/// Shared by the app and release tooling; contains no Flutter dependencies.
List<String> validateProductionValues(Map<String, String> values) {
  final problems = <String>[];
  for (final key in ['SUPABASE_URL', 'WEB_BASE_URL']) {
    final uri = Uri.tryParse(values[key]?.trim() ?? '');
    if (uri == null ||
        !uri.isScheme('https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        ['localhost', '127.0.0.1', '::1'].contains(uri.host) ||
        uri.host.endsWith('.example') ||
        uri.host.endsWith('.example.com')) {
      problems.add('$key requires a real public HTTPS origin');
    }
  }
  final key = values['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
  var public = key.startsWith('sb_publishable_') && key.length >= 20;
  if (!public) {
    try {
      final payload = jsonDecode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(key.split('.')[1]),
          ),
        ),
      );
      public = payload is Map<String, dynamic> && payload['role'] == 'anon';
    } on Object {
      public = false;
    }
  }
  if (!public ||
      RegExp('placeholder|xxxx', caseSensitive: false).hasMatch(key)) {
    problems.add('SUPABASE_PUBLISHABLE_KEY requires a real public key');
  }
  for (final name in ['GOOGLE_WEB_CLIENT_ID', 'GOOGLE_IOS_CLIENT_ID']) {
    final value = values[name]?.trim() ?? '';
    if (value.isNotEmpty &&
        (!value.endsWith('.apps.googleusercontent.com') ||
            value.contains('xxxx'))) {
      problems.add('$name must be configured or omitted');
    }
  }
  return problems;
}
