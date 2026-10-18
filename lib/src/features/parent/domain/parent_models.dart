import 'package:flutter/foundation.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/utils/json.dart';
import 'package:school_platform/src/core/utils/names.dart';

// Models for the guardian read API (guardian_* functions). Field names follow
// the function result columns in supabase/migrations/*_guardian_access.sql.

/// A row of `guardian_children()`.
@immutable
class Child {
  const Child({
    required this.studentId,
    required this.schoolId,
    required this.schoolName,
    required this.schoolTimezone,
    required this.enabledModules,
    required this.status,
    this.schoolLogoPath,
    this.schoolPrimaryColor,
    this.firstName,
    this.lastName,
    this.preferredName,
    this.gradeLevel,
    this.section,
    this.photoPath,
    this.relationship,
  });

  factory Child.fromJson(Json json) => Child(
    studentId: json.requireString('student_id'),
    schoolId: json.requireString('school_id'),
    schoolName: json.requireString('school_name'),
    schoolLogoPath: json.optString('school_logo_path'),
    schoolPrimaryColor: json.optString('school_primary_color'),
    schoolTimezone: json.optString('school_timezone') ?? 'UTC',
    enabledModules: SchoolModule.parseList(
      json.optStringList('enabled_modules'),
    ),
    firstName: json.optString('first_name'),
    lastName: json.optString('last_name'),
    preferredName: json.optString('preferred_name'),
    gradeLevel: json.optString('grade_level'),
    section: json.optString('section'),
    photoPath: json.optString('photo_path'),
    status: StudentStatus.fromWire(json.optString('status')),
    relationship: GuardianRelationship.fromWire(json.optString('relationship')),
  );

  final String studentId;
  final String schoolId;
  final String schoolName;
  final String? schoolLogoPath;
  final String? schoolPrimaryColor;
  final String schoolTimezone;
  final Set<SchoolModule> enabledModules;
  final String? firstName;
  final String? lastName;
  final String? preferredName;
  final String? gradeLevel;
  final String? section;
  final String? photoPath;
  final StudentStatus status;
  final GuardianRelationship? relationship;

  String? get displayName =>
      personName(first: firstName, last: lastName, preferred: preferredName);

  /// e.g. "5B" – grade level and section combined.
  String? get classCode {
    final value = [gradeLevel, section].whereType<String>().join();
    return value.isEmpty ? null : value;
  }

  bool hasModule(SchoolModule module) => enabledModules.contains(module);
}

/// A guardian-visible custom field value.
@immutable
class VisibleCustomField {
  const VisibleCustomField({
    required this.key,
    required this.label,
    required this.type,
    required this.value,
  });

  factory VisibleCustomField.fromJson(Json json) => VisibleCustomField(
    key: json.requireString('key'),
    label: json.requireString('label'),
    type: json.requireString('type'),
    value: json['value'],
  );

  final String key;
  final String label;

  /// custom_field_type wire value (text, number, boolean, date, select, ...).
  final String type;
  final Object? value;
}

/// `guardian_student_profile()`.
@immutable
class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.schoolId,
    required this.status,
    required this.customFields,
    this.studentNumber,
    this.firstName,
    this.lastName,
    this.preferredName,
    this.dateOfBirth,
    this.gender,
    this.gradeLevel,
    this.section,
    this.photoPath,
    this.enrolledOn,
  });

  factory StudentProfile.fromJson(Json json) => StudentProfile(
    studentId: json.requireString('student_id'),
    schoolId: json.requireString('school_id'),
    studentNumber: json.optString('student_number'),
    firstName: json.optString('first_name'),
    lastName: json.optString('last_name'),
    preferredName: json.optString('preferred_name'),
    dateOfBirth: json.optDate('date_of_birth'),
    gender: Gender.fromWire(json.optString('gender')),
    gradeLevel: json.optString('grade_level'),
    section: json.optString('section'),
    photoPath: json.optString('photo_path'),
    status: StudentStatus.fromWire(json.optString('status')),
    enrolledOn: json.optDate('enrolled_on'),
    customFields: [
      for (final f in json.optObjectList('custom_fields'))
        VisibleCustomField.fromJson(f),
    ],
  );

  final String studentId;
  final String schoolId;
  final String? studentNumber;
  final String? firstName;
  final String? lastName;
  final String? preferredName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? gradeLevel;
  final String? section;
  final String? photoPath;
  final StudentStatus status;
  final DateTime? enrolledOn;
  final List<VisibleCustomField> customFields;

  String? get displayName =>
      personName(first: firstName, last: lastName, preferred: preferredName);
}

