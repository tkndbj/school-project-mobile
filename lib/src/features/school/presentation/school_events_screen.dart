import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/widgets/school_widgets.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/school/application/school_providers.dart';
import 'package:school_platform/src/features/school/presentation/school_shell.dart';

class SchoolEventsScreen extends ConsumerWidget {
  const SchoolEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membership = ref.watch(activeMembershipProvider);
    if (membership == null) return const Scaffold(body: LoadingView());
    final provider = upcomingEventsProvider(membership.schoolId);
    final events = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.events),
        actions: const [SchoolAppBarActions()],
      ),
      body: RefreshableList(
        onRefresh: () => ref.refresh(provider.future),
        child: AsyncValueView(
          value: events,
          onRetry: () => ref.invalidate(provider),
          data: (items) {
            if (items.isEmpty) {
              return ScrollableCenter(
                child: EmptyView(
                  icon: Icons.event_outlined,
                  message: l10n.noEvents,
                  action: const ManageOnWebCard(),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = items[index];
                return EventTile(
                  title: event.title,
                  startsAt: event.startsAt,
                  endsAt: event.endsAt,
                  allDay: event.allDay,
                  color: event.color,
                  details: [
                    event.courseName ?? l10n.schoolWide,
                    ?event.location,
                  ],
                  trailing: event.visibleToGuardians
                      ? null
                      : Tooltip(
                          message: l10n.staffOnly,
                          child: Icon(
                            Icons.lock_outline,
                            semanticLabel: l10n.staffOnly,
                          ),
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
