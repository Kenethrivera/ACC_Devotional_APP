
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription<AuthUser?> _subscription;

  AuthUser? _user;
  bool _isLoading = false;
  bool _isPasswordRecovery = false;
  String? _errorMessage;

  AuthController(this._repository) {
    _user = _repository.currentUser;

    _subscription = _repository.authStateChanges.listen(
      (user) {
        _user = user;
        notifyListeners();
      },
      
onError: (Object error, StackTrace stackTrace) {
        debugPrint('Authentication error: $error');

        final message = error.toString().toLowerCase();

        if (message.contains(
          'error getting user email from external provider',
        )) {
          _errorMessage =
              'Facebook could not provide your email address. '
              'Please use Google Sign-In or your email and password instead.';
        } else {
          _errorMessage =
              'Authentication could not be completed. '
              'Please try again.';
        }

        notifyListeners();
      },
    );
  }

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // EMAIL / PASSWORD LOGIN
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signInWithEmail(
        email: email.trim(),
        password: password,
      );

      _user = _repository.currentUser;
      return _user != null;
    } catch (error) {
      debugPrint('Login failed: $error');
      _errorMessage =
          'Sign in failed. Check your credentials and email verification.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REGISTRATION
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signUp(
        email: email.trim(),
        password: password,
      );
      return true;
    } catch (error) {
      debugPrint('Registration failed: $error');
      _errorMessage =
          'Registration failed. Please check your details or try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // VERIFY REGISTRATION OTP
  Future<bool> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.verifySignUpCode(
        email: email.trim(),
        code: code.trim(),
      );

      _user = _repository.currentUser;
      return true;
    } catch (error) {
      debugPrint('Registration OTP failed: $error');
      _errorMessage =
          'Invalid or expired verification code.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REQUEST PASSWORD RECOVERY OTP
  Future<bool> requestPasswordReset(String email) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.sendPasswordResetEmail(
        email.trim(),
      );
      return true;
    } catch (error) {
      debugPrint('Recovery request failed: $error');
      _errorMessage =
          'Unable to send the code. Please try again later.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // VERIFY PASSWORD RECOVERY OTP
  Future<bool> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;

    // Prevent navigation to the normal dashboard
    // while the recovery OTP establishes a session.
    _isPasswordRecovery = true;
    notifyListeners();

    try {
      await _repository.verifyRecoveryCode(
        email: email.trim(),
        code: code.trim(),
      );

      _user = _repository.currentUser;

      if (_user == null) {
        throw StateError('No recovery session established.');
      }

      return true;
    } catch (error) {
      debugPrint('Recovery OTP failed: $error');
      _isPasswordRecovery = false;
      _errorMessage =
          'Invalid or expired verification code.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE PASSWORD AFTER OTP VERIFICATION
  Future<bool> changeRecoveredPassword(
    String newPassword,
  ) async {
    if (_isLoading) return false;

    if (!_isPasswordRecovery ||
        _repository.currentUser == null) {
      _errorMessage =
          'Please verify your recovery code first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updatePassword(newPassword);

      // Require a fresh login after resetting.
      await _repository.signOut();

      _user = null;
      _isPasswordRecovery = false;
      return true;
    } catch (error) {
      debugPrint('Password update failed: $error');
      _errorMessage =
          'Unable to finish the password reset. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CANCEL RECOVERY AND INVALIDATE ITS SESSION
  Future<void> cancelPasswordRecovery() async {
    if (_isPasswordRecovery) {
      await signOut();
    } else {
      clearError();
    }
  }

  // LOGOUT
  Future<void> signOut() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signOut();
      _user = null;
      _isPasswordRecovery = false;
    } catch (error) {
      debugPrint('Logout failed: $error');
      _errorMessage = 'Unable to log out.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
Future<void> signInWithGoogle() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signInWithGoogle();

      // Google redirects back to the application.
      // The existing authStateChanges listener
      // handles the authenticated session.
    } catch (error) {
      debugPrint('Google Sign-In failed: $error');

      _errorMessage =
          'Unable to sign in with Google. '
          'Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
Future<void> signInWithFacebook() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signInWithFacebook();

      // Supabase will notify our existing
      // authStateChanges listener after login.
    } catch (error) {
      debugPrint('Facebook Sign-In failed: $error');

      _errorMessage =
          'Unable to sign in with Facebook. '
          'Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
