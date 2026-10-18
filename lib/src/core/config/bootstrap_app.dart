import 'package:flutter/material.dart';
import 'package:school_platform/l10n/app_localizations.dart';

/// Startup failures stay recoverable without exposing backend details.
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({required this.initialize, super.key});
  final Future<Widget> Function() initialize;

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<Widget> _startup;

  @override
  void initState() {
    super.initState();
    _startup = Future.sync(widget.initialize);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.requireData;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: snapshot.hasError
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                l10n.errorUnknown,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => setState(() {
                                  _startup = Future.sync(widget.initialize);
                                }),
                                child: Text(l10n.retry),
                              ),
                            ],
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
