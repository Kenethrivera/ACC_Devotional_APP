import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/auth_user.dart' as app_auth;
import '../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  // Convert Supabase User into our independent AuthUser model.
  app_auth.AuthUser? _mapUser(User? user) {
    if (user == null) return null;

    return app_auth.AuthUser(
      id: user.id,
      email: user.email,
      isEmailVerified: user.emailConfirmedAt != null,
    );
  }

  // Get the currently authenticated user.
  @override
  app_auth.AuthUser? get currentUser {
    return _mapUser(_client.auth.currentSession?.user);
  }

  // Listen for authentication state changes.
  
@override
  Stream<app_auth.AuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      if (kDebugMode) {
        debugPrint('AUTH EVENT: ${data.event.name}');
        debugPrint('SESSION EXISTS: ${data.session != null}');
        debugPrint('USER EXISTS: ${data.session?.user != null}');
      }

      return _mapUser(data.session?.user);
    });
  }

  // Register with email and password.
  @override
  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email.trim(), password: password);
  }

  // Sign in with email and password.
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Google Sign-In.
  @override
  Future<void> signInWithGoogle() async {
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'poweroffour://login-callback/',
    );

    if (!launched) {
      throw const AuthException('Unable to open Google Sign-In.');
    }
  }

  // Resend verification email.
  @override
  Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  // Send password recovery email.
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  // Update password after recovery.
  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // Log out of the current device only.
  @override
  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  
@override
  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
  }

  

@override
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
  }

  
@override
  Future<void> signInWithFacebook() async {
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : 'poweroffour://login-callback/',
    );

    if (!launched) {
      throw const AuthException('Unable to open Facebook Sign-In.');
    }
  }




}