@immutable
class TeacherSummary {
  const TeacherSummary({
    required this.id,
    this.title,
    this.firstName,
    this.lastName,
    this.email,
    this.subject,
    this.photoPath,
  });

  factory TeacherSummary.fromJson(Json json) => TeacherSummary(
    id: json.requireString('id'),
    title: json.optString('title'),
    firstName: json.optString('first_name'),
    lastName: json.optString('last_name'),
    email: json.optString('email'),
    subject: json.optString('subject'),
    photoPath: json.optString('photo_path'),
  );

  final String id;
  final String? title;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? subject;
  final String? photoPath;

  String? get displayName =>
      personName(title: title, first: firstName, last: lastName);
}

/// `guardian_student_courses()`.
@immutable
class EnrolledCourse {
  const EnrolledCourse({
    required this.courseId,
    required this.name,
    required this.teachers,
    this.code,
    this.subject,
    this.color,
    this.termId,
    this.termName,
  });

  factory EnrolledCourse.fromJson(Json json) => EnrolledCourse(
    courseId: json.requireString('course_id'),
    name: json.requireString('name'),
    code: json.optString('code'),
    subject: json.optString('subject'),
    color: json.optString('color'),
    termId: json.optString('term_id'),
    termName: json.optString('term_name'),
    teachers: [
      for (final t in json.optObjectList('teachers'))
        TeacherSummary.fromJson(t),
    ],
  );

  final String courseId;
  final String name;
  final String? code;
  final String? subject;
  final String? color;
  final String? termId;
  final String? termName;
  final List<TeacherSummary> teachers;
}

/// `guardian_student_grades()`.
@immutable
class GradeEntry {
  const GradeEntry({
    required this.gradeId,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.kind,
    required this.maxScore,
    required this.courseId,
    required this.courseName,
    this.assessedOn,
    this.weight,
    this.score,
    this.letter,
    this.comment,
    this.termId,
    this.publishedAt,
  });

  factory GradeEntry.fromJson(Json json) => GradeEntry(
    gradeId: json.requireString('grade_id'),
    assessmentId: json.requireString('assessment_id'),
    assessmentTitle: json.requireString('assessment_title'),
    kind: AssessmentKind.fromWire(json.optString('assessment_kind')),
    assessedOn: json.optDate('assessed_on'),
    maxScore: json.optDouble('max_score') ?? 100,
    weight: json.optDouble('weight'),
    score: json.optDouble('score'),
    letter: json.optString('letter'),
    comment: json.optString('comment'),
    courseId: json.requireString('course_id'),
    courseName: json.requireString('course_name'),
    termId: json.optString('term_id'),
    publishedAt: json.optDateTime('published_at'),
  );

  final String gradeId;
  final String assessmentId;
  final String assessmentTitle;
  final AssessmentKind kind;
  final DateTime? assessedOn;
  final double maxScore;
  final double? weight;
  final double? score;
  final String? letter;
  final String? comment;
  final String courseId;
  final String courseName;
  final String? termId;
  final DateTime? publishedAt;

  /// Score as a percentage of the maximum, when a numeric score exists.
  double? get percent =>
      (score == null || maxScore <= 0) ? null : score! / maxScore * 100;
}

/// Grades of one course with a (weighted) average percentage.
@immutable
class CourseGrades {
  const CourseGrades({
    required this.courseId,
    required this.courseName,
    required this.grades,
  });

  final String courseId;
  final String courseName;
  final List<GradeEntry> grades;

