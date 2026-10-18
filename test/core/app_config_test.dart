import 'package:flutter_test/flutter_test.dart';
import 'package:school_platform/src/core/config/app_config.dart';

void main() {
  test('production rejects local URLs and placeholder keys', () {
    expect(
      () => AppConfig.fromMap(const {
        'SUPABASE_URL': 'http://127.0.0.1:54321',
        'WEB_BASE_URL': 'https://school.example.com',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_xxxxxxxxxxxxxxxxxxxx',
      }, production: true),
      throwsA(
        isA<AppConfigException>().having(
          (error) => error.problems.length,
          'production problems',
          3,
        ),
      ),
    );
  });
  const valid = {
    'SUPABASE_URL': 'https://abc.supabase.co/',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_123',
    'GOOGLE_WEB_CLIENT_ID': 'web.apps.googleusercontent.com',
    'GOOGLE_IOS_CLIENT_ID': 'ios.apps.googleusercontent.com',
    'WEB_BASE_URL': 'https://school.example.com',
  };

  test('parses a complete configuration and trims trailing slashes', () {
    final config = AppConfig.fromMap(valid);
    expect(config.supabaseUrl, 'https://abc.supabase.co');
    expect(config.webBaseUrl, 'https://school.example.com');
    expect(config.googleWebClientId, 'web.apps.googleusercontent.com');
  });

  test('reports every missing or invalid value at once', () {
    expect(
      // Not const: later entries intentionally override the spread values.
      // ignore: prefer_const_literals_to_create_immutables
      () => AppConfig.fromMap({
        ...valid,
        'SUPABASE_URL': 'not a url',
        'WEB_BASE_URL': 'not a url',
      }),
      throwsA(
        isA<AppConfigException>().having(
          (e) => e.problems,
          'problems',
          [
            'SUPABASE_URL must be an http(s) URL',
            'WEB_BASE_URL must be an http(s) URL',
          ],
        ),
      ),
    );
  });

  test('fromEnvironment fails when no dart-defines were supplied', () {
    expect(AppConfig.fromEnvironment, throwsA(isA<AppConfigException>()));
  });

  test('password sign-in does not require Google configuration', () {
    final values = Map<String, String>.of(valid)
      ..['GOOGLE_WEB_CLIENT_ID'] = ''
      ..['GOOGLE_IOS_CLIENT_ID'] = '';
    final config = AppConfig.fromMap(values);
    expect(config.googleSignInConfigured, isFalse);
  });

  test('rejects a secret key in the client configuration', () {
    final values = Map<String, String>.of(valid)
      ..['SUPABASE_PUBLISHABLE_KEY'] = 'sb_secret_do_not_ship';
    expect(
      () => AppConfig.fromMap(values),
      throwsA(isA<AppConfigException>()),
    );
  });
}
