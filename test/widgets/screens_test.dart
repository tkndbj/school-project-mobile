import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/config/app_config.dart';
import 'package:school_platform/src/core/config/config_error_app.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/data/account_repository.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/account/presentation/account_screens.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';
import 'package:school_platform/src/features/auth/presentation/sign_in_screen.dart';
import 'package:school_platform/src/features/parent/application/parent_providers.dart';
import 'package:school_platform/src/features/parent/data/parent_repository.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';
import 'package:school_platform/src/features/parent/presentation/child_detail_screen.dart';
import 'package:school_platform/src/features/parent/presentation/children_screen.dart';

import '../helpers/fake_backend.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockParentRepository extends Mock implements ParentRepository {}

Widget harness(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(
            supabaseUrl: 'https://test.supabase.co',
            supabasePublishableKey: 'sb_publishable_test',
            googleWebClientId: 'test.apps.googleusercontent.com',
            googleIosClientId: 'test.apps.googleusercontent.com',
            webBaseUrl: 'https://school.example.com',
          ),
        ),
        ...overrides,
      ],
      retry: (_, _) => null,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: child,
      ),
    );

const child = Child(
  studentId: 'st1',
  schoolId: 's1',
  schoolName: 'School A',
  schoolTimezone: 'UTC',
  enabledModules: {SchoolModule.grades},
  status: StudentStatus.active,
  firstName: 'Ada',
  lastName: 'Lovelace',
  gradeLevel: '5',
  section: 'B',
);

