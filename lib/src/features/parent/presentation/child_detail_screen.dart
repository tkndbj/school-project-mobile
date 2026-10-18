import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/theme/app_theme.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/parent/application/parent_providers.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';
import 'package:school_platform/src/features/parent/presentation/child_tabs.dart';

/// A tab of the child detail screen, gated by a school module.
enum ChildTab {
  overview(null),
  grades(SchoolModule.grades),
  attendance(SchoolModule.attendance),
  notes(SchoolModule.notes),
  events(SchoolModule.events),
  courses(SchoolModule.courses)
  ;

  const ChildTab(this.module);

  /// `null` for tabs that are always shown.
  final SchoolModule? module;

  /// Tabs available for a school with the given modules, in display order.
  static List<ChildTab> availableFor(Set<SchoolModule> modules) => [
    for (final tab in values)
      if (tab.module == null || modules.contains(tab.module)) tab,
  ];

  String label(AppLocalizations l10n) => switch (this) {
    overview => l10n.tabOverview,
    grades => l10n.tabGrades,
    attendance => l10n.tabAttendance,
    notes => l10n.tabNotes,
    events => l10n.tabEvents,
    courses => l10n.tabCourses,
  };
}

class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({required this.studentId, super.key});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final child = ref.watch(childProvider(studentId));

    return child.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: e,
          onRetry: () => ref.invalidate(childrenProvider),
        ),
      ),
      data: (child) {
        if (child == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(error: NotFoundFailure()),
          );
        }
        final tabs = ChildTab.availableFor(child.enabledModules);
        final scheme = AppTheme.schoolColorScheme(
          context,
          child.schoolPrimaryColor,
        );
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: scheme),
          child: DefaultTabController(
            length: tabs.length,
            child: Scaffold(
              appBar: AppBar(
                title: Text(child.displayName ?? l10n.unnamedStudent),
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [for (final tab in tabs) Tab(text: tab.label(l10n))],
                ),
              ),
              body: TabBarView(
                children: [for (final tab in tabs) _tabBody(tab, child)],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tabBody(ChildTab tab, Child child) => switch (tab) {
    ChildTab.overview => OverviewTab(child: child),
    ChildTab.grades => GradesTab(studentId: child.studentId),
    ChildTab.attendance => AttendanceTab(studentId: child.studentId),
    ChildTab.notes => NotesTab(studentId: child.studentId),
    ChildTab.events => EventsTab(studentId: child.studentId),
    ChildTab.courses => CoursesTab(studentId: child.studentId),
  };
}
