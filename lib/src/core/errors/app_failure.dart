import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Every error that reaches the presentation layer is an [AppFailure].
///
/// Repositories convert low-level exceptions (Postgres/PostgREST, auth,
/// network) with [AppFailure.from]; widgets turn a failure into a localized
/// message with `failureMessage` (see failure_messages.dart). The database
/// error contract is documented in the web repo: docs/database.md.
@immutable
sealed class AppFailure implements Exception {
  const AppFailure();

  /// Maps any thrown object to a typed failure.
  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is PostgrestException) return _fromPostgrest(error);
    if (error is AuthException) return _fromAuth(error);
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return const NetworkFailure();
    }
    return UnknownFailure(error.toString());
  }

  static AppFailure _fromPostgrest(PostgrestException e) {
    final detail = e.details?.toString();
    switch (e.code) {
      case '42501':
        return PermissionDeniedFailure(e.message);
      case 'PGRST301' || 'PGRST302' || 'PGRST303':
        return const SessionExpiredFailure();
      case 'PGRST116':
        return const NotFoundFailure();
      case 'SC001':
        return CustomFieldFailure(e.message, field: detail);
      case 'SC010':
        return InvalidSettingFailure(e.message);
      case 'SC011':
        return MembershipRuleFailure(e.message);
      case 'SC020':
        return InvalidArgumentFailure(e.message);
      case 'SC030':
        return ImportFormatFailure(e.message, detail: detail);
      case '23505':
        return DuplicateFailure(constraint: _constraintName(e.message));
      case '23514' || '23502':
        return ConstraintFailure(constraint: _constraintName(e.message));
      case '23503':
        return const ReferenceFailure();
      case '22P02' || '22007' || '22008' || '22023':
        return const InvalidInputFailure();
    }
    final status = int.tryParse(e.code ?? '');
    if (status != null && status >= 500) return const ServerFailure();
    return UnknownFailure(e.message);
  }

  static AppFailure _fromAuth(AuthException e) {
    if (e is AuthRetryableFetchException) return const NetworkFailure();
    if (e is AuthSessionMissingException) return const SessionExpiredFailure();
    switch (e.code) {
      case 'invalid_credentials':
        return const AuthFailure(AuthFailureKind.invalidCredentials);
      case 'email_not_confirmed':
        return const AuthFailure(AuthFailureKind.emailNotConfirmed);
      case 'user_banned':
        return const AuthFailure(AuthFailureKind.userBanned);
      case 'over_request_rate_limit' || 'over_email_send_rate_limit':
        return const AuthFailure(AuthFailureKind.rateLimited);
      case 'session_expired' || 'refresh_token_not_found':
        return const SessionExpiredFailure();
    }
    return const AuthFailure(AuthFailureKind.unknown);
  }

  /// Extracts the constraint name from Postgres messages such as
  /// `duplicate key value violates unique constraint "students_..._key"`.
  static String? _constraintName(String message) =>
      RegExp('constraint "([^"]+)"').firstMatch(message)?.group(1);
}

/// The user may not perform the action (SQLSTATE 42501).
final class PermissionDeniedFailure extends AppFailure {
  const PermissionDeniedFailure([this.reason]);

  /// Stable machine-readable key from the database,
  /// e.g. `student_not_accessible`.
  final String? reason;
}

final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure();
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure();
}

/// A custom field value was rejected (SC001). [reason] is e.g.
/// `custom_field_invalid_option`; [field] is the field key.
final class CustomFieldFailure extends AppFailure {
  const CustomFieldFailure(this.reason, {this.field});

  final String reason;
  final String? field;
}

/// An invalid school setting such as a time zone (SC010).
final class InvalidSettingFailure extends AppFailure {
  const InvalidSettingFailure(this.reason);

  final String reason;
}

/// A membership rule was violated, e.g. `school_requires_an_admin` (SC011).
final class MembershipRuleFailure extends AppFailure {
  const MembershipRuleFailure(this.reason);

  final String reason;
}

/// An argument such as a date range was invalid (SC020).
final class InvalidArgumentFailure extends AppFailure {
  const InvalidArgumentFailure(this.reason);

  final String reason;
}

/// Bulk import payload problem (SC030).
final class ImportFormatFailure extends AppFailure {
  const ImportFormatFailure(this.reason, {this.detail});

  final String reason;
  final String? detail;
}

/// A unique constraint was violated (23505).
final class DuplicateFailure extends AppFailure {
  const DuplicateFailure({this.constraint});

  final String? constraint;
}

/// A check / not-null constraint was violated (23514 / 23502).
final class ConstraintFailure extends AppFailure {
  const ConstraintFailure({this.constraint});

  final String? constraint;
}

/// A referenced record does not exist (23503).
final class ReferenceFailure extends AppFailure {
  const ReferenceFailure();
}

/// A value had the wrong format (invalid date, email, enum value, ...).
final class InvalidInputFailure extends AppFailure {
  const InvalidInputFailure();
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class ServerFailure extends AppFailure {
  const ServerFailure();
}

enum AuthFailureKind {
  invalidCredentials,
  emailNotConfirmed,
  userBanned,
  rateLimited,
  googleNotAvailable,
  unknown,
}

final class AuthFailure extends AppFailure {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;
}

/// The user dismissed a sign-in flow. Callers usually ignore it silently.
final class CancelledFailure extends AppFailure {
  const CancelledFailure();
}

/// The account cannot be deleted yet (e.g. last admin of a school).
final class AccountDeletionBlockedFailure extends AppFailure {
  const AccountDeletionBlockedFailure();
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(this.message);

  final String message;

  @override
  String toString() => 'UnknownFailure($message)';
}
