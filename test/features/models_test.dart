import 'package:flutter_test/flutter_test.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';

void main() {
  group('AccountContext', () {
    test(
      'a connected guardian can use the parent side before child assignment',
      () {
        final context = AccountContext.fromJson(const {
          'user_id': 'u1',
          'guardian_schools': [
            {'school_id': 's1', 'school_name': 'School A'},
          ],
          'children_count': 0,
        });
        expect(context.guardianSchools.single.schoolName, 'School A');
        expect(context.availableSides, {AppSide.parent});
      },
    );

    test('older account payloads remain compatible', () {
      final context = AccountContext.fromJson(const {
        'user_id': 'u1',
        'children_count': 1,
      });
      expect(context.guardianSchools, isEmpty);
      expect(context.availableSides, {AppSide.parent});
    });

    test('parses my_account_context() and derives sides', () {
      final context = AccountContext.fromJson(const {
        'user_id': 'u1',
        'is_platform_admin': false,
        'memberships': [
          {
            'school_id': 's1',
            'school_name': 'Atatürk İlkokulu',
            'slug': 'ataturk',
            'role': 'admin',
            'logo_path': null,
            'primary_color': '#1E40AF',
            'default_locale': 'tr',
            'timezone': 'Europe/Istanbul',
            'enabled_modules': ['grades', 'attendance', 'a_future_module'],
          },
        ],
        'children_count': 2,
      });
      final membership = context.memberships.single;
      expect(membership.role, SchoolRole.admin);
      expect(membership.enabledModules, {
        SchoolModule.grades,
        SchoolModule.attendance,
      });
      expect(context.availableSides, {AppSide.school, AppSide.parent});
      expect(context.membershipFor('s1'), same(membership));
      expect(context.membershipFor('other'), isNull);
    });

    test('unknown roles degrade to the least privileged role', () {
      expect(SchoolRole.fromWire('teacher'), SchoolRole.staff);
    });

    test('a malformed payload fails loudly', () {
      expect(
        () => AccountContext.fromJson(const {'user_id': 42}),
        throwsFormatException,
      );
    });
  });

  group('normalizeInviteCode', () {
    test('accepts formatting variations and Crockford substitutions', () {
      expect(normalizeInviteCode('abcde-fghjk'), 'ABCDE-FGHJK');
      expect(normalizeInviteCode(' 7k3m9 q2x4t '), '7K3M9-Q2X4T');
      expect(normalizeInviteCode('O1IL0-00000'), '01110-00000');
    });

    test('rejects wrong lengths and the excluded letter U', () {
      expect(normalizeInviteCode('ABCDE'), isNull);
      expect(normalizeInviteCode('ABCDE-FGHJKM'), isNull);
      expect(normalizeInviteCode('UUUUU-UUUUU'), isNull);
    });

    test('redemption status parsing defaults to invalid', () {
      expect(
        InviteRedemptionStatus.fromWire('linked'),
        InviteRedemptionStatus.linked,
      );
      expect(
        InviteRedemptionStatus.fromWire('already_linked'),
        InviteRedemptionStatus.alreadyLinked,
      );
      expect(
        InviteRedemptionStatus.fromWire('rate_limited'),
        InviteRedemptionStatus.rateLimited,
      );
      expect(
        InviteRedemptionStatus.fromWire('something_else'),
        InviteRedemptionStatus.invalid,
      );
    });
  });

  group('parent models', () {
    test('Child parses guardian_children() rows', () {
      final child = Child.fromJson(const {
        'student_id': 'st1',
        'school_id': 's1',
        'school_name': 'School A',
        'school_logo_path': 's1/branding/logo.png',
        'school_primary_color': '#123456',
        'school_timezone': 'Europe/Istanbul',
        'enabled_modules': ['notes'],
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'preferred_name': null,
        'grade_level': '5',
        'section': 'B',
        'photo_path': null,
        'status': 'active',
        'relationship': 'mother',
      });
      expect(child.displayName, 'Ada Lovelace');
      expect(child.classCode, '5B');
      expect(child.relationship, GuardianRelationship.mother);
      expect(child.hasModule(SchoolModule.notes), isTrue);
      expect(child.hasModule(SchoolModule.grades), isFalse);
    });

    test('StudentProfile keeps guardian-visible custom fields in order', () {
      final profile = StudentProfile.fromJson(const {
        'student_id': 'st1',
        'school_id': 's1',
        'status': 'graduated',
        'date_of_birth': '2015-11-07',
        'custom_fields': [
          {
            'key': 'allergies',
            'label': 'Allergies',
            'type': 'text',
            'value': 'Peanuts',
          },
          {
            'key': 'clubs',
            'label': 'Clubs',
            'type': 'multi_select',
            'value': ['Chess'],
          },
        ],
      });
      expect(profile.status, StudentStatus.graduated);
      expect(profile.dateOfBirth, DateTime(2015, 11, 7));
      expect(profile.customFields.map((f) => f.key), ['allergies', 'clubs']);
    });

    GradeEntry grade(
      String course,
      double? score, {
      double max = 100,
      double? weight,
    }) => GradeEntry.fromJson({
      'grade_id': '$course-$score',
      'assessment_id': 'a',
      'assessment_title': 'Exam',
      'assessment_kind': 'term_grade',
      'max_score': max,
      'weight': weight,
      'score': score,
      'course_id': course,
      'course_name': course == 'm' ? 'Mathematics' : 'Art',
    });

    test('grades group by course with a weighted average', () {
      final grouped = CourseGrades.group([
        grade('m', 90),
        grade('a', 8, max: 10),
        grade('m', 40, max: 50, weight: 3),
        grade('m', null),
      ]);
      expect(grouped.map((c) => c.courseName), ['Art', 'Mathematics']);
      expect(grouped.first.averagePercent, 80);
      // (90 * 1 + 80 * 3) / 4 = 82.5; the letter-only grade is ignored.
      expect(grouped.last.averagePercent, 82.5);
      expect(grouped.last.grades.first.kind, AssessmentKind.termGrade);
    });

    test('attendance summary counts per status', () {
      final summary = AttendanceSummary.fromRows(const [
        {'status': 'present', 'total': 18},
        {'status': 'absent', 'total': 2},
      ]);
      expect(summary.count(AttendanceStatus.present), 18);
      expect(summary.count(AttendanceStatus.late), 0);
      expect(summary.total, 20);
    });

    test('notes and events parse timestamps to local time', () {
      final note = GuardianNote.fromJson(const {
        'note_id': 'n1',
        'body': 'Great week',
        'created_at': '2026-10-01T08:00:00+00:00',
      });
      expect(note.createdAt.isUtc, isFalse);
      expect(note.createdAt.toUtc(), DateTime.utc(2026, 10, 1, 8));

      final event = GuardianEvent.fromJson(const {
        'event_id': 'e1',
        'title': 'Sports day',
        'starts_at': '2026-10-21T09:00:00Z',
        'all_day': true,
      });
      expect(event.allDay, isTrue);
      expect(event.endsAt, isNull);
    });
  });

  group('school models', () {
    test('StudentDraft serializes blanks as null and dates as YYYY-MM-DD', () {
      final draft = StudentDraft(
        firstName: '  Marie ',
        lastName: '',
        dateOfBirth: DateTime(2015, 1, 9),
        gender: Gender.female,
        status: StudentStatus.inactive,
      );
      final json = draft.toJson();
      expect(json['first_name'], 'Marie');
      expect(json['last_name'], isNull);
      expect(json['date_of_birth'], '2015-01-09');
      expect(json['gender'], 'female');
      expect(json['status'], 'inactive');
      expect(json.containsKey('school_id'), isFalse);
      expect(json.containsKey('custom_fields'), isFalse);
    });

    test('identifiable rule mirrors students_identifiable', () {
      expect(const StudentDraft().isIdentifiable, isFalse);
      expect(const StudentDraft(firstName: ' ').isIdentifiable, isFalse);
      expect(const StudentDraft(studentNumber: 'A-1').isIdentifiable, isTrue);
    });

    test('StudentRecord parses embedded guardians, primary first', () {
      final record = StudentRecord.fromJson(const {
        'id': 'st1',
        'school_id': 's1',
        'student_number': 'A-001',
        'status': 'active',
        'custom_fields': {'bus_route': 'North'},
        'updated_at': '2026-10-01T08:00:00Z',
        'student_guardians': [
          {
            'relationship': 'father',
            'is_primary': false,
            'guardians': {'id': 'g2', 'first_name': 'Pierre', 'user_id': null},
          },
          {
            'relationship': 'mother',
            'is_primary': true,
            'guardians': {
              'id': 'g1',
              'email': 'marie@test.dev',
              'user_id': 'u1',
            },
          },
        ],
      });
      expect(record.displayName, 'A-001');
      expect(record.guardians.map((g) => g.guardianId), ['g1', 'g2']);
      expect(record.guardians.first.isAppLinked, isTrue);
      expect(record.guardians.first.displayName, 'marie@test.dev');
      expect(record.customFields, {'bus_route': 'North'});
    });

    test(
      'DashboardStats parses today attendance and ignores unknown statuses',
      () {
        final stats = DashboardStats.fromJson(const {
          'students_active': 120,
          'students_total': 130,
          'teachers_total': 12,
          'courses_total': 30,
          'guardians_total': 200,
          'guardians_linked': 150,
          'attendance_today': {'present': 110, 'absent': 5, 'unknown': 1},
          'upcoming_events': 3,
        });
        expect(stats.attendanceToday, {
          AttendanceStatus.present: 110,
          AttendanceStatus.absent: 5,
        });
        expect(stats.attendanceTodayTotal, 115);
      },
    );

    test('SchoolEvent reads the embedded course name', () {
      final event = SchoolEvent.fromJson(const {
        'id': 'e1',
        'title': 'Olympiad',
        'starts_at': '2026-10-21T09:00:00Z',
        'visible_to_guardians': false,
        'courses': {'name': 'Mathematics'},
      });
      expect(event.courseName, 'Mathematics');
      expect(event.visibleToGuardians, isFalse);
    });
  });
}
