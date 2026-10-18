import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/core/locale/locale_controller.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/features/account/data/account_repository.dart';
import 'package:school_platform/src/features/account/domain/account_context.dart';
import 'package:school_platform/src/features/auth/data/auth_repository.dart';

/// The routing context of the signed-in user (`null` when signed out).
///
/// Rebuilds whenever the signed-in user changes. Linking guardian records by
/// email runs first so a parent whose school just registered their email sees
/// their children immediately.
final accountContextProvider = FutureProvider<AccountContext?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repository = ref.watch(accountRepositoryProvider);
  try {
    await repository.linkGuardianRecords();
  } on Object catch (e) {
    // Linking is an optimisation (database triggers also link); never block
    // the user from signing in because of it.
    debugPrint('Guardian linking failed: $e');
  }
  return repository.fetchContext();
});

/// The side of the app the user last chose. Only meaningful when the account
/// has both sides; see [effectiveSideProvider].
final preferredSideProvider =
    NotifierProvider<PreferredSideController, AppSide?>(
      PreferredSideController.new,
    );

class PreferredSideController extends Notifier<AppSide?> {
  @override
  AppSide? build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(PreferenceKeys.activeSide);
    return AppSide.values.where((s) => s.name == stored).firstOrNull;
  }

  Future<void> choose(AppSide side) async {
    state = side;
    await ref
        .read(sharedPreferencesProvider)
        .setString(PreferenceKeys.activeSide, side.name);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(PreferenceKeys.activeSide);
  }
}

/// The side currently in use, or `null` when the user still has to choose
/// (or has no side at all).
final effectiveSideProvider = Provider<AppSide?>((ref) {
  final context = ref.watch(accountContextProvider).value;
  if (context == null) return null;
  return resolveEffectiveSide(
    available: context.availableSides,
    preferred: ref.watch(preferredSideProvider),
  );
});

@visibleForTesting
AppSide? resolveEffectiveSide({
  required Set<AppSide> available,
  required AppSide? preferred,
}) {
  if (available.length == 1) return available.single;
  if (preferred != null && available.contains(preferred)) return preferred;
  return null;
}
