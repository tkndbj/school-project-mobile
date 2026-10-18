import 'package:flutter/foundation.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';

/// Route locations. Parameterised routes have builder helpers.
abstract final class Routes {
  static const splash = '/';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';
  static const platformAdmin = '/platform-admin';
  static const chooseSide = '/choose-side';
  static const settings = '/settings';

  static const parent = '/parent';
  static String parentChild(String studentId) => '/parent/children/$studentId';

  static const school = '/school';
  static const schoolDashboard = '/school/dashboard';
  static const schoolStudents = '/school/students';
  static const schoolStudentNew = '/school/students/new';
  static String schoolStudent(String id) => '/school/students/$id';
  static String schoolStudentEdit(String id) => '/school/students/$id/edit';
  static const schoolAttendance = '/school/attendance';
  static const schoolEvents = '/school/events';
}

/// Snapshot of everything routing depends on.
@immutable
sealed class RouteGate {
  const RouteGate();
}

final class SignedOutGate extends RouteGate {
  const SignedOutGate();
}

/// Signed in, account context not loaded yet (or failed to load).
final class LoadingGate extends RouteGate {
  const LoadingGate();
}

final class ReadyGate extends RouteGate {
  const ReadyGate(this.account, this.side);

  final AccountContext account;

  /// The side in use; `null` when the user must choose or has none.
  final AppSide? side;
}

/// The landing location for a ready account.
String homeLocation(ReadyGate gate) {
  final sides = gate.account.availableSides;
  if (sides.isEmpty) {
    return gate.account.isPlatformAdmin
        ? Routes.platformAdmin
        : Routes.onboarding;
  }
  return switch (gate.side) {
    null => Routes.chooseSide,
    AppSide.school => Routes.schoolDashboard,
    AppSide.parent => Routes.parent,
  };
}

bool _isUnder(String location, String prefix) =>
    location == prefix || location.startsWith('$prefix/');

/// Pure redirect logic used by GoRouter. Returns the location to redirect
/// to, or `null` to stay on [location].
String? resolveRedirect(RouteGate gate, String location) {
  switch (gate) {
    case SignedOutGate():
      return location == Routes.signIn ? null : Routes.signIn;
    case LoadingGate():
      return location == Routes.splash ? null : Routes.splash;
    case ReadyGate():
      final home = homeLocation(gate);
      final sides = gate.account.availableSides;
      String? stayOr({required bool allowed}) =>
          allowed ? null : (home == location ? null : home);

      if (location == Routes.splash || location == Routes.signIn) return home;
      if (location == Routes.platformAdmin) {
        return stayOr(allowed: gate.account.isPlatformAdmin && sides.isEmpty);
      }
      if (location == Routes.chooseSide) {
        return stayOr(allowed: sides.length > 1);
      }
      if (_isUnder(location, Routes.school)) {
        if (location == Routes.school) return stayOr(allowed: false);
        return stayOr(allowed: gate.side == AppSide.school);
      }
      if (_isUnder(location, Routes.parent)) {
        return stayOr(allowed: gate.side == AppSide.parent);
      }
      // Onboarding (invite codes) and settings are always reachable.
      return null;
  }
}