  /// Weighted mean of percentages. Assessments without a weight count as 1.
  double? get averagePercent {
    var total = 0.0;
    var weights = 0.0;
    for (final grade in grades) {
      final percent = grade.percent;
      if (percent == null) continue;
      final weight = grade.weight ?? 1;
      if (weight <= 0) continue;
      total += percent * weight;
      weights += weight;
    }
    return weights == 0 ? null : total / weights;
  }

  /// Groups grades by course, ordered by course name.
  static List<CourseGrades> group(List<GradeEntry> grades) {
    final byCourse = <String, List<GradeEntry>>{};
    final names = <String, String>{};
    for (final grade in grades) {
      byCourse.putIfAbsent(grade.courseId, () => []).add(grade);
      names[grade.courseId] = grade.courseName;
    }
    final result =
        [
          for (final entry in byCourse.entries)
            CourseGrades(
              courseId: entry.key,
              courseName: names[entry.key]!,
              grades: entry.value,
            ),
        ]..sort(
          (a, b) =>
              a.courseName.toLowerCase().compareTo(b.courseName.toLowerCase()),
        );
    return result;
  }
}

/// `guardian_student_attendance()`.
@immutable
class AttendanceEntry {
  const AttendanceEntry({
    required this.recordId,
    required this.attendedOn,
    required this.status,
    this.courseId,
    this.courseName,
    this.period,
    this.minutesLate,
    this.note,
  });

  factory AttendanceEntry.fromJson(Json json) => AttendanceEntry(
    recordId: json.requireString('record_id'),
    attendedOn: json.optDate('attended_on')!,
    status:
        AttendanceStatus.fromWire(json.optString('status')) ??
        AttendanceStatus.present,
    courseId: json.optString('course_id'),
    courseName: json.optString('course_name'),
    period: json.optString('period'),
    minutesLate: json.optInt('minutes_late'),
    note: json.optString('note'),
  );

  final String recordId;
  final DateTime attendedOn;
  final AttendanceStatus status;
  final String? courseId;
  final String? courseName;
  final String? period;
  final int? minutesLate;
  final String? note;
}

/// `guardian_student_attendance_summary()` as counts per status.
@immutable
class AttendanceSummary {
  const AttendanceSummary(this.counts);

  factory AttendanceSummary.fromRows(List<Json> rows) => AttendanceSummary({
    for (final row in rows)
      ?AttendanceStatus.fromWire(row.optString('status')): row.requireInt(
        'total',
      ),
  });

  final Map<AttendanceStatus, int> counts;

  int count(AttendanceStatus status) => counts[status] ?? 0;

  int get total => counts.values.fold(0, (a, b) => a + b);
}

/// `guardian_student_notes()`.
@immutable
class GuardianNote {
  const GuardianNote({
    required this.noteId,
    required this.body,
    required this.createdAt,
    this.title,
    this.category,
    this.teacherName,
  });

  factory GuardianNote.fromJson(Json json) => GuardianNote(
    noteId: json.requireString('note_id'),
    title: json.optString('title'),
    body: json.requireString('body'),
    category: json.optString('category'),
    createdAt: json.requireDateTime('created_at'),
    teacherName: json.optString('teacher_name'),
  );

  final String noteId;
  final String? title;
  final String body;
  final String? category;
  final DateTime createdAt;
  final String? teacherName;
}

/// `guardian_student_events()`.
@immutable
class GuardianEvent {
  const GuardianEvent({
    required this.eventId,
    required this.title,
    required this.startsAt,
    required this.allDay,
    this.description,
    this.location,
    this.endsAt,
    this.color,
    this.courseId,
    this.courseName,
  });

  factory GuardianEvent.fromJson(Json json) => GuardianEvent(
    eventId: json.requireString('event_id'),
    title: json.requireString('title'),
    description: json.optString('description'),
    location: json.optString('location'),
    startsAt: json.requireDateTime('starts_at'),
    endsAt: json.optDateTime('ends_at'),
    allDay: json.optBool('all_day') ?? false,
    color: json.optString('color'),
    courseId: json.optString('course_id'),
    courseName: json.optString('course_name'),
  );

  final String eventId;
  final String title;
  final String? description;
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String? color;
  final String? courseId;
  final String? courseName;
}
