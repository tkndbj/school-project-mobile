import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:school_platform/src/core/config/production_values.dart';

/// Compile-time configuration supplied with
/// `--dart-define-from-file=env/<environment>.json`.
///
/// Required backend values are validated; Google OAuth settings are optional.
/// [AppConfig.fromEnvironment] reports all missing or
/// malformed keys at once so a misconfigured build fails fast and clearly.
@immutable
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.googleWebClientId,
    required this.googleIosClientId,
    required this.webBaseUrl,
  });

  /// Reads and validates the configuration from `--dart-define` values.
  factory AppConfig.fromEnvironment() {
    return AppConfig.fromMap(const {
      supabaseUrlKey: String.fromEnvironment(supabaseUrlKey),
      supabasePublishableKeyKey: String.fromEnvironment(
        supabasePublishableKeyKey,
      ),
      googleWebClientIdKey: String.fromEnvironment(googleWebClientIdKey),
      googleIosClientIdKey: String.fromEnvironment(googleIosClientIdKey),
      webBaseUrlKey: String.fromEnvironment(webBaseUrlKey),
    });
  }

  /// Builds a configuration from raw values, throwing [AppConfigException]
  /// that lists every problem when the values are incomplete or invalid.
  factory AppConfig.fromMap(
    Map<String, String> values, {
    bool production = kReleaseMode,
  }) {
    final problems = <String>[];

    String required(String key) {
      final value = values[key]?.trim() ?? '';
      if (value.isEmpty) problems.add('$key is missing');
      return value;
    }

    String url(String key) {
      final value = required(key);
      if (value.isEmpty) return value;
      final uri = Uri.tryParse(value);
      if (uri == null ||
          !(uri.isScheme('http') || uri.isScheme('https')) ||
          uri.host.isEmpty) {
        problems.add('$key must be an http(s) URL');
      }
      return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
    }

    final config = AppConfig(
      supabaseUrl: url(supabaseUrlKey),
      supabasePublishableKey: required(supabasePublishableKeyKey),
      googleWebClientId: values[googleWebClientIdKey]?.trim() ?? '',
      googleIosClientId: values[googleIosClientIdKey]?.trim() ?? '',
      webBaseUrl: url(webBaseUrlKey),
    );

    if (config.supabasePublishableKey.startsWith('sb_secret_') ||
        _isServiceRoleJwt(config.supabasePublishableKey)) {
      problems.add('SUPABASE_PUBLISHABLE_KEY must not be a privileged key');
    }
    if (production) problems.addAll(validateProductionValues(values));
    if (problems.isNotEmpty) throw AppConfigException(problems);
    return config;
  }

  static const supabaseUrlKey = 'SUPABASE_URL';
  static const supabasePublishableKeyKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const googleWebClientIdKey = 'GOOGLE_WEB_CLIENT_ID';
  static const googleIosClientIdKey = 'GOOGLE_IOS_CLIENT_ID';
  static const webBaseUrlKey = 'WEB_BASE_URL';

  final String supabaseUrl;
  final String supabasePublishableKey;

  /// OAuth client id of the *web* application in Google Cloud. Used as the
  /// server client id so the ID token audience matches Supabase's Google
  /// provider configuration.
  final String googleWebClientId;

  /// OAuth client id of the iOS application in Google Cloud.
  final String googleIosClientId;

  /// Base URL of the web app (password reset pages, account deletion API).
  final String webBaseUrl;

  bool get googleSignInConfigured =>
      googleWebClientId.isNotEmpty &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          googleIosClientId.isNotEmpty);

  static bool _isServiceRoleJwt(String value) {
    // Legacy Supabase keys are JWTs. Never ship a service_role key in a client.
    final parts = value.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map<String, dynamic> &&
          payload['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}

/// Thrown when the build was produced without a valid configuration.
class AppConfigException implements Exception {
  const AppConfigException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'Invalid app configuration: ${problems.join('; ')}';
}
