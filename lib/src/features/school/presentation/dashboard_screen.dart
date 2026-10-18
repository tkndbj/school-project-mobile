import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/media/media_repository.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/core/widgets/school_widgets.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:school_platform/src/features/school/domain/school_models.dart';
import 'package:school_platform/src/features/school/presentation/school_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeMembershipProvider);
    if (membership == null) return const Scaffold(body: LoadingView());
    final stats = ref.watch(dashboardProvider(membership.schoolId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            StorageAvatar(
              path: membership.logoPath,
              fallbackText: membership.schoolName,
              radius: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                membership.schoolName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [SchoolAppBarActions()],
      ),
      body: RefreshableList(
        onRefresh: () =>
            ref.refresh(dashboardProvider(membership.schoolId).future),
        child: AsyncValueView(
          value: stats,
          onRetry: () => ref.invalidate(dashboardProvider(membership.schoolId)),
          data: (s) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (membership.hasModule(SchoolModule.attendance)) ...[
                _AttendanceTodayCard(stats: s),
                const SizedBox(height: 16),
              ],
              _StatGrid(
                items: [
                  (Icons.people, l10n.activeStudents, s.studentsActive),
                  if (membership.hasModule(SchoolModule.teachers))
                    (Icons.badge_outlined, l10n.teachers, s.teachersTotal),
                  if (membership.hasModule(SchoolModule.courses))
                    (Icons.menu_book_outlined, l10n.courses, s.coursesTotal),
                  (Icons.family_restroom, l10n.guardians, s.guardiansTotal),
                  (Icons.phone_iphone, l10n.linkedGuardians, s.guardiansLinked),
                  if (membership.hasModule(SchoolModule.events))
                    (Icons.event, l10n.upcomingEventsCount, s.upcomingEvents),
                ],
              ),
              const SizedBox(height: 16),
              const ManageOnWebCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceTodayCard extends StatelessWidget {
  const _AttendanceTodayCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.attendanceToday,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (stats.attendanceTodayTotal == 0)
              Text(l10n.noAttendanceToday)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in AttendanceStatus.values)
                    AttendanceChip(
                      status: status,
                      count: stats.attendanceToday[status] ?? 0,
                    ),
                ],
              ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => context.go(Routes.schoolAttendance),
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(l10n.takeAttendance),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<(IconData, String, int)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (icon, label, value) in items)
              SizedBox(
                width: width,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: MergeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text('$value', style: theme.textTheme.headlineMedium),
                          Text(label, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
