import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/core/utils/json.dart';
import 'package:school_platform/src/core/utils/names.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>(
  (ref) => SchoolRepository(ref.watch(supabaseClientProvider)),
);

/// Staff access to a school's data. Row-level security restricts every query
/// to schools the user works at; queries still filter by `school_id`
/// explicitly so they use the right indexes and never mix schools for users
/// with several memberships. Throws [AppFailure]s only.
class SchoolRepository {
  SchoolRepository(this._client);

  final SupabaseClient _client;

  static const studentsPageSize = 30;
  static const _attendanceBatchSize = 1000;
  static const _timeout = Duration(seconds: 20);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(_timeout);
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<DashboardStats> fetchDashboard(String schoolId) => _guard(() async {
    final rows = parseList(
      await _client.rpc<dynamic>(
        'school_dashboard_stats',
        params: {'p_school_id': schoolId},
      ),
      (json) => json,
    );
    if (rows.isEmpty) throw const NotFoundFailure();
    return DashboardStats.fromJson(rows.first);
  });

  /// One page of students ordered by name, optionally filtered by a search
  /// term matched against first name, last name and student number.
  Future<List<StudentSummary>> searchStudents(
    String schoolId, {
    String query = '',
    int page = 0,
  }) => _guard(() async {
    var filter = _client
        .from('students')
        .select(StudentSummary.columns)
        .eq('school_id', schoolId);
    final pattern = searchPattern(query);
    if (pattern != null) {
      filter = filter.or(
        'first_name.ilike.$pattern,last_name.ilike.$pattern,'
        'preferred_name.ilike.$pattern,student_number.ilike.$pattern',
      );
    }
    final from = page * studentsPageSize;
    final rows = await filter
        .order('last_name', ascending: true)
        .order('first_name', ascending: true)
        .order('id', ascending: true)
        .range(from, from + studentsPageSize - 1);
    return rows.map(StudentSummary.fromJson).toList();
  });

  /// Active students of a class (or the whole school) for attendance.
  Future<List<StudentSummary>> fetchActiveStudents(
    String schoolId, {
    String? gradeLevel,
    String? section,
  }) => _guard(() async {
    final result = <StudentSummary>[];
    for (var from = 0; ; from += _attendanceBatchSize) {
      var filter = _client
          .from('students')
          .select(StudentSummary.columns)
          .eq('school_id', schoolId)
          .eq('status', StudentStatus.active.wire);
      if (blankToNull(gradeLevel) case final grade?) {
        filter = filter.eq('grade_level', grade);
      }
      if (blankToNull(section) case final sec?) {
        filter = filter.eq('section', sec);
      }
      final rows = await filter
          .order('last_name', ascending: true)
          .order('first_name', ascending: true)
          .order('id', ascending: true)
          .range(from, from + _attendanceBatchSize - 1);
      result.addAll(rows.map(StudentSummary.fromJson));
      if (rows.length < _attendanceBatchSize) return result;
    }
  });

  /// Distinct (grade level, section) pairs of active students, for filters.
  Future<List<({String? gradeLevel, String? section})>> fetchClasses(
    String schoolId,
  ) => _guard(() async {
    final rows = parseList(
      await _client.rpc<dynamic>(
        'school_student_groups',
        params: {'p_school_id': schoolId},
      ),
      (json) => json,
    );
    final classes =
        rows
            .map(
              (row) => (
                gradeLevel: row.optString('grade_level'),
                section: row.optString('section'),
              ),
            )
            .toList()
          ..sort(
            (a, b) => '${a.gradeLevel}${a.section}'.compareTo(
              '${b.gradeLevel}${b.section}',
            ),
          );
    return classes;
  });

  Future<StudentRecord> fetchStudent(String schoolId, String studentId) =>
      _guard(() async {
        final row = await _client
            .from('students')
            .select(StudentRecord.columns)
            .eq('school_id', schoolId)
            .eq('id', studentId)
            .maybeSingle();
        if (row == null) throw const NotFoundFailure();
        return StudentRecord.fromJson(row);
      });

