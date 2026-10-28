import 'package:flutter/foundation.dart';

import '../../domain/models/user_role.dart';
import '../../domain/repositories/authorization_repository.dart';

class AuthorizationController extends ChangeNotifier {
  final AuthorizationRepository _repository;

  AuthorizationController(this._repository);

  String? _userId;
  UserRole? _role;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestVersion = 0;

  String? get userId => _userId;
  UserRole? get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRole(String userId, {bool force = false}) async {
    if (!force && _userId == userId && (_isLoading || _role != null)) {
      return;
    }

    final version = ++_requestVersion;

    _userId = userId;
    _role = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final role = await _repository.getRoleForUser(userId);

      if (version != _requestVersion) return;

      _role = role;
    } catch (error) {
      if (version != _requestVersion) return;

      debugPrint('Authorization failed: $error');
      _errorMessage = 'Unable to load your account role.';
    } finally {
      if (version == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    ++_requestVersion;
    _userId = null;
    _role = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
