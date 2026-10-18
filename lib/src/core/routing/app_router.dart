import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/presentation/account_screens.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';
import 'package:school_platform/src/features/auth/presentation/sign_in_screen.dart';
import 'package:school_platform/src/features/parent/presentation/child_detail_screen.dart';
import 'package:school_platform/src/features/parent/presentation/children_screen.dart';
import 'package:school_platform/src/features/school/presentation/attendance_screen.dart';
import 'package:school_platform/src/features/school/presentation/dashboard_screen.dart';
import 'package:school_platform/src/features/school/presentation/school_events_screen.dart';
import 'package:school_platform/src/features/school/presentation/school_shell.dart';
import 'package:school_platform/src/features/school/presentation/student_detail_screen.dart';
import 'package:school_platform/src/features/school/presentation/student_form_screen.dart';
import 'package:school_platform/src/features/school/presentation/students_screen.dart';
import 'package:school_platform/src/features/settings/presentation/settings_screen.dart';

/// Current routing inputs. A context loaded for a previous user (still
/// present while the provider reloads) is never treated as ready.
final routeGateProvider = Provider<RouteGate>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const SignedOutGate();
  final account = ref.watch(accountContextProvider).value;
  if (account == null || account.userId != userId) return const LoadingGate();
  return ReadyGate(account, ref.watch(effectiveSideProvider));
});

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  // GoRouter is created once; gate changes trigger a redirect re-evaluation.
  final refresh = ValueNotifier<RouteGate>(ref.read(routeGateProvider));
  ref
    ..listen(routeGateProvider, (_, next) => refresh.value = next)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        resolveRedirect(refresh.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.platformAdmin,
        builder: (_, _) => const PlatformAdminScreen(),
      ),
      GoRoute(
        path: Routes.chooseSide,
        builder: (_, _) => const ChooseSideScreen(),
      ),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: Routes.parent,
        builder: (_, _) => const ChildrenScreen(),
        routes: [
          GoRoute(
            path: 'children/:studentId',
            builder: (_, state) => ChildDetailScreen(
              studentId: state.pathParameters['studentId']!,
            ),
          ),
        ],
      ),
      GoRoute(path: Routes.school, redirect: (_, _) => Routes.schoolDashboard),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => SchoolShell(navigationShell: shell),
        // Branch order must match SchoolTab.
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.schoolDashboard,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.schoolStudents,
                builder: (_, _) => const StudentsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const StudentFormScreen(),
                  ),
                  GoRoute(
                    path: ':studentId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => StudentDetailScreen(
                      studentId: state.pathParameters['studentId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (_, state) => StudentFormScreen(
                          studentId: state.pathParameters['studentId'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.schoolAttendance,
                builder: (_, _) => const AttendanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.schoolEvents,
                builder: (_, _) => const SchoolEventsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