  /// Creates a student and returns its id.
  Future<String> createStudent(String schoolId, StudentDraft draft) =>
      _guard(() async {
        final row = await _client
            .from('students')
            .insert({...draft.toJson(), 'school_id': schoolId})
            .select('id')
            .single();
        return row.requireString('id');
      });

  Future<void> updateStudent(
    String schoolId,
    String studentId,
    StudentDraft draft,
  ) => _guard(() async {
    final rows = await _client
        .from('students')
        .update(draft.toJson())
        .eq('school_id', schoolId)
        .eq('id', studentId)
        .select('id');
    // RLS filters rows silently: no row means no access (or deleted).
    if (rows.isEmpty) throw const NotFoundFailure();
  });

  Future<List<StaffNote>> fetchStudentNotes(
    String schoolId,
    String studentId,
  ) => _guard(() async {
    final rows = await _client
        .from('student_notes')
        .select(StaffNote.columns)
        .eq('school_id', schoolId)
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(StaffNote.fromJson).toList();
  });

  Future<void> addStudentNote(
    String schoolId,
    String studentId, {
    required String body,
    required bool visibleToGuardians,
    String? title,
  }) => _guard(() async {
    await _client.from('student_notes').insert({
      'school_id': schoolId,
      'student_id': studentId,
      'title': blankToNull(title),
      'body': body.trim(),
      'visible_to_guardians': visibleToGuardians,
    });
  });

  /// Daily attendance (no course, no period) already recorded for [date].
  Future<Map<String, DailyAttendanceRecord>> fetchDailyAttendance(
    String schoolId,
    DateTime date,
  ) => _guard(() async {
    final records = <String, DailyAttendanceRecord>{};
    for (var from = 0; ; from += _attendanceBatchSize) {
      final rows = await _client
          .from('attendance_records')
          .select(DailyAttendanceRecord.columns)
          .eq('school_id', schoolId)
          .eq('attended_on', toDateParam(date))
          .isFilter('course_id', null)
          .isFilter('period', null)
          .order('student_id', ascending: true)
          .range(from, from + _attendanceBatchSize - 1);
      for (final row in rows) {
        final record = DailyAttendanceRecord.fromJson(row);
        records[record.studentId] = record;
      }
      if (rows.length < _attendanceBatchSize) return records;
    }
  });

  /// Saves daily attendance (no course, no period) through the atomic
  /// `save_attendance` RPC: each batch is applied in one transaction and
  /// re-saving a day updates the existing records.
  Future<void> saveDailyAttendance(
    String schoolId,
    DateTime date,
    List<AttendanceEntryInput> entries,
  ) => _guard(() async {
    for (var i = 0; i < entries.length; i += _attendanceBatchSize) {
      final end = (i + _attendanceBatchSize).clamp(0, entries.length);
      await _client.rpc<dynamic>(
        'save_attendance',
        params: {
          'p_school_id': schoolId,
          'p_date': toDateParam(date),
          'p_entries': [
            for (final entry in entries.sublist(i, end)) entry.toJson(),
          ],
        },
      );
    }
  });

  /// Upcoming events from the start of today, staff-only events included.
  Future<List<SchoolEvent>> fetchUpcomingEvents(String schoolId) => _guard(
    () async {
      final rows = await _client
          .from('events')
          .select(SchoolEvent.columns)
          .eq('school_id', schoolId)
          .gte('starts_at', dateOnly(DateTime.now()).toUtc().toIso8601String())
          .order('starts_at', ascending: true)
          .limit(100);
      return rows.map(SchoolEvent.fromJson).toList();
    },
  );
}

/// Builds an ILIKE pattern for PostgREST `or()` filters, or `null` for an
/// empty query. Characters with meaning in the filter grammar or as LIKE
/// wildcards are removed, so user input can't alter the filter.
String? searchPattern(String query) {
  final cleaned = query
      .replaceAll(RegExp(r'[,()*%_\\:"]'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return null;
  return '"%$cleaned%"';
}
