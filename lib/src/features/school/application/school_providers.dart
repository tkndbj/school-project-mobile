import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/locale/locale_controller.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/school/data/school_repository.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';

// ------------------------------------------------------------ school choice

final selectedSchoolIdProvider =
    NotifierProvider<SelectedSchoolController, String?>(
      SelectedSchoolController.new,
    );

class SelectedSchoolController extends Notifier<String?> {
  @override
  String? build() => ref
      .watch(sharedPreferencesProvider)
      .getString(PreferenceKeys.selectedSchoolId);

  Future<void> select(String schoolId) async {
    state = schoolId;
    await ref
        .read(sharedPreferencesProvider)
        .setString(PreferenceKeys.selectedSchoolId, schoolId);
  }
}

/// The school the staff user is working in: the remembered choice if still a
/// membership, otherwise the first membership (alphabetical).
final activeMembershipProvider = Provider<SchoolMembership?>((ref) {
  final account = ref.watch(accountContextProvider).value;
  if (account == null || account.memberships.isEmpty) return null;
  return account.membershipFor(ref.watch(selectedSchoolIdProvider)) ??
      account.memberships.first;
});

// -------------------------------------------------------------- read models

final dashboardProvider = FutureProvider.autoDispose
    .family<DashboardStats, String>(
      (ref, schoolId) =>
          ref.watch(schoolRepositoryProvider).fetchDashboard(schoolId),
    );

typedef StudentKey = ({String schoolId, String studentId});

final studentRecordProvider = FutureProvider.autoDispose
    .family<StudentRecord, StudentKey>(
      (ref, key) => ref
          .watch(schoolRepositoryProvider)
          .fetchStudent(key.schoolId, key.studentId),
    );

final staffStudentNotesProvider = FutureProvider.autoDispose
    .family<List<StaffNote>, StudentKey>(
      (ref, key) => ref
          .watch(schoolRepositoryProvider)
          .fetchStudentNotes(key.schoolId, key.studentId),
    );

final upcomingEventsProvider = FutureProvider.autoDispose
    .family<List<SchoolEvent>, String>(
      (ref, schoolId) =>
          ref.watch(schoolRepositoryProvider).fetchUpcomingEvents(schoolId),
    );

final schoolClassesProvider = FutureProvider.autoDispose
    .family<List<({String? gradeLevel, String? section})>, String>(
      (ref, schoolId) =>
          ref.watch(schoolRepositoryProvider).fetchClasses(schoolId),
    );

// ----------------------------------------------------------- student search

@immutable
class StudentListState {
  const StudentListState({
    required this.query,
    required this.students,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.loadMoreError,
  });

  final String query;
  final List<StudentSummary> students;
  final bool hasMore;
  final bool isLoadingMore;

  /// A new search is running; [students] still shows the previous results.
  final bool isSearching;
  final Object? loadMoreError;

  int get loadedPages =>
      (students.length / SchoolRepository.studentsPageSize).ceil();
}

final studentListProvider = AsyncNotifierProvider.autoDispose
    .family<StudentListController, StudentListState, String>(
      StudentListController.new,
    );

class StudentListController extends AsyncNotifier<StudentListState> {
  StudentListController(this.schoolId);

  final String schoolId;
  String _query = '';

  @override
  Future<StudentListState> build() => _firstPage(_query);

  Future<StudentListState> _firstPage(String query) async {
    final students = await ref
        .read(schoolRepositoryProvider)
        .searchStudents(schoolId, query: query);
    return StudentListState(
      query: query,
      students: students,
      hasMore: students.length == SchoolRepository.studentsPageSize,
    );
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    if (normalized == _query && state.hasValue) return;
    _query = normalized;
    final current = state.value;
    if (current != null) state = AsyncData(_copy(current, isSearching: true));
    final next = await AsyncValue.guard(() => _firstPage(normalized));
    // A newer search may have started while this one was in flight.
    if (ref.mounted && _query == normalized) state = next;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(_copy(current, isLoadingMore: true));
    try {
      final more = await ref
          .read(schoolRepositoryProvider)
          .searchStudents(
            schoolId,
            query: current.query,
            page: current.loadedPages,
          );
      if (!ref.mounted || _query != current.query) return;
      state = AsyncData(
        StudentListState(
          query: current.query,
          students: [...current.students, ...more],
          hasMore: more.length == SchoolRepository.studentsPageSize,
        ),
      );
    } on Object catch (e) {
      if (ref.mounted) state = AsyncData(_copy(current, loadMoreError: e));
    }
  }

