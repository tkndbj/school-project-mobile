import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/core/utils/json.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final parentRepositoryProvider = Provider<ParentRepository>(
  (ref) => ParentRepository(ref.watch(supabaseClientProvider)),
);

/// Read-only access to a parent's children through the guardian_* functions.
/// Parents have no direct table access; the database returns exactly what a
/// parent may see. Throws [AppFailure]s only.
class ParentRepository {
  ParentRepository(this._client);

  final SupabaseClient _client;

  static const notesPageSize = 20;
  static const _timeout = Duration(seconds: 20);

  Future<List<Json>> _rows(
    String function, [
    Map<String, dynamic>? params,
  ]) async {
    try {
      final rows = <Json>[];
      // The Data API caps each response. Fetch fresh builders for every page
      // so a long grade or attendance history is never silently truncated.
      for (var from = 0; ; from += 1000) {
        final result = await _client
            .rpc<dynamic>(function, params: params)
            .range(from, from + 999)
            .timeout(_timeout);
        final page = parseList(result, (json) => json);
        rows.addAll(page);
        if (page.length < 1000) return rows;
      }
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<List<Child>> fetchChildren() async {
    final children =
        (await _rows('guardian_children')).map(Child.fromJson).toList()..sort(
          (a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''),
        );
    return children;
  }

  Future<StudentProfile> fetchProfile(String studentId) async {
    final rows = await _rows('guardian_student_profile', {
      'p_student_id': studentId,
    });
    if (rows.isEmpty) throw const NotFoundFailure();
    return StudentProfile.fromJson(rows.first);
  }

  Future<List<EnrolledCourse>> fetchCourses(String studentId) async =>
      (await _rows('guardian_student_courses', {
        'p_student_id': studentId,
      })).map(EnrolledCourse.fromJson).toList();

  Future<List<GradeEntry>> fetchGrades(
    String studentId, {
    String? termId,
  }) async => (await _rows('guardian_student_grades', {
    'p_student_id': studentId,
    'p_term_id': termId,
  })).map(GradeEntry.fromJson).toList();

  Future<List<AttendanceEntry>> fetchAttendance(
    String studentId,
    MonthRange month,
  ) async => (await _rows('guardian_student_attendance', {
    'p_student_id': studentId,
    'p_from': toDateParam(month.first),
    'p_to': toDateParam(month.last),
  })).map(AttendanceEntry.fromJson).toList();

  Future<AttendanceSummary> fetchAttendanceSummary(
    String studentId,
    MonthRange month,
  ) async => AttendanceSummary.fromRows(
    await _rows('guardian_student_attendance_summary', {
      'p_student_id': studentId,
      'p_from': toDateParam(month.first),
      'p_to': toDateParam(month.last),
    }),
  );

  /// Keyset pagination: pass the `createdAt` of the last note to get older
  /// ones.
  Future<List<GuardianNote>> fetchNotes(
    String studentId, {
    DateTime? before,
    String? beforeId,
  }) async => (await _rows('guardian_student_notes_page', {
    'p_student_id': studentId,
    'p_before': before?.toUtc().toIso8601String(),
    'p_before_id': beforeId,
    'p_limit': notesPageSize,
  })).map(GuardianNote.fromJson).toList();

  Future<List<GuardianEvent>> fetchEvents(
    String studentId, {
    required DateTime from,
    required DateTime to,
  }) async => (await _rows('guardian_student_events', {
    'p_student_id': studentId,
    'p_from': from.toUtc().toIso8601String(),
    'p_to': to.toUtc().toIso8601String(),
  })).map(GuardianEvent.fromJson).toList();
}
