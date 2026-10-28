import '../models/managed_user.dart';
import '../models/user_role.dart';

abstract class AuthorizationRepository {
  Future<UserRole> getRoleForUser(String userId);

  Future<List<ManagedUser>> listManageableUsers();

  Future<void> setAdminAccess({
    required String userId,
    required bool makeAdmin,
  });
}

