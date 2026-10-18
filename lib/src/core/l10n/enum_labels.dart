import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';

extension StudentStatusLabel on StudentStatus {
  String label(AppLocalizations l10n) => switch (this) {
    StudentStatus.active => l10n.studentStatusActive,
    StudentStatus.inactive => l10n.studentStatusInactive,
    StudentStatus.graduated => l10n.studentStatusGraduated,
    StudentStatus.transferred => l10n.studentStatusTransferred,
  };
}

extension GenderLabel on Gender {
  String label(AppLocalizations l10n) => switch (this) {
    Gender.female => l10n.genderFemale,
    Gender.male => l10n.genderMale,
    Gender.other => l10n.genderOther,
    Gender.undisclosed => l10n.genderUndisclosed,
  };
}

extension AttendanceStatusLabel on AttendanceStatus {
  String label(AppLocalizations l10n) => switch (this) {
    AttendanceStatus.present => l10n.attendancePresent,
    AttendanceStatus.absent => l10n.attendanceAbsent,
    AttendanceStatus.late => l10n.attendanceLate,
    AttendanceStatus.excused => l10n.attendanceExcused,
  };
}

extension GuardianRelationshipLabel on GuardianRelationship {
  String label(AppLocalizations l10n) => switch (this) {
    GuardianRelationship.mother => l10n.relationshipMother,
    GuardianRelationship.father => l10n.relationshipFather,
    GuardianRelationship.guardian => l10n.relationshipGuardian,
    GuardianRelationship.grandparent => l10n.relationshipGrandparent,
    GuardianRelationship.sibling => l10n.relationshipSibling,
    GuardianRelationship.other => l10n.relationshipOther,
  };
}

extension AssessmentKindLabel on AssessmentKind {
  String label(AppLocalizations l10n) => switch (this) {
    AssessmentKind.exam => l10n.assessmentExam,
    AssessmentKind.quiz => l10n.assessmentQuiz,
    AssessmentKind.homework => l10n.assessmentHomework,
    AssessmentKind.project => l10n.assessmentProject,
    AssessmentKind.participation => l10n.assessmentParticipation,
    AssessmentKind.termGrade => l10n.assessmentTermGrade,
    AssessmentKind.other => l10n.assessmentOther,
  };
}

extension SchoolRoleLabel on SchoolRole {
  String label(AppLocalizations l10n) => switch (this) {
    SchoolRole.admin => l10n.roleAdmin,
    SchoolRole.staff => l10n.roleStaff,
  };
}
