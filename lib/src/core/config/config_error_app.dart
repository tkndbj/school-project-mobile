import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shown instead of the app when the build has no valid configuration.
///
/// Deliberately not localized and dependency-free: it must render even when
/// nothing else could be initialised.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.problems, super.key});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  kReleaseMode
                      ? 'App unavailable'
                      : 'App configuration is missing',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (kReleaseMode)
                  const Text(
                    'This version could not start. Please contact your school.',
                  ),
                if (!kReleaseMode)
                  const Text(
                    'Run the app with --dart-define-from-file=env/dev.json '
                    '(see env/example.json and README.md).',
                  ),
                const SizedBox(height: 16),
                if (!kReleaseMode)
                  for (final problem in problems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $problem'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
