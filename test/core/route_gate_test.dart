import 'package:flutter_test/flutter_test.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';

AccountContext account({
  bool platformAdmin = false,
  bool staff = false,
  int children = 0,
}) => AccountContext(
  userId: 'u1',
  isPlatformAdmin: platformAdmin,
  memberships: [
    if (staff)
      const SchoolMembership(
        schoolId: 's1',
        schoolName: 'School',
        slug: 'school',
        role: SchoolRole.admin,
        enabledModules: {},
        timezone: 'UTC',
      ),
  ],
  childrenCount: children,
);

void main() {
  group('signed out', () {
    test('everything redirects to sign-in', () {
      for (final location in [
        Routes.splash,
        Routes.parent,
        Routes.schoolDashboard,
        Routes.settings,
      ]) {
        expect(resolveRedirect(const SignedOutGate(), location), Routes.signIn);
      }
      expect(resolveRedirect(const SignedOutGate(), Routes.signIn), isNull);
    });
  });

  group('loading', () {
    test('waits on the splash screen', () {
      expect(
        resolveRedirect(const LoadingGate(), Routes.signIn),
        Routes.splash,
      );
      expect(
        resolveRedirect(const LoadingGate(), Routes.parent),
        Routes.splash,
      );
      expect(resolveRedirect(const LoadingGate(), Routes.splash), isNull);
    });
  });

  group('ready', () {
    test(
      'parent only lands on the children list and cannot open school routes',
      () {
        final gate = ReadyGate(account(children: 2), AppSide.parent);
        expect(resolveRedirect(gate, Routes.splash), Routes.parent);
        expect(resolveRedirect(gate, Routes.signIn), Routes.parent);
        expect(resolveRedirect(gate, Routes.parentChild('x')), isNull);
        expect(resolveRedirect(gate, Routes.schoolStudents), Routes.parent);
        expect(resolveRedirect(gate, Routes.chooseSide), Routes.parent);
      },
    );

    test('staff only lands on the dashboard and cannot open parent routes', () {
      final gate = ReadyGate(account(staff: true), AppSide.school);
      expect(resolveRedirect(gate, Routes.splash), Routes.schoolDashboard);
      expect(resolveRedirect(gate, Routes.school), Routes.schoolDashboard);
      expect(resolveRedirect(gate, Routes.schoolStudent('id')), isNull);
      expect(resolveRedirect(gate, Routes.parent), Routes.schoolDashboard);
    });

    test('both sides without a choice go to the side picker', () {
      final gate = ReadyGate(account(staff: true, children: 1), null);
      expect(resolveRedirect(gate, Routes.splash), Routes.chooseSide);
      expect(resolveRedirect(gate, Routes.chooseSide), isNull);
      expect(resolveRedirect(gate, Routes.parent), Routes.chooseSide);
    });

    test('no sides: onboarding, or the web notice for platform admins', () {
      expect(
        resolveRedirect(ReadyGate(account(), null), Routes.splash),
        Routes.onboarding,
      );
      expect(
        resolveRedirect(ReadyGate(account(), null), Routes.onboarding),
        isNull,
      );
      expect(
        resolveRedirect(ReadyGate(account(), null), Routes.platformAdmin),
        Routes.onboarding,
      );
      final admin = ReadyGate(account(platformAdmin: true), null);
      expect(resolveRedirect(admin, Routes.splash), Routes.platformAdmin);
      expect(resolveRedirect(admin, Routes.platformAdmin), isNull);
    });

    test('platform admins who are also parents use the parent side', () {
      final gate = ReadyGate(
        account(platformAdmin: true, children: 1),
        AppSide.parent,
      );
      expect(resolveRedirect(gate, Routes.platformAdmin), Routes.parent);
    });

    test('settings and onboarding (invite codes) are always reachable', () {
      final gate = ReadyGate(account(children: 1), AppSide.parent);
      expect(resolveRedirect(gate, Routes.settings), isNull);
      expect(resolveRedirect(gate, Routes.onboarding), isNull);
    });
  });

  group('resolveEffectiveSide', () {
    test('a single side is always used', () {
      expect(
        resolveEffectiveSide(
          available: {AppSide.parent},
          preferred: AppSide.school,
        ),
        AppSide.parent,
      );
    });

    test('with both sides the stored preference wins, otherwise none', () {
      const both = {AppSide.parent, AppSide.school};
      expect(
        resolveEffectiveSide(available: both, preferred: AppSide.school),
        AppSide.school,
      );
      expect(resolveEffectiveSide(available: both, preferred: null), isNull);
    });

    test('no sides → none', () {
      expect(
        resolveEffectiveSide(available: {}, preferred: AppSide.parent),
        isNull,
      );
    });
  });
}
