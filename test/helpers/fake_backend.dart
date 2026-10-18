import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A real [SupabaseClient] whose HTTP traffic is answered by [handler].
///
/// Tests exercise the actual PostgREST query building and error parsing and
/// assert on the outgoing requests, without a network or a database.
class FakeBackend {
  FakeBackend(this.handler) {
    client = SupabaseClient(
      'https://project.supabase.test',
      'sb_publishable_test',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await handler(request);
        // Real clients attach the originating request; postgrest relies on it.
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  }

  final Future<http.Response> Function(http.Request request) handler;
  final requests = <http.Request>[];
  late final SupabaseClient client;

  http.Request get lastRequest => requests.last;

  /// JSON body of the last request.
  Object? get lastBody => jsonDecode(lastRequest.body);

  Future<void> dispose() => client.dispose();
}

http.Response jsonResponse(Object? body, {int status = 200}) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// A PostgREST error response as returned for a raised Postgres exception.
http.Response postgresError(String code, String message, {int status = 400}) =>
    jsonResponse({
      'code': code,
      'message': message,
      'details': null,
      'hint': null,
    }, status: status);

final AppLocalizations l10nEn = lookupAppLocalizations(const Locale('en'));
final AppLocalizations l10nTr = lookupAppLocalizations(const Locale('tr'));
