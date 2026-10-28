import '../models/auth_user.dart';

abstract class AuthRepository {
  // Current authenticated user
  AuthUser? get currentUser;

  // Observe login/logout/session changes
  Stream<AuthUser?> get authStateChanges;

  // Register with email and password
  Future<void> signUp({required String email, required String password});

  // Login with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  // Login or register through Google
  Future<void> signInWithGoogle();

  // Resend account verification
  Future<void> resendVerificationEmail(String email);

  // Request password recovery
  Future<void> sendPasswordResetEmail(String email);

  // Set new password after recovery
  Future<void> updatePassword(String newPassword);

  // Log out of current device
  Future<void> signOut();

  Future<void> verifySignUpCode({
  required String email,
  required String code,
});

Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  });
  
Future<void> signInWithFacebook();

}