  StudentListState _copy(
    StudentListState s, {
    bool isLoadingMore = false,
    bool isSearching = false,
    Object? loadMoreError,
  }) => StudentListState(
    query: s.query,
    students: s.students,
    hasMore: s.hasMore,
    isLoadingMore: isLoadingMore,
    isSearching: isSearching,
    loadMoreError: loadMoreError,
  );
}

// --------------------------------------------------------------- attendance

typedef AttendanceSheetKey = ({
  String schoolId,
  DateTime date,
  String? gradeLevel,
  String? section,
});

/// Students of a class with their saved and pending (unsaved) daily status.
@immutable
class AttendanceSheet {
  const AttendanceSheet({
    required this.students,
    required this.saved,
    required this.pending,
  });

  final List<StudentSummary> students;

  /// Saved daily records by student id (with notes and minutes late).
  final Map<String, DailyAttendanceRecord> saved;
  final Map<String, AttendanceStatus> pending;

  AttendanceStatus? statusOf(String studentId) =>
      pending[studentId] ?? saved[studentId]?.status;

  /// Pending entries that differ from what is saved.
  Map<String, AttendanceStatus> get changes => {
    for (final entry in pending.entries)
      if (saved[entry.key]?.status != entry.value) entry.key: entry.value,
  };

  /// Entries for `save_attendance`. Existing notes and minutes late are sent
  /// back unchanged because the RPC replaces the whole record.
  List<AttendanceEntryInput> get changeEntries => [
    for (final MapEntry(key: studentId, value: status) in changes.entries)
      AttendanceEntryInput(
        studentId: studentId,
        status: status,
        minutesLate: saved[studentId]?.minutesLate,
        note: saved[studentId]?.note,
      ),
  ];

  AttendanceSheet withPending(Map<String, AttendanceStatus> pending) =>
      AttendanceSheet(students: students, saved: saved, pending: pending);
}

final attendanceSheetProvider = AsyncNotifierProvider.autoDispose
    .family<AttendanceSheetController, AttendanceSheet, AttendanceSheetKey>(
      AttendanceSheetController.new,
    );

class AttendanceSheetController extends AsyncNotifier<AttendanceSheet> {
  AttendanceSheetController(this.key);

  final AttendanceSheetKey key;

  @override
  Future<AttendanceSheet> build() async {
    final repository = ref.watch(schoolRepositoryProvider);
    final date = dateOnly(key.date);
    final (students, records) = await (
      repository.fetchActiveStudents(
        key.schoolId,
        gradeLevel: key.gradeLevel,
        section: key.section,
      ),
      repository.fetchDailyAttendance(key.schoolId, date),
    ).wait;
    return AttendanceSheet(
      students: students,
      saved: records,
      pending: const {},
    );
  }

  void mark(String studentId, AttendanceStatus status) {
    final sheet = state.value;
    if (sheet == null) return;
    state = AsyncData(sheet.withPending({...sheet.pending, studentId: status}));
  }

  /// Marks every student without a status as present.
  void markUnmarkedPresent() {
    final sheet = state.value;
    if (sheet == null) return;
    state = AsyncData(
      sheet.withPending({
        ...sheet.pending,
        for (final s in sheet.students)
          if (sheet.statusOf(s.id) == null) s.id: AttendanceStatus.present,
      }),
    );
  }

  /// Saves pending changes. Throws an AppFailure on error, keeping the
  /// pending changes so the user can retry.
  Future<void> save() async {
    final sheet = state.value;
    if (sheet == null) return;
    final entries = sheet.changeEntries;
    if (entries.isEmpty) return;
    await ref
        .read(schoolRepositoryProvider)
        .saveDailyAttendance(key.schoolId, key.date, entries);
    if (!ref.mounted) return;
    state = AsyncData(
      AttendanceSheet(
        students: sheet.students,
        saved: {
          ...sheet.saved,
          for (final e in entries)
            e.studentId: DailyAttendanceRecord(
              studentId: e.studentId,
              status: e.status!,
              minutesLate: e.status == AttendanceStatus.late
                  ? e.minutesLate
                  : null,
              note: e.note,
            ),
        },
        pending: const {},
      ),
    );
  }
}
