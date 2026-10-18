import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/media/media_repository.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/core/theme/app_theme.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/parent/application/parent_providers.dart';
import 'package:school_platform/src/features/parent/domain/parent_models.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final children = ref.watch(childrenProvider);
    final canSwitch =
        ref
            .watch(accountContextProvider)
            .value
            ?.availableSides
            .contains(AppSide.school) ??
        false;

    Future<void> refresh() async {
      ref.invalidate(accountContextProvider);
      return ref.refresh(childrenProvider.future).then((_) {});
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.childrenTitle),
        actions: [
          if (canSwitch)
            IconButton(
              tooltip: l10n.switchToSchool,
              icon: const Icon(Icons.apartment_outlined),
              onPressed: () => ref
                  .read(preferredSideProvider.notifier)
                  .choose(AppSide.school),
            ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.onboarding),
        icon: const Icon(Icons.add),
        label: Text(l10n.addChildWithCode),
      ),
      body: RefreshableList(
        onRefresh: refresh,
        child: AsyncValueView(
          value: children,
          onRetry: () => ref.invalidate(childrenProvider),
          data: (items) {
            if (items.isEmpty) {
              return ScrollableCenter(
                child: EmptyView(message: l10n.noChildren),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => ChildCard(child: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class ChildCard extends StatelessWidget {
  const ChildCard({required this.child, super.key});

  final Child child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = AppTheme.schoolColorScheme(
      context,
      child.schoolPrimaryColor,
    );
    final name = child.displayName ?? l10n.unnamedStudent;
    final classCode = child.classCode;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.parentChild(child.studentId)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, color: scheme.primary),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  StorageAvatar(
                    path: child.photoPath,
                    fallbackText: name,
                    radius: 28,
                    backgroundColor: scheme.primaryContainer,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (classCode != null) l10n.classLabel(classCode),
                            child.schoolName,
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  StorageAvatar(
                    path: child.schoolLogoPath,
                    fallbackText: child.schoolName,
                    radius: 16,
                    backgroundColor: scheme.secondaryContainer,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
