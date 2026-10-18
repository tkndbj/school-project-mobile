import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/errors/failure_messages.dart';
import 'package:school_platform/src/core/locale/locale_controller.dart';
import 'package:school_platform/src/core/utils/names.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/data/account_repository.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';

final profileNameProvider = FutureProvider.autoDispose<String?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(accountRepositoryProvider).fetchFullName(userId);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final email = ref.watch(currentUserEmailProvider);
    final locale = ref.watch(localeControllerProvider);
    final account = ref.watch(accountContextProvider).value;
    final sides = account?.availableSides ?? const <AppSide>{};
    final side = ref.watch(effectiveSideProvider);
    final name = ref.watch(profileNameProvider);

    Future<void> setLocale(Locale? value) async {
      await ref.read(localeControllerProvider.notifier).setLocale(value);
      final userId = ref.read(currentUserIdProvider);
      if (value != null && userId != null) {
        // Server-side preference (e.g. for notification language). Best effort.
        unawaited(
          ref
              .read(accountRepositoryProvider)
              .updateProfile(userId, locale: value.languageCode)
              .catchError((Object _) {}),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l10n.profileSection),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.fullName),
            subtitle: Text(name.value ?? l10n.notSet),
            trailing: const Icon(Icons.edit_outlined),
            onTap: name.isLoading
                ? null
                : () => _editName(context, ref, name.value),
          ),
          if (email != null)
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: Text(l10n.signedInAs(email)),
            ),
          if (sides.length > 1 && side != null)
            ListTile(
              leading: Icon(
                side == AppSide.school
                    ? Icons.family_restroom_outlined
                    : Icons.apartment_outlined,
              ),
              title: Text(
                side == AppSide.school
                    ? l10n.switchToParent
                    : l10n.switchToSchool,
              ),
              onTap: () {
                Navigator.of(context).pop();
                unawaited(
                  ref
                      .read(preferredSideProvider.notifier)
                      .choose(
                        side == AppSide.school
                            ? AppSide.parent
                            : AppSide.school,
                      ),
                );
              },
            ),
          _SectionHeader(l10n.languageSection),
          RadioGroup<String>(
            groupValue: locale?.languageCode ?? '',
            onChanged: (code) =>
                setLocale(LocaleController.supportedLocaleFor(code)),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: '',
                  title: Text(l10n.languageSystem),
                ),
                RadioListTile<String>(
                  value: 'en',
                  title: Text(l10n.languageEnglish),
                ),
                RadioListTile<String>(
                  value: 'tr',
                  title: Text(l10n.languageTurkish),
                ),
              ],
            ),
          ),
          _SectionHeader(l10n.accountSection),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => _signOut(context, ref),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _deleteAccount(context, ref),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on Object catch (e) {
      if (context.mounted) showSnack(context, failureMessage(l10n, e));
    }
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fullName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.fullName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    final userId = ref.read(currentUserIdProvider);
    if (result == null || userId == null) return;
    final value = blankToNull(result);
    try {
      await ref
          .read(accountRepositoryProvider)
          .updateProfile(userId, fullName: value, clearFullName: value == null);
      ref.invalidate(profileNameProvider);
      if (context.mounted) showSnack(context, l10n.nameSaved);
    } on Object catch (e) {
      if (context.mounted) showSnack(context, failureMessage(l10n, e));
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountRepositoryProvider).deleteAccount();
      await ref.read(authRepositoryProvider).signOutLocally();
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
    } on Object catch (e) {
      if (context.mounted) showSnack(context, failureMessage(l10n, e));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
