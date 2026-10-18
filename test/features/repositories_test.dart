import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/media/media_repository.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/features/account/data/account_repository.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/parent/data/parent_repository.dart';
import 'package:school_platform/src/features/school/data/school_repository.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';

import '../helpers/fake_backend.dart';

void main() {
  group('ParentRepository', () {
    test('children reads continue past the Data API row cap', () async {
      final backend = FakeBackend((request) async {
        final offset = int.parse(request.url.queryParameters['offset'] ?? '0');
        return jsonResponse(
          List.generate(
            offset == 0 ? 1000 : 1,
            (index) => {
              'student_id': 'student-${offset + index}',
              'school_id': 'school',
              'school_name': 'School',
              'school_timezone': 'UTC',
              'enabled_modules': <String>[],
              'status': 'active',
            },
          ),
        );
      });
      addTearDown(backend.dispose);
      final children = await ParentRepository(backend.client).fetchChildren();
      expect(children, hasLength(1001));
      expect(backend.lastRequest.url.queryParameters['offset'], '1000');
    });
    test('calls guardian RPCs with the documented parameters', () async {
      final backend = FakeBackend(
        (_) async => jsonResponse([
          {
            'record_id': 'r1',
            'attended_on': '2026-10-02',
            'status': 'late',
            'minutes_late': 10,
          },
        ]),
      );
      addTearDown(backend.dispose);

      final records = await ParentRepository(
        backend.client,
      ).fetchAttendance('st1', MonthRange(DateTime(2026, 10, 15)));

      expect(backend.lastRequest.method, 'POST');
      expect(
        backend.lastRequest.url.path,
        '/rest/v1/rpc/guardian_student_attendance',
      );
      expect(backend.lastBody, {
        'p_student_id': 'st1',
        'p_from': '2026-10-01',
        'p_to': '2026-10-31',
      });
      expect(records.single.status, AttendanceStatus.late);
      expect(records.single.minutesLate, 10);
    });

    test(
      'notes pagination sends p_before as UTC ISO-8601 and the page size',
      () async {
        final backend = FakeBackend((_) async => jsonResponse(<Object>[]));
        addTearDown(backend.dispose);

        await ParentRepository(
          backend.client,
        ).fetchNotes(
          'st1',
          before: DateTime.utc(2026, 10, 1, 12),
          beforeId: 'note-20',
        );

        expect(backend.lastBody, {
          'p_student_id': 'st1',
          'p_before': '2026-10-01T12:00:00.000Z',
          'p_before_id': 'note-20',
          'p_limit': ParentRepository.notesPageSize,
        });
      },
    );

    test('database permission errors become PermissionDeniedFailure', () async {
      final backend = FakeBackend(
        (_) async =>
            postgresError('42501', 'student_not_accessible', status: 403),
      );
      addTearDown(backend.dispose);

      await expectLater(
        ParentRepository(backend.client).fetchProfile('someone-else'),
        throwsA(
          isA<PermissionDeniedFailure>().having(
            (f) => f.reason,
            'reason',
            'student_not_accessible',
          ),
        ),
      );
    });

    test('an empty profile result is NotFound', () async {
      final backend = FakeBackend((_) async => jsonResponse(<Object>[]));
      addTearDown(backend.dispose);
      await expectLater(
        ParentRepository(backend.client).fetchProfile('x'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('SchoolRepository', () {
    test('class filters use the database aggregate', () async {
      final backend = FakeBackend(
        (_) async => jsonResponse([
          {'grade_level': '5', 'section': 'A', 'student_count': 2000},
        ]),
      );
      addTearDown(backend.dispose);
      final classes = await SchoolRepository(backend.client).fetchClasses('s1');
      expect(classes, [(gradeLevel: '5', section: 'A')]);
      expect(
        backend.lastRequest.url.path,
        '/rest/v1/rpc/school_student_groups',
      );
      expect(backend.lastBody, {'p_school_id': 's1'});
    });
    test(
      'student search filters by school, escapes input and pages with range',
      () async {
        final backend = FakeBackend(
          (_) async => jsonResponse([
            {'id': 'st1', 'first_name': 'Ada', 'status': 'active'},
          ]),
        );
        addTearDown(backend.dispose);

        final students = await SchoolRepository(
          backend.client,
        ).searchStudents('s1', query: 'ad,a)(*', page: 2);

        final url = backend.lastRequest.url;
        expect(url.path, '/rest/v1/students');
        expect(url.queryParameters['school_id'], 'eq.s1');
        expect(
          url.queryParameters['or'],
          contains('first_name.ilike."%ad a%"'),
        );
        expect(
          url.queryParameters['order'],
          'last_name.asc.nullslast,first_name.asc.nullslast,id.asc.nullslast',
        );
        expect(
          url.queryParameters['offset'],
          '${2 * SchoolRepository.studentsPageSize}',
        );
        expect(
          url.queryParameters['limit'],
          '${SchoolRepository.studentsPageSize}',
        );
        expect(students.single.displayName, 'Ada');
      },
    );

    test('searchPattern strips filter-grammar characters', () {
      expect(searchPattern('  '), isNull);
      expect(searchPattern(r'50%_off\'), '"%50 off%"');
      expect(searchPattern('a,b(c)d:e"f'), '"%a b c d e f%"');
    });

    test(
      'daily attendance goes through the atomic save_attendance RPC',
      () async {
        final backend = FakeBackend((_) async => jsonResponse(2));
        addTearDown(backend.dispose);

        await SchoolRepository(backend.client).saveDailyAttendance(
          's1',
          DateTime(2026, 10, 18),
          const [
            AttendanceEntryInput(
              studentId: 'st1',
              status: AttendanceStatus.late,
              minutesLate: 10,
              note: 'Bus',
            ),
            AttendanceEntryInput(
              studentId: 'st2',
              status: AttendanceStatus.absent,
              minutesLate: 5,
            ),
            AttendanceEntryInput(studentId: 'st3', status: null),
          ],
        );

        expect(backend.lastRequest.url.path, '/rest/v1/rpc/save_attendance');
        expect(backend.lastBody, {
          'p_school_id': 's1',
          'p_date': '2026-10-18',
          'p_entries': [
            {
              'student_id': 'st1',
              'status': 'late',
              'minutes_late': 10,
              'note': 'Bus',
            },
            {'student_id': 'st2', 'status': 'absent', 'note': null},
            {'student_id': 'st3', 'status': null, 'note': null},
          ],
        });
      },
    );

    test('saving nothing makes no request', () async {
      final backend = FakeBackend((_) async => jsonResponse(0));
      addTearDown(backend.dispose);
      await SchoolRepository(
        backend.client,
      ).saveDailyAttendance('s1', DateTime(2026), const []);
      expect(backend.requests, isEmpty);
    });

    test('updating a row hidden by RLS is reported as not found', () async {
      final backend = FakeBackend((_) async => jsonResponse(<Object>[]));
      addTearDown(backend.dispose);
      await expectLater(
        SchoolRepository(
          backend.client,
        ).updateStudent('s1', 'st1', const StudentDraft(firstName: 'A')),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(backend.lastRequest.method, 'PATCH');
      expect(backend.lastRequest.url.queryParameters['school_id'], 'eq.s1');
    });

    test('duplicate student numbers surface as DuplicateFailure', () async {
      final backend = FakeBackend(
        (_) async => postgresError(
          '23505',
          'duplicate key value violates unique constraint '
              '"students_school_id_student_number_key"',
          status: 409,
        ),
      );
      addTearDown(backend.dispose);
      await expectLater(
        SchoolRepository(
          backend.client,
        ).createStudent('s1', const StudentDraft(studentNumber: 'A-1')),
        throwsA(isA<DuplicateFailure>()),
      );
      expect(backend.lastBody, containsPair('school_id', 's1'));
    });
  });

  group('AccountRepository', () {
    AccountRepository repository(
      FakeBackend backend,
      MockClient http, {
      String? token = 'jwt',
    }) => AccountRepository(
      client: backend.client,
      httpClient: http,
      webBaseUrl: 'https://web.test',
      accessToken: () => token,
    );

    test('redeemInvite parses the status row', () async {
      final backend = FakeBackend(
        (_) async => jsonResponse([
          {'status': 'linked', 'school_id': 's1', 'school_name': 'School A'},
        ]),
      );
      addTearDown(backend.dispose);
      final result = await repository(
        backend,
        MockClient((_) async => http.Response('', 500)),
      ).redeemInvite('ABCDE-FGHJK');
      expect(backend.lastBody, {'p_code': 'ABCDE-FGHJK'});
      expect(result.status, InviteRedemptionStatus.linked);
      expect(result.schoolName, 'School A');
    });

    test(
      'deleteAccount calls DELETE /api/account with the bearer token',
      () async {
        final backend = FakeBackend((_) async => jsonResponse(null));
        addTearDown(backend.dispose);
        late http.Request sent;
        final client = MockClient((request) async {
          sent = request;
          return http.Response('', 204);
        });

        await repository(backend, client).deleteAccount();

        expect(sent.method, 'DELETE');
        expect(sent.url.toString(), 'https://web.test/api/account');
        expect(sent.headers['Authorization'], 'Bearer jwt');
      },
    );

    test('deleteAccount maps the documented status codes', () async {
      final backend = FakeBackend((_) async => jsonResponse(null));
      addTearDown(backend.dispose);
      Future<void> deleteWith(int status) => repository(
        backend,
        MockClient((_) async => http.Response('', status)),
      ).deleteAccount();

      await expectLater(
        deleteWith(409),
        throwsA(isA<AccountDeletionBlockedFailure>()),
      );
      await expectLater(deleteWith(401), throwsA(isA<SessionExpiredFailure>()));
      await expectLater(deleteWith(503), throwsA(isA<ServerFailure>()));
    });

    test('deleteAccount without a session never calls the API', () async {
      final backend = FakeBackend((_) async => jsonResponse(null));
      addTearDown(backend.dispose);
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('', 204);
      });
      await expectLater(
        repository(backend, client, token: null).deleteAccount(),
        throwsA(isA<SessionExpiredFailure>()),
      );
      expect(called, isFalse);
    });
  });

  group('MediaRepository', () {
    test('caches signed URLs until shortly before they expire', () async {
      final backend = FakeBackend(
        (_) async => jsonResponse({
          'signedURL': '/object/sign/school-media/s1/branding/logo.png?token=t',
        }),
      );
      addTearDown(backend.dispose);
      var now = DateTime(2026, 10, 18, 9);
      final media = MediaRepository(backend.client, clock: () => now);

      final first = await media.signedUrl('s1/branding/logo.png');
      await media.signedUrl('s1/branding/logo.png');
      expect(backend.requests, hasLength(1));
      expect(
        backend.lastRequest.url.path,
        '/storage/v1/object/sign/school-media/s1/branding/logo.png',
      );
      expect(first, contains('token=t'));

      now = now.add(const Duration(minutes: 55));
      await media.signedUrl('s1/branding/logo.png');
      expect(backend.requests, hasLength(2));
    });
  });
}
