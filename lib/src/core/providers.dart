import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:school_platform/src/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Root dependencies. They are created during bootstrap (see main.dart) and
// injected with ProviderScope overrides, which also makes them trivially
// replaceable in tests.

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) =>
      throw UnimplementedError('supabaseClientProvider must be overridden'),
);

final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
