import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/routing/app_router.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/data/account_repository.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:school_platform/src/features/school/data/school_repository.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';

class MockSchoolRepository extends Mock implements SchoolRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

StudentSummary student(String id) =>
    StudentSummary(id: id, firstName: id, status: StudentStatus.active);

const accountU1 = AccountContext(
  userId: 'u1',
  isPlatformAdmin: false,
  memberships: [],
  childrenCount: 1,
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<AttendanceEntryInput>[]);
  });

  group('AttendanceSheetController', () {
    late MockSchoolRepository repository;
    late ProviderContainer container;
    final key = (
      schoolId: 's1',
      date: DateTime(2026, 10, 18),
      gradeLevel: '5',
      section: null,
    );

    setUp(() {
      repository = MockSchoolRepository();
      when(
        () => repository.fetchActiveStudents(
          's1',
          gradeLevel: '5',
        ),
      ).thenAnswer((_) async => [student('a'), student('b'), student('c')]);
      when(
        () => repository.fetchDailyAttendance('s1', DateTime(2026, 10, 18)),
      ).thenAnswer(
        (_) async => {
          'a': const DailyAttendanceRecord(
            studentId: 'a',
            status: AttendanceStatus.late,
            minutesLate: 15,
            note: 'Doctor visit',
          ),
        },
      );
      container = ProviderContainer.test(
        overrides: [schoolRepositoryProvider.overrideWithValue(repository)],
        retry: (_, _) => null,
      );
    });

    AttendanceSheet sheet() =>
        container.read(attendanceSheetProvider(key)).requireValue;
    AttendanceSheetController controller() =>
        container.read(attendanceSheetProvider(key).notifier);

    test('loads the class with already saved statuses', () async {
      container.listen(attendanceSheetProvider(key), (_, _) {});
      await container.read(attendanceSheetProvider(key).future);
      expect(sheet().students.map((s) => s.id), ['a', 'b', 'c']);
      expect(sheet().statusOf('a'), AttendanceStatus.late);
      expect(sheet().statusOf('b'), isNull);
      expect(sheet().changes, isEmpty);
    });

    test('"mark all present" only fills unmarked students', () async {
      container.listen(attendanceSheetProvider(key), (_, _) {});
      await container.read(attendanceSheetProvider(key).future);
      controller().markUnmarkedPresent();
      expect(sheet().statusOf('a'), AttendanceStatus.late);
      expect(sheet().changes, {
        'b': AttendanceStatus.present,
        'c': AttendanceStatus.present,
      });
    });

    test('re-marking a saved status is not a change', () async {
      container.listen(attendanceSheetProvider(key), (_, _) {});
      await container.read(attendanceSheetProvider(key).future);
      controller().mark('a', AttendanceStatus.late);
      expect(sheet().changes, isEmpty);
    });

    test('save sends only the changes and marks them saved', () async {
      when(
        () => repository.saveDailyAttendance(any(), any(), any()),
      ).thenAnswer((_) async {});
      container.listen(attendanceSheetProvider(key), (_, _) {});
      await container.read(attendanceSheetProvider(key).future);

      controller()
        ..mark('b', AttendanceStatus.late)
        ..mark('a', AttendanceStatus.excused);
      await controller().save();

      final entries =
          verify(
                () => repository.saveDailyAttendance(
                  's1',
                  DateTime(2026, 10, 18),
                  captureAny(),
                ),
              ).captured.single
              as List<AttendanceEntryInput>;
      expect(
        entries.map((e) => e.toJson()),
        unorderedEquals([
          // The existing note survives a status change; minutes late are
          // dropped because the student is no longer late.
          {'student_id': 'a', 'status': 'excused', 'note': 'Doctor visit'},
          {
            'student_id': 'b',
            'status': 'late',
            'minutes_late': null,
            'note': null,
          },
        ]),
      );
      expect(sheet().changes, isEmpty);
      expect(sheet().statusOf('b'), AttendanceStatus.late);
      expect(sheet().saved['a']?.note, 'Doctor visit');
    });

    test('a failed save keeps the pending changes for retry', () async {
      when(
        () => repository.saveDailyAttendance(any(), any(), any()),
      ).thenThrow(const NetworkFailure());
      container.listen(attendanceSheetProvider(key), (_, _) {});
      await container.read(attendanceSheetProvider(key).future);

      controller().mark('c', AttendanceStatus.excused);
      await expectLater(controller().save(), throwsA(isA<NetworkFailure>()));
      expect(sheet().changes, {'c': AttendanceStatus.excused});
    });
  });

  group('accountContextProvider', () {
    test('signed out → null without touching the backend', () async {
      final repository = MockAccountRepository();
      final container = ProviderContainer.test(
        overrides: [
          currentUserIdProvider.overrideWithValue(null),
          accountRepositoryProvider.overrideWithValue(repository),
        ],
      );
      expect(await container.read(accountContextProvider.future), isNull);
      verifyZeroInteractions(repository);
    });

    test(
      'links guardian records first, and never fails because of it',
      () async {
        final repository = MockAccountRepository();
        when(repository.linkGuardianRecords).thenThrow(const NetworkFailure());
        when(repository.fetchContext).thenAnswer((_) async => accountU1);
        final container = ProviderContainer.test(
          overrides: [
            currentUserIdProvider.overrideWithValue('u1'),
            accountRepositoryProvider.overrideWithValue(repository),
          ],
        );
        expect(await container.read(accountContextProvider.future), accountU1);
        verifyInOrder([
          repository.linkGuardianRecords,
          repository.fetchContext,
        ]);
      },
    );
  });

  group('routeGateProvider', () {
    ProviderContainer containerFor(String? userId, AccountContext? account) =>
        ProviderContainer.test(
          overrides: [
            currentUserIdProvider.overrideWithValue(userId),
            accountContextProvider.overrideWithValue(AsyncData(account)),
            preferredSideProvider.overrideWithBuild((ref, notifier) => null),
          ],
        );

    test('signed out', () {
      expect(
        containerFor(null, null).read(routeGateProvider),
        isA<SignedOutGate>(),
      );
    });

    test('a context that belongs to a previous user is never "ready"', () {
      expect(
        containerFor('u2', accountU1).read(routeGateProvider),
        isA<LoadingGate>(),
      );
    });

    test('ready with the effective side', () {
      final gate = containerFor('u1', accountU1).read(routeGateProvider);
      expect(
        gate,
        isA<ReadyGate>().having((g) => g.side, 'side', AppSide.parent),
      );
    });
  });
}