void main() {
  group('SignInScreen', () {
    late MockAuthRepository auth;

    setUp(() => auth = MockAuthRepository());

    testWidgets('validates the staff form before calling the backend', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
        ),
      );
      expect(find.text(l10nEn.signInWithGoogle), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('password-sign-in')));
      await tester.tap(find.byKey(const Key('password-sign-in')));
      await tester.pump();

      expect(find.text(l10nEn.validationEmail), findsOneWidget);
      expect(find.text(l10nEn.validationRequired), findsOneWidget);
      verifyNever(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('shows a localized error for wrong credentials', (
      tester,
    ) async {
      when(
        () => auth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureKind.invalidCredentials));

      await tester.pumpWidget(
        harness(
          const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
        ),
      );
      await tester.enterText(
        find.byKey(const Key('email')),
        'staff@school.dev',
      );
      await tester.enterText(find.byKey(const Key('password')), 'secret');
      await tester.ensureVisible(find.byKey(const Key('password-sign-in')));
      await tester.tap(find.byKey(const Key('password-sign-in')));
      await tester.pumpAndSettle();

      verify(
        () => auth.signInWithPassword(
          email: 'staff@school.dev',
          password: 'secret',
        ),
      ).called(1);
      expect(find.text(l10nEn.errorAuthInvalidCredentials), findsOneWidget);
    });

    testWidgets('a cancelled Google dialog shows no error', (tester) async {
      when(auth.signInWithGoogle).thenThrow(const CancelledFailure());
      await tester.pumpWidget(
        harness(
          const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(auth)],
        ),
      );
      await tester.tap(find.byKey(const Key('google-sign-in')));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.errorUnknown), findsNothing);
      expect(find.text(l10nEn.errorAuthUnknown), findsNothing);
    });
  });

  group('OnboardingScreen', () {
    late MockAccountRepository account;

    List<Override> overrides() => [
      accountRepositoryProvider.overrideWithValue(account),
      currentUserEmailProvider.overrideWithValue('parent@test.dev'),
      accountContextProvider.overrideWithValue(
        const AsyncData(
          AccountContext(
            userId: 'u1',
            isPlatformAdmin: false,
            memberships: [],
            childrenCount: 0,
          ),
        ),
      ),
    ];

    setUp(() => account = MockAccountRepository());

    testWidgets('explains email linking and validates the code format', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const OnboardingScreen(), overrides: overrides()),
      );
      expect(find.textContaining('parent@test.dev'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('invite-code')), 'ABC');
      await tester.tap(find.text(l10nEn.redeemButton));
      await tester.pump();
      expect(find.text(l10nEn.inviteCodeInvalidFormat), findsOneWidget);
      verifyNever(() => account.redeemInvite(any()));
    });

    testWidgets('normalizes the code and reports an invalid invite', (
      tester,
    ) async {
      when(() => account.redeemInvite(any())).thenAnswer(
        (_) async =>
            const InviteRedemption(status: InviteRedemptionStatus.invalid),
      );
      await tester.pumpWidget(
        harness(const OnboardingScreen(), overrides: overrides()),
      );
      await tester.enterText(
        find.byKey(const Key('invite-code')),
        'abcde fghjk',
      );
      await tester.tap(find.text(l10nEn.redeemButton));
      await tester.pumpAndSettle();

      verify(() => account.redeemInvite('ABCDE-FGHJK')).called(1);
      expect(find.text(l10nEn.inviteInvalid), findsOneWidget);
    });

    testWidgets('reports rate limiting', (tester) async {
      when(() => account.redeemInvite(any())).thenAnswer(
        (_) async =>
            const InviteRedemption(status: InviteRedemptionStatus.rateLimited),
      );
      await tester.pumpWidget(
        harness(const OnboardingScreen(), overrides: overrides()),
      );
      await tester.enterText(
        find.byKey(const Key('invite-code')),
        'ABCDE-FGHJK',
      );
      await tester.tap(find.text(l10nEn.redeemButton));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.inviteRateLimited), findsOneWidget);
    });
  });

  group('parent screens', () {
    testWidgets('children list shows each child with class and school', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const ChildrenScreen(),
          overrides: [
            childrenProvider.overrideWith((ref) async => [child]),
            accountContextProvider.overrideWithValue(const AsyncData(null)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Class 5B · School A'), findsOneWidget);
    });

    testWidgets('empty state when no child is linked yet', (tester) async {
      await tester.pumpWidget(
        harness(
          const ChildrenScreen(),
          overrides: [
            childrenProvider.overrideWith((ref) async => <Child>[]),
            accountContextProvider.overrideWithValue(const AsyncData(null)),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.noChildren), findsOneWidget);
    });

    testWidgets('child detail only shows tabs for enabled modules', (
      tester,
    ) async {
      final repository = MockParentRepository();
      when(() => repository.fetchProfile('st1')).thenAnswer(
        (_) async => const StudentProfile(
          studentId: 'st1',
          schoolId: 's1',
          status: StudentStatus.active,
          customFields: [],
          firstName: 'Ada',
          studentNumber: 'A-001',
        ),
      );
      await tester.pumpWidget(
        harness(
          const ChildDetailScreen(studentId: 'st1'),
          overrides: [
            childrenProvider.overrideWith((ref) async => [child]),
            parentRepositoryProvider.overrideWithValue(repository),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.tabOverview), findsOneWidget);
      expect(find.text(l10nEn.tabGrades), findsOneWidget);
      expect(find.text(l10nEn.tabAttendance), findsNothing);
      expect(find.text(l10nEn.tabNotes), findsNothing);
      expect(find.text('A-001'), findsOneWidget);
    });

    testWidgets('a child that is not linked shows not found', (tester) async {
      await tester.pumpWidget(
        harness(
          const ChildDetailScreen(studentId: 'other'),
          overrides: [
            childrenProvider.overrideWith((ref) async => [child]),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.errorNotFound), findsOneWidget);
    });
  });

  testWidgets('ConfigErrorApp lists every configuration problem', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ConfigErrorApp(
        problems: ['SUPABASE_URL is missing', 'WEB_BASE_URL is missing'],
      ),
    );
    expect(find.text('• SUPABASE_URL is missing'), findsOneWidget);
    expect(find.text('• WEB_BASE_URL is missing'), findsOneWidget);
  });
}
