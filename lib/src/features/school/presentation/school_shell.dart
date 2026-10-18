import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/domain/enums.dart';
import 'package:school_platform/src/core/l10n/enum_labels.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Branches of the school navigation shell, in router order.
enum SchoolTab {
  dashboard(null, Icons.space_dashboard_outlined, Icons.space_dashboard),
  students(null, Icons.people_outline, Icons.people),
  attendance(
    SchoolModule.attendance,
    Icons.fact_check_outlined,
    Icons.fact_check,
  ),
  events(SchoolModule.events, Icons.event_outlined, Icons.event)
  ;

  const SchoolTab(this.module, this.icon, this.selectedIcon);

  final SchoolModule? module;
  final IconData icon;
  final IconData selectedIcon;

  String label(AppLocalizations l10n) => switch (this) {
    dashboard => l10n.schoolDashboard,
    students => l10n.students,
    attendance => l10n.attendance,
    events => l10n.events,
  };

  bool isEnabledFor(SchoolMembership membership) =>
      module == null || membership.hasModule(module!);
}

class SchoolShell extends ConsumerWidget {
  const SchoolShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeMembershipProvider);
    if (membership == null) return const Scaffold(body: LoadingView());

    final tabs = [
      for (final tab in SchoolTab.values)
        if (tab.isEnabledFor(membership)) tab,
    ];
    final current = SchoolTab.values[navigationShell.currentIndex];
    final selected = tabs.indexOf(current);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (index) {
          final branch = tabs[index].index;
          navigationShell.goBranch(
            branch,
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label(l10n),
            ),
        ],
      ),
    );
  }
}

/// Shared app bar actions on school screens: school switcher, switch to the
/// parent side, settings.
class SchoolAppBarActions extends ConsumerWidget {
  const SchoolAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(accountContextProvider).value;
    final active = ref.watch(activeMembershipProvider);
    final memberships = account?.memberships ?? const <SchoolMembership>[];
    final canSwitchSide =
        account?.availableSides.contains(AppSide.parent) ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (memberships.length > 1)
          PopupMenuButton<String>(
            tooltip: l10n.switchSchool,
            icon: const Icon(Icons.swap_horiz),
            initialValue: active?.schoolId,
            onSelected: (id) =>
                ref.read(selectedSchoolIdProvider.notifier).select(id),
            itemBuilder: (_) => [
              for (final m in memberships)
                CheckedPopupMenuItem(
                  value: m.schoolId,
                  checked: m.schoolId == active?.schoolId,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.schoolName),
                    subtitle: Text(m.role.label(l10n)),
                  ),
                ),
            ],
          ),
        if (canSwitchSide)
          IconButton(
            tooltip: l10n.switchToParent,
            icon: const Icon(Icons.family_restroom_outlined),
            onPressed: () =>
                ref.read(preferredSideProvider.notifier).choose(AppSide.parent),
          ),
        IconButton(
          tooltip: l10n.settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(Routes.settings),
        ),
      ],
    );
  }
}

/// Reminder that some management features live on the web panel.
class ManageOnWebCard extends ConsumerWidget {
  const ManageOnWebCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.desktop_windows_outlined),
        title: Text(l10n.manageOnWeb),
        subtitle: Text(l10n.manageOnWebDetails),
        onTap: () async {
          final membership = ref.read(activeMembershipProvider);
          final base = ref.read(appConfigProvider).webBaseUrl;
          final uri = Uri.parse(
            membership == null ? base : '$base/school/${membership.slug}',
          );
          try {
            if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              return;
            }
          } on Object {
            /* Show the same recoverable message below. */
          }
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
          }
        },
      ),
    );
  }
}
