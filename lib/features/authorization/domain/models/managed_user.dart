import 'user_role.dart';

class ManagedUser {
  final String userId;
  final String email;
  final UserRole role;

  const ManagedUser({
    required this.userId,
    required this.email,
    required this.role,
  });
}
