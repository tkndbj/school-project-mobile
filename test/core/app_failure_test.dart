import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/errors/failure_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fake_backend.dart';

void main() {
  group('AppFailure.from maps database errors (docs/database.md)', () {
    PostgrestException pg(String code, String message, {Object? details}) =>
        PostgrestException(code: code, message: message, details: details);

    test('42501 → permission denied with the reason key', () {
      final failure = AppFailure.from(pg('42501', 'student_not_accessible'));
      expect(
        failure,
        isA<PermissionDeniedFailure>().having(
          (f) => f.reason,
          'reason',
          'student_not_accessible',
        ),
      );
    });

    test('SC001 → custom field failure with the field key from details', () {
      final failure = AppFailure.from(
        pg('SC001', 'custom_field_invalid_option', details: 'bus_route'),
      );
      expect(
        failure,
        isA<CustomFieldFailure>()
            .having((f) => f.reason, 'reason', 'custom_field_invalid_option')
            .having((f) => f.field, 'field', 'bus_route'),
      );
    });

    test('SC010 / SC011 / SC020 / SC030 map to their own types', () {
      expect(
        AppFailure.from(pg('SC010', 'invalid_timezone')),
        isA<InvalidSettingFailure>(),
      );
      expect(
        AppFailure.from(pg('SC011', 'school_requires_an_admin')),
        isA<MembershipRuleFailure>(),
      );
      expect(
        AppFailure.from(pg('SC020', 'invalid_date_range')),
        isA<InvalidArgumentFailure>(),
      );
      expect(
        AppFailure.from(pg('SC030', 'import_unknown_column')),
        isA<ImportFormatFailure>(),
      );
    });

    test('23505 extracts the violated constraint', () {
      final failure = AppFailure.from(
        pg(
          '23505',
          'duplicate key value violates unique constraint '
              '"students_school_id_student_number_key"',
        ),
      );
      expect(
        failure,
        isA<DuplicateFailure>().having(
          (f) => f.constraint,
          'constraint',
          'students_school_id_student_number_key',
        ),
      );
    });

    test('23514 / 23502 → constraint failure', () {
      expect(
        AppFailure.from(
          pg(
            '23514',
            'new row violates check constraint "students_identifiable"',
          ),
        ),
        isA<ConstraintFailure>().having(
          (f) => f.constraint,
          'constraint',
          'students_identifiable',
        ),
      );
      expect(
        AppFailure.from(pg('23502', 'null value')),
        isA<ConstraintFailure>(),
      );
    });

    test('JWT errors → session expired; PGRST116 → not found', () {
      expect(
        AppFailure.from(pg('PGRST301', 'JWT expired')),
        isA<SessionExpiredFailure>(),
      );
      expect(
        AppFailure.from(pg('PGRST116', 'no rows')),
        isA<NotFoundFailure>(),
      );
    });

    test('unknown codes stay unknown, 5xx become server failures', () {
      expect(AppFailure.from(pg('XX000', 'boom')), isA<UnknownFailure>());
      expect(AppFailure.from(pg('503', 'unavailable')), isA<ServerFailure>());
    });
  });

  group('AppFailure.from maps auth and transport errors', () {
    test('auth error codes', () {
      expect(
        AppFailure.from(
          const AuthApiException('bad', code: 'invalid_credentials'),
        ),
        isA<AuthFailure>().having(
          (f) => f.kind,
          'kind',
          AuthFailureKind.invalidCredentials,
        ),
      );
      expect(
        AppFailure.from(
          const AuthApiException('slow down', code: 'over_request_rate_limit'),
        ),
        isA<AuthFailure>().having(
          (f) => f.kind,
          'kind',
          AuthFailureKind.rateLimited,
        ),
      );
      expect(
        AppFailure.from(AuthSessionMissingException()),
        isA<SessionExpiredFailure>(),
      );
      expect(
        AppFailure.from(AuthRetryableFetchException()),
        isA<NetworkFailure>(),
      );
    });

    test('network exceptions', () {
      expect(
        AppFailure.from(const SocketException('offline')),
        isA<NetworkFailure>(),
      );
      expect(AppFailure.from(TimeoutException('slow')), isA<NetworkFailure>());
    });

    test('failures pass through unchanged', () {
      const failure = AccountDeletionBlockedFailure();
      expect(AppFailure.from(failure), same(failure));
    });
  });

  group('failureMessage', () {
    test('localizes specific constraints and reasons', () {
      expect(
        failureMessage(
          l10nEn,
          const DuplicateFailure(
            constraint: 'students_school_id_student_number_key',
          ),
        ),
        l10nEn.errorDuplicateStudentNumber,
      );
      expect(
        failureMessage(
          l10nEn,
          const ConstraintFailure(constraint: 'students_identifiable'),
        ),
        l10nEn.errorStudentIdentifiable,
      );
      expect(
        failureMessage(
          l10nEn,
          const MembershipRuleFailure('school_requires_an_admin'),
        ),
        l10nEn.errorSchoolRequiresAdmin,
      );
      expect(
        failureMessage(
          l10nTr,
          const CustomFieldFailure(
            'custom_field_invalid_option',
            field: 'bus_route',
          ),
        ),
        '"bus_route" alanının değeri geçersiz.',
      );
    });

    test('falls back to a generic message for raw exceptions', () {
      expect(failureMessage(l10nEn, StateError('x')), l10nEn.errorUnknown);
    });
  });
}
