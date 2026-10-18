// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'School Platform';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get notSet => 'Not set';

  @override
  String get signOut => 'Sign out';

  @override
  String get settings => 'Settings';

  @override
  String get manageOnWeb => 'Manage this on the web panel';

  @override
  String get manageOnWebDetails =>
      'Grade books, imports, custom fields and school settings are available on the web panel.';

  @override
  String get moduleDisabled => 'This feature is turned off for your school.';

  @override
  String get errorPermissionDenied => 'You don\'t have permission to do that.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorNotFound => 'We couldn\'t find what you were looking for.';

  @override
  String get errorNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get errorServer =>
      'The server had a problem. Please try again shortly.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorInvalidInput => 'Some values have an invalid format.';

  @override
  String get errorDuplicate => 'A record with the same details already exists.';

  @override
  String get errorDuplicateStudentNumber =>
      'Another student already has this student number.';

  @override
  String get errorConstraint => 'Some values are not allowed.';

  @override
  String get errorStudentIdentifiable =>
      'Enter at least a first name, last name or student number.';

  @override
  String get errorReference =>
      'A related record no longer exists. Refresh and try again.';

  @override
  String errorCustomField(String field) {
    return 'The value of \"$field\" is not valid.';
  }

  @override
  String get errorInvalidSetting => 'This setting value is not valid.';

  @override
  String get errorSchoolRequiresAdmin =>
      'A school must always have at least one admin.';

  @override
  String get errorInvalidDateRange => 'The selected date range is not valid.';

  @override
  String get errorImport => 'The import data is not in the expected format.';

  @override
  String get errorAuthInvalidCredentials => 'Incorrect email or password.';

  @override
  String get errorAuthEmailNotConfirmed =>
      'Please confirm your email address first.';

  @override
  String get errorAuthUserBanned => 'This account has been disabled.';

  @override
  String get errorAuthRateLimited =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorGoogleNotAvailable =>
      'Google sign-in is not available on this device.';

  @override
  String get errorAuthUnknown => 'Sign-in failed. Please try again.';

  @override
  String get errorAccountDeletionBlocked =>
      'You are the only admin of a school. Transfer the admin role to someone else on the web panel first.';

  @override
  String get signInTitle => 'Welcome';

  @override
  String get signInSubtitle =>
      'Parents: continue with Google. School staff can also sign in with the email and password from their invitation.';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get orDivider => 'or';

  @override
  String get staffSignInHeading => 'School staff sign-in';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordBody =>
      'We\'ll email you a link to choose a new password.';

  @override
  String get resetPasswordSend => 'Send link';

  @override
  String resetPasswordSent(String email) {
    return 'If an account exists for $email, a reset link is on its way.';
  }

  @override
  String get validationEmail => 'Enter a valid email address';

  @override
  String get validationRequired => 'Required';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get loadingAccount => 'Loading your account…';

  @override
  String get accountLoadFailed => 'We couldn\'t load your account.';

  @override
  String get platformAdminTitle => 'Use the web panel';

  @override
  String get platformAdminBody =>
      'Platform administration is only available on the web panel.';

  @override
  String get chooseSideTitle => 'How would you like to continue?';

  @override
  String get sideSchool => 'School';

  @override
  String get sideSchoolDescription => 'Manage students, attendance and notes';

  @override
  String get sideParent => 'Parent';

  @override
  String get sideParentDescription => 'Follow your children\'s school life';

  @override
  String get switchToSchool => 'Switch to school';

  @override
  String get switchToParent => 'Switch to parent';

  @override
  String get onboardingTitle => 'Connect to your child\'s school';

  @override
  String onboardingBody(String email) {
    return 'Your account is connected automatically once your child\'s school registers the email address you signed in with ($email). If the school gave you an invite code, enter it below.';
  }

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteCodeHint => 'XXXXX-XXXXX';

  @override
  String get inviteCodeInvalidFormat =>
      'Invite codes have 10 letters or digits.';

  @override
  String get redeemButton => 'Connect';

  @override
  String inviteLinked(String school) {
    return 'Connected to $school.';
  }

  @override
  String get inviteInvalid => 'This code is invalid or has expired.';

  @override
  String get inviteAlreadyLinked =>
      'This invite was already used by another account. Ask the school for a new code.';

  @override
  String get inviteRateLimited =>
      'Too many attempts. Please try again in an hour.';

  @override
  String get checkAgain => 'Check again';

  @override
  String get addChildWithCode => 'Add a child with an invite code';

  @override
  String get childrenTitle => 'My children';

  @override
  String get noChildren => 'No children are connected to your account yet.';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabGrades => 'Grades';

  @override
  String get tabAttendance => 'Attendance';

  @override
  String get tabNotes => 'Notes';

  @override
  String get tabEvents => 'Events';

  @override
  String get tabCourses => 'Courses';

  @override
  String get profileSection => 'Profile';

  @override
  String get studentNumber => 'Student number';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get gradeLevel => 'Grade';

  @override
  String get section => 'Section';

  @override
  String classLabel(String grade) {
    return 'Class $grade';
  }

  @override
  String get enrolledOn => 'Enrolled on';

  @override
  String get statusLabel => 'Status';

  @override
  String get attendanceThisMonth => 'Attendance this month';

  @override
  String get additionalInfo => 'Additional information';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get studentStatusActive => 'Active';

  @override
  String get studentStatusInactive => 'Inactive';

  @override
  String get studentStatusGraduated => 'Graduated';

  @override
  String get studentStatusTransferred => 'Transferred';

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderMale => 'Male';

  @override
  String get genderOther => 'Other';

  @override
  String get genderUndisclosed => 'Prefer not to say';

  @override
  String get relationshipMother => 'Mother';

  @override
  String get relationshipFather => 'Father';

  @override
  String get relationshipGuardian => 'Guardian';

  @override
  String get relationshipGrandparent => 'Grandparent';

  @override
  String get relationshipSibling => 'Sibling';

  @override
  String get relationshipOther => 'Other';

  @override
  String get attendancePresent => 'Present';

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceLate => 'Late';

  @override
  String get attendanceExcused => 'Excused';

  @override
  String minutesLate(int minutes) {
    return '$minutes min late';
  }

  @override
  String get dailyAttendance => 'Daily';

  @override
  String get noGrades => 'No published grades yet.';

  @override
  String averagePercent(String percent) {
    return 'Average $percent%';
  }

  @override
  String scoreOutOf(String score, String max) {
    return '$score / $max';
  }

  @override
  String get assessmentExam => 'Exam';

  @override
  String get assessmentQuiz => 'Quiz';

  @override
  String get assessmentHomework => 'Homework';

  @override
  String get assessmentProject => 'Project';

  @override
  String get assessmentParticipation => 'Participation';

  @override
  String get assessmentTermGrade => 'Term grade';

  @override
  String get assessmentOther => 'Other';

  @override
  String get noAttendance => 'No attendance records for this month.';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get noNotes => 'No notes yet.';

  @override
  String get loadMore => 'Load more';

  @override
  String byTeacher(String name) {
    return 'by $name';
  }

  @override
  String get noEvents => 'No upcoming events.';

  @override
  String get allDay => 'All day';

  @override
  String get noCourses => 'Not enrolled in any courses.';

  @override
  String get teachersLabel => 'Teachers';

  @override
  String emailTeacher(String name) {
    return 'Email $name';
  }

  @override
  String get schoolDashboard => 'Dashboard';

  @override
  String get students => 'Students';

  @override
  String get attendance => 'Attendance';

  @override
  String get events => 'Events';

  @override
  String get activeStudents => 'Active students';

  @override
  String get teachers => 'Teachers';

  @override
  String get courses => 'Courses';

  @override
  String get guardians => 'Guardians';

  @override
  String get linkedGuardians => 'Parents connected';

  @override
  String get upcomingEventsCount => 'Events in the next 30 days';

  @override
  String get attendanceToday => 'Today\'s attendance';

  @override
  String get noAttendanceToday => 'Attendance hasn\'t been taken today.';

  @override
  String get takeAttendance => 'Take attendance';

  @override
  String get searchStudents => 'Search by name or number';

  @override
  String get noStudents => 'No students found.';

  @override
  String get addStudent => 'Add student';

  @override
  String get editStudent => 'Edit student';

  @override
  String get newStudent => 'New student';

  @override
  String get studentSaved => 'Student saved.';

  @override
  String get unnamedStudent => 'Unnamed student';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get preferredName => 'Preferred name';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get internalNotes => 'Internal notes (staff only)';

  @override
  String get identifiableHint =>
      'Enter at least a first name, last name or student number.';

  @override
  String get clearValue => 'Clear';

  @override
  String get customFieldsOnWeb =>
      'Custom fields can be edited on the web panel.';

  @override
  String get guardiansSection => 'Parents & guardians';

  @override
  String get guardianLinked => 'App connected';

  @override
  String get guardianNotLinked => 'Not connected yet';

  @override
  String get noGuardians => 'No guardians added.';

  @override
  String get notesSection => 'Notes';

  @override
  String get addNote => 'Add note';

  @override
  String get noteTitle => 'Title (optional)';

  @override
  String get noteBody => 'Note';

  @override
  String get noteVisibleToGuardians => 'Visible to parents';

  @override
  String get noteVisibleToGuardiansHint =>
      'Parents see this note in their app.';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get internalNote => 'Staff only';

  @override
  String get attendanceDate => 'Date';

  @override
  String get filterClass => 'Filter by class';

  @override
  String get allClasses => 'All classes';

  @override
  String get markAllPresent => 'Mark all present';

  @override
  String saveAttendance(int count) {
    return 'Save ($count)';
  }

  @override
  String get attendanceSaved => 'Attendance saved.';

  @override
  String unsavedChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsaved changes',
      one: '1 unsaved change',
    );
    return '$_temp0';
  }

  @override
  String get notMarked => 'Not marked';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesBody => 'You have unsaved attendance changes.';

  @override
  String get discard => 'Discard';

  @override
  String get staffOnly => 'Staff only';

  @override
  String get schoolWide => 'Whole school';

  @override
  String get switchSchool => 'Switch school';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleStaff => 'Staff';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get fullName => 'Full name';

  @override
  String get nameSaved => 'Name updated.';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get accountSection => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account and disconnects you from your children\'s schools. School records are not affected. This cannot be undone.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get accountDeleted => 'Your account was deleted.';
}
