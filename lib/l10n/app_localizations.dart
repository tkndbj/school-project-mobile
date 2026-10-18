import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'School Platform'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @manageOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Manage this on the web panel'**
  String get manageOnWeb;

  /// No description provided for @manageOnWebDetails.
  ///
  /// In en, this message translates to:
  /// **'Grade books, imports, custom fields and school settings are available on the web panel.'**
  String get manageOnWebDetails;

  /// No description provided for @moduleDisabled.
  ///
  /// In en, this message translates to:
  /// **'This feature is turned off for your school.'**
  String get moduleDisabled;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorPermissionDenied;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find what you were looking for.'**
  String get errorNotFound;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server had a problem. Please try again shortly.'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Some values have an invalid format.'**
  String get errorInvalidInput;

  /// No description provided for @errorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A record with the same details already exists.'**
  String get errorDuplicate;

  /// No description provided for @errorDuplicateStudentNumber.
  ///
  /// In en, this message translates to:
  /// **'Another student already has this student number.'**
  String get errorDuplicateStudentNumber;

  /// No description provided for @errorConstraint.
  ///
  /// In en, this message translates to:
  /// **'Some values are not allowed.'**
  String get errorConstraint;

  /// No description provided for @errorStudentIdentifiable.
  ///
  /// In en, this message translates to:
  /// **'Enter at least a first name, last name or student number.'**
  String get errorStudentIdentifiable;

  /// No description provided for @errorReference.
  ///
  /// In en, this message translates to:
  /// **'A related record no longer exists. Refresh and try again.'**
  String get errorReference;

  /// No description provided for @errorCustomField.
  ///
  /// In en, this message translates to:
  /// **'The value of \"{field}\" is not valid.'**
  String errorCustomField(String field);

  /// No description provided for @errorInvalidSetting.
  ///
  /// In en, this message translates to:
  /// **'This setting value is not valid.'**
  String get errorInvalidSetting;

  /// No description provided for @errorSchoolRequiresAdmin.
  ///
  /// In en, this message translates to:
  /// **'A school must always have at least one admin.'**
  String get errorSchoolRequiresAdmin;

  /// No description provided for @errorInvalidDateRange.
  ///
  /// In en, this message translates to:
  /// **'The selected date range is not valid.'**
  String get errorInvalidDateRange;

  /// No description provided for @errorImport.
  ///
  /// In en, this message translates to:
  /// **'The import data is not in the expected format.'**
  String get errorImport;

  /// No description provided for @errorAuthInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorAuthInvalidCredentials;

  /// No description provided for @errorAuthEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email address first.'**
  String get errorAuthEmailNotConfirmed;

  /// No description provided for @errorAuthUserBanned.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errorAuthUserBanned;

  /// No description provided for @errorAuthRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorAuthRateLimited;

  /// No description provided for @errorGoogleNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not available on this device.'**
  String get errorGoogleNotAvailable;

  /// No description provided for @errorAuthUnknown.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get errorAuthUnknown;

  /// No description provided for @errorAccountDeletionBlocked.
  ///
  /// In en, this message translates to:
  /// **'You are the only admin of a school. Transfer the admin role to someone else on the web panel first.'**
  String get errorAccountDeletionBlocked;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Parents: continue with Google. School staff can also sign in with the email and password from their invitation.'**
  String get signInSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @staffSignInHeading.
  ///
  /// In en, this message translates to:
  /// **'School staff sign-in'**
  String get staffSignInHeading;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to choose a new password.'**
  String get resetPasswordBody;

  /// No description provided for @resetPasswordSend.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get resetPasswordSend;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset link is on its way.'**
  String resetPasswordSent(String email);

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmail;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @loadingAccount.
  ///
  /// In en, this message translates to:
  /// **'Loading your account…'**
  String get loadingAccount;

  /// No description provided for @accountLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your account.'**
  String get accountLoadFailed;

  /// No description provided for @platformAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Use the web panel'**
  String get platformAdminTitle;

  /// No description provided for @platformAdminBody.
  ///
  /// In en, this message translates to:
  /// **'Platform administration is only available on the web panel.'**
  String get platformAdminBody;

  /// No description provided for @chooseSideTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to continue?'**
  String get chooseSideTitle;

  /// No description provided for @sideSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get sideSchool;

  /// No description provided for @sideSchoolDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage students, attendance and notes'**
  String get sideSchoolDescription;

  /// No description provided for @sideParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get sideParent;

  /// No description provided for @sideParentDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow your children\'s school life'**
  String get sideParentDescription;

  /// No description provided for @switchToSchool.
  ///
  /// In en, this message translates to:
  /// **'Switch to school'**
  String get switchToSchool;

  /// No description provided for @switchToParent.
  ///
  /// In en, this message translates to:
  /// **'Switch to parent'**
  String get switchToParent;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to your child\'s school'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is connected automatically once your child\'s school registers the email address you signed in with ({email}). If the school gave you an invite code, enter it below.'**
  String onboardingBody(String email);

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'XXXXX-XXXXX'**
  String get inviteCodeHint;

  /// No description provided for @inviteCodeInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invite codes have 10 letters or digits.'**
  String get inviteCodeInvalidFormat;

  /// No description provided for @redeemButton.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get redeemButton;

  /// No description provided for @inviteLinked.
  ///
  /// In en, this message translates to:
  /// **'Connected to {school}.'**
  String inviteLinked(String school);

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code is invalid or has expired.'**
  String get inviteInvalid;

  /// No description provided for @inviteAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This invite was already used by another account. Ask the school for a new code.'**
  String get inviteAlreadyLinked;

  /// No description provided for @inviteRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again in an hour.'**
  String get inviteRateLimited;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// No description provided for @addChildWithCode.
  ///
  /// In en, this message translates to:
  /// **'Add a child with an invite code'**
  String get addChildWithCode;

  /// No description provided for @childrenTitle.
  ///
  /// In en, this message translates to:
  /// **'My children'**
  String get childrenTitle;

  /// No description provided for @noChildren.
  ///
  /// In en, this message translates to:
  /// **'No children are connected to your account yet.'**
  String get noChildren;

  /// No description provided for @waitingForStudentLink.
  ///
  /// In en, this message translates to:
  /// **'Your school connection is ready. Ask the school to link your guardian record to your child. Their information will appear here once the school adds that link. Tap Check again to refresh.'**
  String get waitingForStudentLink;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabGrades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get tabGrades;

  /// No description provided for @tabAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get tabAttendance;

  /// No description provided for @tabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tabNotes;

  /// No description provided for @tabEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get tabEvents;

  /// No description provided for @tabCourses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get tabCourses;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @studentNumber.
  ///
  /// In en, this message translates to:
  /// **'Student number'**
  String get studentNumber;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @gradeLevel.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeLevel;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class {grade}'**
  String classLabel(String grade);

  /// No description provided for @enrolledOn.
  ///
  /// In en, this message translates to:
  /// **'Enrolled on'**
  String get enrolledOn;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @attendanceThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Attendance this month'**
  String get attendanceThisMonth;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get additionalInfo;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @studentStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get studentStatusActive;

  /// No description provided for @studentStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get studentStatusInactive;

  /// No description provided for @studentStatusGraduated.
  ///
  /// In en, this message translates to:
  /// **'Graduated'**
  String get studentStatusGraduated;

  /// No description provided for @studentStatusTransferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get studentStatusTransferred;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderUndisclosed.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderUndisclosed;

  /// No description provided for @relationshipMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationshipMother;

  /// No description provided for @relationshipFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationshipFather;

  /// No description provided for @relationshipGuardian.
  ///
  /// In en, this message translates to:
  /// **'Guardian'**
  String get relationshipGuardian;

  /// No description provided for @relationshipGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get relationshipGrandparent;

  /// No description provided for @relationshipSibling.
  ///
  /// In en, this message translates to:
  /// **'Sibling'**
  String get relationshipSibling;

  /// No description provided for @relationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;

  /// No description provided for @attendancePresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get attendancePresent;

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @attendanceLate.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get attendanceLate;

  /// No description provided for @attendanceExcused.
  ///
  /// In en, this message translates to:
  /// **'Excused'**
  String get attendanceExcused;

  /// No description provided for @minutesLate.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min late'**
  String minutesLate(int minutes);

  /// No description provided for @dailyAttendance.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyAttendance;

  /// No description provided for @noGrades.
  ///
  /// In en, this message translates to:
  /// **'No published grades yet.'**
  String get noGrades;

  /// No description provided for @averagePercent.
  ///
  /// In en, this message translates to:
  /// **'Average {percent}%'**
  String averagePercent(String percent);

  /// No description provided for @scoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{score} / {max}'**
  String scoreOutOf(String score, String max);

  /// No description provided for @assessmentExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get assessmentExam;

  /// No description provided for @assessmentQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get assessmentQuiz;

  /// No description provided for @assessmentHomework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get assessmentHomework;

  /// No description provided for @assessmentProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get assessmentProject;

  /// No description provided for @assessmentParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get assessmentParticipation;

  /// No description provided for @assessmentTermGrade.
  ///
  /// In en, this message translates to:
  /// **'Term grade'**
  String get assessmentTermGrade;

  /// No description provided for @assessmentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get assessmentOther;

  /// No description provided for @noAttendance.
  ///
  /// In en, this message translates to:
  /// **'No attendance records for this month.'**
  String get noAttendance;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotes;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @byTeacher.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byTeacher(String name);

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events.'**
  String get noEvents;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @noCourses.
  ///
  /// In en, this message translates to:
  /// **'Not enrolled in any courses.'**
  String get noCourses;

  /// No description provided for @teachersLabel.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachersLabel;

  /// No description provided for @emailTeacher.
  ///
  /// In en, this message translates to:
  /// **'Email {name}'**
  String emailTeacher(String name);

  /// No description provided for @schoolDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get schoolDashboard;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @activeStudents.
  ///
  /// In en, this message translates to:
  /// **'Active students'**
  String get activeStudents;

  /// No description provided for @teachers.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachers;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @guardians.
  ///
  /// In en, this message translates to:
  /// **'Guardians'**
  String get guardians;

  /// No description provided for @linkedGuardians.
  ///
  /// In en, this message translates to:
  /// **'Parents connected'**
  String get linkedGuardians;

  /// No description provided for @upcomingEventsCount.
  ///
  /// In en, this message translates to:
  /// **'Events in the next 30 days'**
  String get upcomingEventsCount;

  /// No description provided for @attendanceToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s attendance'**
  String get attendanceToday;

  /// No description provided for @noAttendanceToday.
  ///
  /// In en, this message translates to:
  /// **'Attendance hasn\'t been taken today.'**
  String get noAttendanceToday;

  /// No description provided for @takeAttendance.
  ///
  /// In en, this message translates to:
  /// **'Take attendance'**
  String get takeAttendance;

  /// No description provided for @searchStudents.
  ///
  /// In en, this message translates to:
  /// **'Search by name or number'**
  String get searchStudents;

  /// No description provided for @noStudents.
  ///
  /// In en, this message translates to:
  /// **'No students found.'**
  String get noStudents;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get addStudent;

  /// No description provided for @editStudent.
  ///
  /// In en, this message translates to:
  /// **'Edit student'**
  String get editStudent;

  /// No description provided for @newStudent.
  ///
  /// In en, this message translates to:
  /// **'New student'**
  String get newStudent;

  /// No description provided for @studentSaved.
  ///
  /// In en, this message translates to:
  /// **'Student saved.'**
  String get studentSaved;

  /// No description provided for @unnamedStudent.
  ///
  /// In en, this message translates to:
  /// **'Unnamed student'**
  String get unnamedStudent;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @preferredName.
  ///
  /// In en, this message translates to:
  /// **'Preferred name'**
  String get preferredName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @internalNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal notes (staff only)'**
  String get internalNotes;

  /// No description provided for @identifiableHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least a first name, last name or student number.'**
  String get identifiableHint;

  /// No description provided for @clearValue.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearValue;

  /// No description provided for @customFieldsOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Custom fields can be edited on the web panel.'**
  String get customFieldsOnWeb;

  /// No description provided for @guardiansSection.
  ///
  /// In en, this message translates to:
  /// **'Parents & guardians'**
  String get guardiansSection;

  /// No description provided for @guardianLinked.
  ///
  /// In en, this message translates to:
  /// **'App connected'**
  String get guardianLinked;

  /// No description provided for @guardianNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not connected yet'**
  String get guardianNotLinked;

  /// No description provided for @noGuardians.
  ///
  /// In en, this message translates to:
  /// **'No guardians added.'**
  String get noGuardians;

  /// No description provided for @notesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesSection;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @noteTitle.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get noteTitle;

  /// No description provided for @noteBody.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteBody;

  /// No description provided for @noteVisibleToGuardians.
  ///
  /// In en, this message translates to:
  /// **'Visible to parents'**
  String get noteVisibleToGuardians;

  /// No description provided for @noteVisibleToGuardiansHint.
  ///
  /// In en, this message translates to:
  /// **'Parents see this note in their app.'**
  String get noteVisibleToGuardiansHint;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// No description provided for @internalNote.
  ///
  /// In en, this message translates to:
  /// **'Staff only'**
  String get internalNote;

  /// No description provided for @attendanceDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get attendanceDate;

  /// No description provided for @filterClass.
  ///
  /// In en, this message translates to:
  /// **'Filter by class'**
  String get filterClass;

  /// No description provided for @allClasses.
  ///
  /// In en, this message translates to:
  /// **'All classes'**
  String get allClasses;

  /// No description provided for @markAllPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark all present'**
  String get markAllPresent;

  /// No description provided for @saveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Save ({count})'**
  String saveAttendance(int count);

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved.'**
  String get attendanceSaved;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unsaved change} other{{count} unsaved changes}}'**
  String unsavedChanges(int count);

  /// No description provided for @notMarked.
  ///
  /// In en, this message translates to:
  /// **'Not marked'**
  String get notMarked;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved attendance changes.'**
  String get discardChangesBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @staffOnly.
  ///
  /// In en, this message translates to:
  /// **'Staff only'**
  String get staffOnly;

  /// No description provided for @schoolWide.
  ///
  /// In en, this message translates to:
  /// **'Whole school'**
  String get schoolWide;

  /// No description provided for @switchSchool.
  ///
  /// In en, this message translates to:
  /// **'Switch school'**
  String get switchSchool;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @nameSaved.
  ///
  /// In en, this message translates to:
  /// **'Name updated.'**
  String get nameSaved;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and disconnects you from your children\'s schools. School records are not affected. This cannot be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountConfirm;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get accountDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
