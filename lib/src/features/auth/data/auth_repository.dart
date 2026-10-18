import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';
import 'package:school_platform/src/core/providers.dart';
import 'package:school_platform/src/features/auth/data/google_sign_in_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final googleIdTokenSourceProvider = Provider<GoogleIdTokenSource>(
  (ref) => GoogleSignInGateway(ref.watch(appConfigProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    auth: ref.watch(supabaseClientProvider).auth,
    google: ref.watch(googleIdTokenSourceProvider),
    passwordResetRedirect: ref.watch(appConfigProvider).webBaseUrl,
  ),
);

/// Wraps Supabase Auth. All methods throw [AppFailure]s only.
class AuthRepository {
  AuthRepository({
    required GoTrueClient auth,
    required GoogleIdTokenSource google,
    required String passwordResetRedirect,
  }) : _auth = auth,
       _google = google,
       _passwordResetRedirect = passwordResetRedirect;

  final GoTrueClient _auth;
  final GoogleIdTokenSource _google;
  final String _passwordResetRedirect;

  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Native Google sign-in exchanged for a Supabase session.
  Future<void> signInWithGoogle() async {
    try {
      final idToken = await _google.obtainIdToken();
      await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Email/password sign-in for invited school staff.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Sends the password reset email. The link opens the web app, which
  /// handles choosing the new password.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: _passwordResetRedirect,
      );
    } on Object catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (e) {
      throw AppFailure.from(e);
    } finally {
      // Best effort: forget the Google account so the next sign-in can pick
      // a different one. Never blocks signing out of the app.
      unawaited(_google.signOut().catchError((Object _) {}));
    }
  }

  /// Clears the local session without contacting the server (used after the
  /// account was deleted server-side).
  Future<void> signOutLocally() async {
    try {
      // The default scope (local) clears this device only.
      await _auth.signOut();
    } on Object catch (e) {
      debugPrint('Local sign-out failed: $e');
    }
    unawaited(_google.signOut().catchError((Object _) {}));
  }
}

/// The current Supabase session, kept in sync with auth state changes.
final authSessionProvider = NotifierProvider<AuthSessionController, Session?>(
  AuthSessionController.new,
);

class AuthSessionController extends Notifier<Session?> {
  @override
  Session? build() {
    final repository = ref.watch(authRepositoryProvider);
    final subscription = repository.authStateChanges.listen(
      (event) => state = event.session,
      // Refresh failures surface as a signed-out state on the next event.
      onError: (Object error) => debugPrint('Auth state error: $error'),
    );
    ref.onDispose(subscription.cancel);
    return repository.currentSession;
  }
}

/// The signed-in user's id, or `null`. Watching this instead of the session
/// avoids rebuilding dependents on every token refresh.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authSessionProvider.select((s) => s?.user.id)),
);

final currentUserEmailProvider = Provider<String?>(
  (ref) => ref.watch(authSessionProvider.select((s) => s?.user.email)),
);
