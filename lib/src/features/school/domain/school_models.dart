import 'package:flutter/foundation.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/utils/dates.dart';
import 'package:school_platform/src/core/utils/json.dart';
import 'package:school_platform/src/core/utils/names.dart';

/// `school_dashboard_stats()`.
@immutable
class DashboardStats {
  const DashboardStats({
    required this.studentsActive,
    required this.studentsTotal,
    required this.teachersTotal,
    required this.coursesTotal,
    required this.guardiansTotal,
    required this.guardiansLinked,
    required this.attendanceToday,
    required this.upcomingEvents,
  });

  factory DashboardStats.fromJson(Json json) {
    final today = json.optObject('attendance_today') ?? const {};
    return DashboardStats(
      studentsActive: json.requireInt('students_active'),
      studentsTotal: json.requireInt('students_total'),
      teachersTotal: json.requireInt('teachers_total'),
      coursesTotal: json.requireInt('courses_total'),
      guardiansTotal: json.requireInt('guardians_total'),
      guardiansLinked: json.requireInt('guardians_linked'),
      attendanceToday: {
        for (final entry in today.entries)
          ?AttendanceStatus.fromWire(entry.key): (entry.value as num).toInt(),
      },
      upcomingEvents: json.requireInt('upcoming_events'),
    );
  }

  final int studentsActive;
  final int studentsTotal;
  final int teachersTotal;
  final int coursesTotal;
  final int guardiansTotal;
  final int guardiansLinked;
  final Map<AttendanceStatus, int> attendanceToday;
  final int upcomingEvents;

  int get attendanceTodayTotal =>
      attendanceToday.values.fold(0, (a, b) => a + b);
}

/// Columns needed for student lists.
@immutable
class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.status,
    this.studentNumber,
    this.firstName,
    this.lastName,
    this.preferredName,
    this.gradeLevel,
    this.section,
    this.photoPath,
  });

  factory StudentSummary.fromJson(Json json) => StudentSummary(
    id: json.requireString('id'),
    studentNumber: json.optString('student_number'),
    firstName: json.optString('first_name'),
    lastName: json.optString('last_name'),
    preferredName: json.optString('preferred_name'),
    gradeLevel: json.optString('grade_level'),
    section: json.optString('section'),
    photoPath: json.optString('photo_path'),
    status: StudentStatus.fromWire(json.optString('status')),
  );

  static const columns =
      'id,student_number,first_name,last_name,preferred_name,grade_level,'
      'section,photo_path,status';

  final String id;
  final String? studentNumber;
  final String? firstName;
  final String? lastName;
  final String? preferredName;
  final String? gradeLevel;
  final String? section;
  final String? photoPath;
  final StudentStatus status;

  /// Name, falling back to the student number (records may have only one).
  String? get displayName =>
      personName(first: firstName, last: lastName, preferred: preferredName) ??
      studentNumber;

  String? get classCode {
    final value = [gradeLevel, section].whereType<String>().join();
    return value.isEmpty ? null : value;
  }
}

/// A guardian linked to a student, as seen by staff.
@immutable
class GuardianLink {
  const GuardianLink({
    required this.guardianId,
    required this.isPrimary,
    required this.isAppLinked,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.relationship,
  });

  factory GuardianLink.fromJson(Json json) {
    final guardian = json.optObject('guardians') ?? const {};
    return GuardianLink(
      guardianId: guardian.requireString('id'),
      firstName: guardian.optString('first_name'),
      lastName: guardian.optString('last_name'),
      email: guardian.optString('email'),
      phone: guardian.optString('phone'),
      isAppLinked: guardian['user_id'] != null,
      relationship: GuardianRelationship.fromWire(
        json.optString('relationship'),
      ),
      isPrimary: json.optBool('is_primary') ?? false,
    );
  }

  final String guardianId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final GuardianRelationship? relationship;
  final bool isPrimary;
  final bool isAppLinked;

  String? get displayName =>
      personName(first: firstName, last: lastName) ?? email ?? phone;
}

/// Full student record for staff.
@immutable
class StudentRecord {
  const StudentRecord({
    required this.id,
    required this.schoolId,
    required this.draft,
    required this.guardians,
    required this.customFields,
    required this.updatedAt,
  });

  factory StudentRecord.fromJson(Json json) => StudentRecord(
    id: json.requireString('id'),
    schoolId: json.requireString('school_id'),
    draft: StudentDraft.fromJson(json),
    guardians: [
      for (final link in json.optObjectList('student_guardians'))
        GuardianLink.fromJson(link),
    ]..sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0)),
    customFields: json.optObject('custom_fields') ?? const {},
    updatedAt: json.requireDateTime('updated_at'),
  );

  static const columns =
      'id,school_id,student_number,first_name,last_name,preferred_name,'
      'date_of_birth,gender,grade_level,section,email,phone,address,'
      'photo_path,enrolled_on,status,notes,custom_fields,updated_at,'
      'student_guardians(relationship,is_primary,'
      'guardians(id,first_name,last_name,email,phone,user_id))';

  final String id;
  final String schoolId;
  final StudentDraft draft;
  final List<GuardianLink> guardians;
  final Json customFields;
  final DateTime updatedAt;

  String? get displayName =>
      personName(
        first: draft.firstName,
        last: draft.lastName,
        preferred: draft.preferredName,
      ) ??
      draft.studentNumber;
}

