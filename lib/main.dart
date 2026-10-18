import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/app.dart';
import 'package:school_platform/src/core/config/app_config.dart';
import 'package:school_platform/src/core/config/bootstrap_app.dart';
import 'package:school_platform/src/core/config/config_error_app.dart';
import 'package:school_platform/src/core/locale/locale_controller.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on AppConfigException catch (e) {
    runApp(ConfigErrorApp(problems: e.problems));
    return;
  }

  runApp(
    BootstrapApp(
      initialize: () async {
        final (supabase, preferences) = await (
          Supabase.initialize(
            url: config.supabaseUrl,
            publishableKey: config.supabasePublishableKey,
            debug: kDebugMode,
          ),
          SharedPreferencesWithCache.create(
            cacheOptions: const SharedPreferencesWithCacheOptions(
              allowList: PreferenceKeys.all,
            ),
          ),
        ).wait;

        return ProviderScope(
          // Failures are shown with an explicit "Try again" action instead of
          // silent automatic retries (permission errors would never succeed).
          retry: (_, _) => null,
          overrides: [
            appConfigProvider.overrideWithValue(config),
            supabaseClientProvider.overrideWithValue(supabase.client),
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: const SchoolPlatformApp(),
        );
      },
    ),
  );
}
