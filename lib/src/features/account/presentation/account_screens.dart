import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_platform/l10n/app_localizations.dart';
import 'package:school_platform/src/core/errors/failure_messages.dart';
import 'package:school_platform/src/core/routing/route_gate.dart';
import 'package:school_platform/src/core/widgets/state_views.dart';
import 'package:school_platform/src/features/account/application/account_providers.dart';
import 'package:school_platform/src/features/account/data/account_repository.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';
import 'package:school_platform/src/features/parent/application/parent_providers.dart';

/// Shown while the account context loads, or when loading failed.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(accountContextProvider);
    final error = account.hasValue ? null : account.error;

    return Scaffold(
      body: SafeArea(
        child: error == null
            ? LoadingView(message: l10n.loadingAccount)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.accountLoadFailed,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ErrorView(
                      error: error,
                      onRetry: () => ref.invalidate(accountContextProvider),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.read(authRepositoryProvider).signOut(),
                      child: Text(l10n.signOut),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// For accounts with no school or children yet, and for parents adding a
/// child with an invite code.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = normalizeInviteCode(_code.text)!;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await ref
          .read(accountRepositoryProvider)
          .redeemInvite(code);
      if (!mounted) return;
      switch (result.status) {
        case InviteRedemptionStatus.linked:
          _code.clear();
          showSnack(context, l10n.inviteLinked(result.schoolName ?? ''));
          await ref.read(preferredSideProvider.notifier).choose(AppSide.parent);
          if (!mounted) return;
          ref.invalidate(childrenProvider);
          await _reloadAndGoHome();
        case InviteRedemptionStatus.invalid:
          _setMessage(l10n.inviteInvalid, isError: true);
        case InviteRedemptionStatus.alreadyLinked:
          _setMessage(l10n.inviteAlreadyLinked, isError: true);
        case InviteRedemptionStatus.rateLimited:
          _setMessage(l10n.inviteRateLimited, isError: true);
      }
    } on Object catch (e) {
      if (mounted) _setMessage(failureMessage(l10n, e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Reloads the account context, then lets the router pick the landing
  /// page (the splash route always redirects to the user's home).
  Future<void> _reloadAndGoHome() async {
    setState(() => _busy = true);
    try {
      ref.invalidate(accountContextProvider);
      final account = await ref.read(accountContextProvider.future);
      if (mounted && (account?.availableSides.isNotEmpty ?? false)) {
        context.go(Routes.splash);
      }
    } on Object catch (e) {
      if (mounted) {
        _setMessage(
          failureMessage(AppLocalizations.of(context), e),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMessage(String message, {required bool isError}) {
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final email = ref.watch(currentUserEmailProvider) ?? '';
    final hasSides =
        ref.watch(accountContextProvider).value?.availableSides.isNotEmpty ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        automaticallyImplyLeading: hasSides,
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.family_restroom,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingBody(email),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('invite-code'),
                  controller: _code,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: l10n.inviteCodeLabel,
                    hintText: l10n.inviteCodeHint,
                  ),
                  validator: (v) => normalizeInviteCode(v ?? '') == null
                      ? l10n.inviteCodeInvalidFormat
                      : null,
                  onFieldSubmitted: (_) => _redeem(),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _messageIsError ? theme.colorScheme.error : null,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _redeem,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(l10n.redeemButton),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _reloadAndGoHome,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.checkAgain),
                ),
                if (!hasSides) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => ref.read(authRepositoryProvider).signOut(),
                    child: Text(l10n.signOut),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlatformAdminScreen extends ConsumerWidget {
  const PlatformAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: EmptyView(
          icon: Icons.desktop_windows_outlined,
          message: '${l10n.platformAdminTitle}\n\n${l10n.platformAdminBody}',
          action: FilledButton.tonal(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: Text(l10n.signOut),
          ),
        ),
      ),
    );
  }
}

class ChooseSideScreen extends ConsumerWidget {
  const ChooseSideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Future<void> choose(AppSide side) =>
        ref.read(preferredSideProvider.notifier).choose(side);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              l10n.chooseSideTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _SideCard(
              icon: Icons.apartment_rounded,
              title: l10n.sideSchool,
              description: l10n.sideSchoolDescription,
              onTap: () => choose(AppSide.school),
            ),
            const SizedBox(height: 12),
            _SideCard(
              icon: Icons.family_restroom_rounded,
              title: l10n.sideParent,
              description: l10n.sideParentDescription,
              onTap: () => choose(AppSide.parent),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 36),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
