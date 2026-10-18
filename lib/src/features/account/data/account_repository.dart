import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/core/utils/json.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(
    client: ref.watch(supabaseClientProvider),
    httpClient: ref.watch(httpClientProvider),
    webBaseUrl: ref.watch(appConfigProvider).webBaseUrl,
  ),
);

/// Account-level operations: routing context, guardian linking, profile and
/// account deletion. Throws [AppFailure]s only.
class AccountRepository {
  AccountRepository({
    required SupabaseClient client,
    required http.Client httpClient,
    required String webBaseUrl,
    String? Function()? accessToken,
  }) : _client = client,
       _http = httpClient,
       _webBaseUrl = webBaseUrl,
       _accessToken =
           accessToken ?? (() => client.auth.currentSession?.accessToken);

  final SupabaseClient _client;
  final http.Client _http;
  final String _webBaseUrl;
  final String? Function() _accessToken;

  static const _requestTimeout = Duration(seconds: 20);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(_requestTimeout);
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Links guardian records whose email matches the verified account email.
  Future<int> linkGuardianRecords() => _guard(() async {
    final result = await _client.rpc<dynamic>('link_my_guardian_records');
    return (result as num?)?.toInt() ?? 0;
  });

  Future<AccountContext> fetchContext() => _guard(() async {
    final result = await _client.rpc<dynamic>('my_account_context');
    return AccountContext.fromJson((result as Map).cast());
  });

  Future<InviteRedemption> redeemInvite(String code) => _guard(() async {
    final result = await _client.rpc<dynamic>(
      'redeem_guardian_invite',
      params: {'p_code': code},
    );
    final rows = parseList(result, (json) => json);
    if (rows.isEmpty) {
      return const InviteRedemption(status: InviteRedemptionStatus.invalid);
    }
    return InviteRedemption.fromJson(rows.first);
  });

  Future<String?> fetchFullName(String userId) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();
    return row?.optString('full_name');
  });

  Future<void> updateProfile(
    String userId, {
    String? fullName,
    String? locale,
    bool clearFullName = false,
  }) => _guard(() async {
    final values = <String, Object?>{
      if (fullName != null || clearFullName) 'full_name': fullName,
      'locale': ?locale,
    };
    if (values.isEmpty) return;
    await _client.from('profiles').update(values).eq('id', userId);
  });

  /// Permanently deletes the signed-in account through the web API
  /// (`DELETE {WEB_BASE_URL}/api/account`, see docs/database.md).
  Future<void> deleteAccount() => _guard(() async {
    final token = _accessToken();
    if (token == null) throw const SessionExpiredFailure();

    final response = await _http.delete(
      Uri.parse('$_webBaseUrl/api/account'),
      headers: {'Authorization': 'Bearer $token'},
    );
    switch (response.statusCode) {
      case 200 || 204:
        return;
      case 401:
        throw const SessionExpiredFailure();
      case 403:
        throw const PermissionDeniedFailure();
      case 409:
        throw const AccountDeletionBlockedFailure();
      case >= 500:
        throw const ServerFailure();
      default:
        throw UnknownFailure(
          'Account deletion failed (${response.statusCode})',
        );
    }
  });
}
