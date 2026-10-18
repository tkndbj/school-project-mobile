import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_platform/src/app.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/locale/locale_controller.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/features/account/data/account_repository.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';
import 'package:school_platform/src/features/parent/data/parent_repository.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_backend.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockParentRepository extends Mock implements ParentRepository {}

class MockPreferences extends Mock implements SharedPreferencesWithCache {}

const unlinked = AccountContext(
  userId: 'parent1',
  isPlatformAdmin: false,
  memberships: [],
  childrenCount: 0,
);

const connected = AccountContext(
  userId: 'parent1',
  isPlatformAdmin: false,
  memberships: [],
  childrenCount: 0,
  guardianSchools: [GuardianSchool(schoolId: 's1', schoolName: 'School A')],
);

const child = Child(
  studentId: 'student1',
  schoolId: 's1',
  schoolName: 'School A',
  schoolTimezone: 'UTC',
  enabledModules: {},
  status: StudentStatus.active,
  firstName: 'Ada',
  lastName: 'Lovelace',
);

void main() {
  late MockAccountRepository account;
  late MockParentRepository parent;
  late SharedPreferencesWithCache preferences;

  setUp(() {
    account = MockAccountRepository();
    parent = MockParentRepository();
    preferences = MockPreferences();
    when(() => preferences.getString(any())).thenReturn(null);
    when(() => preferences.setString(any(), any())).thenAnswer((_) async {});
    when(account.linkGuardianRecords).thenAnswer((_) async => 0);
    when(parent.fetchChildren).thenAnswer((_) async => <Child>[]);
  });

  Widget app() => ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('parent1'),
      currentUserEmailProvider.overrideWithValue('parent@test.dev'),
      accountRepositoryProvider.overrideWithValue(account),
      parentRepositoryProvider.overrideWithValue(parent),
      sharedPreferencesProvider.overrideWithValue(preferences),
      localeControllerProvider.overrideWithBuild(
        (ref, notifier) => const Locale('en'),
      ),
    ],
    retry: (_, _) => null,
    child: const SchoolPlatformApp(),
  );

  testWidgets(
    'email-linked guardian lands on connected waiting screen at login',
    (tester) async {
      when(account.fetchContext).thenAnswer((_) async => connected);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.childrenTitle), findsOneWidget);
      expect(
        find.textContaining(l10nEn.inviteLinked('School A')),
        findsOneWidget,
      );
      expect(find.textContaining(l10nEn.waitingForStudentLink), findsOneWidget);
      expect(find.text(l10nEn.onboardingTitle), findsNothing);
    },
  );

  testWidgets(
    'redeeming a code navigates to parent home even without a student',
    (tester) async {
      var isConnected = false;
      when(
        account.fetchContext,
      ).thenAnswer((_) async => isConnected ? connected : unlinked);
      when(() => account.redeemInvite('ABCDE-FGHJK')).thenAnswer((_) async {
        isConnected = true;
        return const InviteRedemption(
          status: InviteRedemptionStatus.linked,
          schoolName: 'School A',
        );
      });
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.onboardingTitle), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('invite-code')),
        'abcde fghjk',
      );
      await tester.tap(find.text(l10nEn.redeemButton));
      await tester.pumpAndSettle();

      expect(find.text(l10nEn.childrenTitle), findsOneWidget);
      expect(find.textContaining(l10nEn.waitingForStudentLink), findsOneWidget);
      expect(find.text(l10nEn.onboardingTitle), findsNothing);
      verify(() => account.redeemInvite('ABCDE-FGHJK')).called(1);
    },
  );

  testWidgets(
    'checking again shows a student assigned by the school without signing out',
    (tester) async {
      var assigned = false;
      when(account.fetchContext).thenAnswer((_) async => connected);
      when(
        parent.fetchChildren,
      ).thenAnswer((_) async => assigned ? [child] : <Child>[]);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.textContaining(l10nEn.waitingForStudentLink), findsOneWidget);

      assigned = true;
      await tester.tap(find.text(l10nEn.checkAgain));
      await tester.pumpAndSettle();

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.textContaining(l10nEn.waitingForStudentLink), findsNothing);
    },
  );
}
