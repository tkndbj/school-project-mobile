import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:school_platform/src/core/config/app_config.dart';
import 'package:school_platform/src/core/errors/app_failure.dart';

/// Obtains a Google ID token for Supabase's `signInWithIdToken`.
///
/// Abstracted so the auth repository can be tested without the native plugin.
abstract interface class GoogleIdTokenSource {
  /// Runs the interactive Google sign-in and returns the ID token.
  ///
  /// Throws [CancelledFailure] when the user dismisses the dialog.
  Future<String> obtainIdToken();

  Future<void> signOut();
}

/// [GoogleIdTokenSource] backed by `google_sign_in` 7.x.
class GoogleSignInGateway implements GoogleIdTokenSource {
  GoogleSignInGateway(this._config, {GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final AppConfig _config;
  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  /// `initialize` must run exactly once before any other call.
  Future<void> _ensureInitialized() {
    return _initialization ??= _googleSignIn.initialize(
      // iOS needs its own client id; Android derives it from the signing key.
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _config.googleIosClientId
          : null,
      // The ID token audience must be the web client configured in Supabase.
      serverClientId: _config.googleWebClientId,
    );
  }

  @override
  Future<String> obtainIdToken() async {
    if (!_config.googleSignInConfigured) {
      throw const AuthFailure(AuthFailureKind.googleNotAvailable);
    }
    await _ensureInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw const AuthFailure(AuthFailureKind.googleNotAvailable);
    }
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(AuthFailureKind.unknown);
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const CancelledFailure();
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const AuthFailure(AuthFailureKind.googleNotAvailable);
      }
      throw const AuthFailure(AuthFailureKind.unknown);
    }
  }

  @override
  Future<void> signOut() async {
    if (!_config.googleSignInConfigured) return;
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}
