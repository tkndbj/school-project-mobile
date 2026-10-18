import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';

/// Converts any error into a user-facing, localized message.
String failureMessage(AppLocalizations l10n, Object error) {
  final failure = AppFailure.from(error);
  return switch (failure) {
    PermissionDeniedFailure() => l10n.errorPermissionDenied,
    SessionExpiredFailure() => l10n.errorSessionExpired,
    NotFoundFailure() => l10n.errorNotFound,
    CustomFieldFailure(:final field) => l10n.errorCustomField(field ?? '?'),
    InvalidSettingFailure() => l10n.errorInvalidSetting,
    MembershipRuleFailure(:final reason) =>
      reason == 'school_requires_an_admin'
          ? l10n.errorSchoolRequiresAdmin
          : l10n.errorPermissionDenied,
    InvalidArgumentFailure(:final reason) =>
      reason == 'invalid_date_range'
          ? l10n.errorInvalidDateRange
          : l10n.errorInvalidInput,
    ImportFormatFailure() => l10n.errorImport,
    DuplicateFailure(:final constraint) =>
      constraint == 'students_school_id_student_number_key'
          ? l10n.errorDuplicateStudentNumber
          : l10n.errorDuplicate,
    ConstraintFailure(:final constraint) =>
      constraint == 'students_identifiable'
          ? l10n.errorStudentIdentifiable
          : l10n.errorConstraint,
    ReferenceFailure() => l10n.errorReference,
    InvalidInputFailure() => l10n.errorInvalidInput,
    NetworkFailure() => l10n.errorNetwork,
    ServerFailure() => l10n.errorServer,
    AuthFailure(:final kind) => switch (kind) {
      AuthFailureKind.invalidCredentials => l10n.errorAuthInvalidCredentials,
      AuthFailureKind.emailNotConfirmed => l10n.errorAuthEmailNotConfirmed,
      AuthFailureKind.userBanned => l10n.errorAuthUserBanned,
      AuthFailureKind.rateLimited => l10n.errorAuthRateLimited,
      AuthFailureKind.googleNotAvailable => l10n.errorGoogleNotAvailable,
      AuthFailureKind.unknown => l10n.errorAuthUnknown,
    },
    CancelledFailure() => l10n.errorUnknown,
    AccountDeletionBlockedFailure() => l10n.errorAccountDeletionBlocked,
    UnknownFailure() => l10n.errorUnknown,
  };
}