/// The editable columns of a student. Every field is optional; the database
/// requires at least one of first name, last name or student number.
@immutable
class StudentDraft {
  const StudentDraft({
    this.studentNumber,
    this.firstName,
    this.lastName,
    this.preferredName,
    this.dateOfBirth,
    this.gender,
    this.gradeLevel,
    this.section,
    this.email,
    this.phone,
    this.address,
    this.enrolledOn,
    this.status = StudentStatus.active,
    this.notes,
    this.photoPath,
  });

  factory StudentDraft.fromJson(Json json) => StudentDraft(
    studentNumber: json.optString('student_number'),
    firstName: json.optString('first_name'),
    lastName: json.optString('last_name'),
    preferredName: json.optString('preferred_name'),
    dateOfBirth: json.optDate('date_of_birth'),
    gender: Gender.fromWire(json.optString('gender')),
    gradeLevel: json.optString('grade_level'),
    section: json.optString('section'),
    email: json.optString('email'),
    phone: json.optString('phone'),
    address: json.optString('address'),
    enrolledOn: json.optDate('enrolled_on'),
    status: StudentStatus.fromWire(json.optString('status')),
    notes: json.optString('notes'),
    photoPath: json.optString('photo_path'),
  );

  final String? studentNumber;
  final String? firstName;
  final String? lastName;
  final String? preferredName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? gradeLevel;
  final String? section;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime? enrolledOn;
  final StudentStatus status;
  final String? notes;

  /// Read-only here; photos are uploaded on the web panel.
  final String? photoPath;

  /// Mirrors the `students_identifiable` check constraint.
  bool get isIdentifiable => [
    firstName,
    lastName,
    studentNumber,
  ].any((v) => v != null && v.trim().isNotEmpty);

  /// Columns for insert/update. `school_id` and `custom_fields` are not
  /// included: the former is immutable, the latter is managed on the web.
  Json toJson() => {
    'student_number': blankToNull(studentNumber),
    'first_name': blankToNull(firstName),
    'last_name': blankToNull(lastName),
    'preferred_name': blankToNull(preferredName),
    'date_of_birth': dateOfBirth == null ? null : toDateParam(dateOfBirth!),
    'gender': gender?.wire,
    'grade_level': blankToNull(gradeLevel),
    'section': blankToNull(section),
    'email': blankToNull(email),
    'phone': blankToNull(phone),
    'address': blankToNull(address),
    'enrolled_on': enrolledOn == null ? null : toDateParam(enrolledOn!),
    'status': status.wire,
    'notes': blankToNull(notes),
  };
}

/// A `student_notes` row as seen by staff.
@immutable
class StaffNote {
  const StaffNote({
    required this.id,
    required this.body,
    required this.visibleToGuardians,
    required this.createdAt,
    this.title,
    this.category,
  });

  factory StaffNote.fromJson(Json json) => StaffNote(
    id: json.requireString('id'),
    title: json.optString('title'),
    body: json.requireString('body'),
    category: json.optString('category'),
    visibleToGuardians: json.optBool('visible_to_guardians') ?? false,
    createdAt: json.requireDateTime('created_at'),
  );

  static const columns =
      'id,title,body,category,visible_to_guardians,created_at';

  final String id;
  final String? title;
  final String body;
  final String? category;
  final bool visibleToGuardians;
  final DateTime createdAt;
}

/// An existing daily attendance record (course_id and period are null).
@immutable
class DailyAttendanceRecord {
  const DailyAttendanceRecord({
    required this.studentId,
    required this.status,
    this.minutesLate,
    this.note,
  });

  factory DailyAttendanceRecord.fromJson(Json json) => DailyAttendanceRecord(
    studentId: json.requireString('student_id'),
    status:
        AttendanceStatus.fromWire(json.optString('status')) ??
        AttendanceStatus.present,
    minutesLate: json.optInt('minutes_late'),
    note: json.optString('note'),
  );

  static const columns = 'student_id,status,minutes_late,note';

  final String studentId;
  final AttendanceStatus status;
  final int? minutesLate;
  final String? note;
}

/// One entry for the `save_attendance` RPC. A `null` [status] deletes the
/// student's record for the slot. The RPC replaces the whole record, so
/// [minutesLate] and [note] must carry the existing values to keep them.
@immutable
class AttendanceEntryInput {
  const AttendanceEntryInput({
    required this.studentId,
    required this.status,
    this.minutesLate,
    this.note,
  });

  final String studentId;
  final AttendanceStatus? status;
  final int? minutesLate;
  final String? note;

  Json toJson() => {
    'student_id': studentId,
    'status': status?.wire,
    // The database keeps minutes_late only for 'late'.
    if (status == AttendanceStatus.late) 'minutes_late': minutesLate,
    'note': note,
  };
}

/// An `events` row as seen by staff.
@immutable
class SchoolEvent {
  const SchoolEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.allDay,
    required this.visibleToGuardians,
    this.endsAt,
    this.location,
    this.color,
    this.courseName,
  });

  factory SchoolEvent.fromJson(Json json) => SchoolEvent(
    id: json.requireString('id'),
    title: json.requireString('title'),
    startsAt: json.requireDateTime('starts_at'),
    endsAt: json.optDateTime('ends_at'),
    allDay: json.optBool('all_day') ?? false,
    location: json.optString('location'),
    color: json.optString('color'),
    visibleToGuardians: json.optBool('visible_to_guardians') ?? true,
    courseName: json.optObject('courses')?.optString('name'),
  );

  static const columns =
      'id,title,starts_at,ends_at,all_day,location,color,'
      'visible_to_guardians,courses(name)';

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool allDay;
  final String? location;
  final String? color;
  final bool visibleToGuardians;
  final String? courseName;
}
