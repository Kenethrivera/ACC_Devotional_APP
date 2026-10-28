import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/managed_user.dart';
import '../domain/models/user_role.dart';
import '../domain/repositories/authorization_repository.dart';

class SupabaseAuthorizationRepository implements AuthorizationRepository {
  final SupabaseClient _client;

  SupabaseAuthorizationRepository(this._client);

  UserRole _parseRole(String role) {
    switch (role) {
      case 'member':
        return UserRole.member;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        throw StateError('Unknown role: $role');
    }
  }

  @override
  Future<UserRole> getRoleForUser(String userId) async {
    final result = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();

    if (result == null) {
      throw StateError('User role not found');
    }

    return _parseRole(result['role'] as String);
  }

  @override
  Future<List<ManagedUser>> listManageableUsers() async {
    final result = await _client.rpc('list_manageable_users');

    final rows = result as List<dynamic>;

    return rows.map((row) {
      final data = Map<String, dynamic>.from(row as Map);

      return ManagedUser(
        userId: data['user_id'] as String,
        email: (data['email'] as String?) ?? 'No email',
        role: _parseRole(data['role'] as String),
      );
    }).toList();
  }

  @override
  Future<void> setAdminAccess({
    required String userId,
    required bool makeAdmin,
  }) async {
    await _client.rpc(
      'set_admin_access',
      params: {'p_target_user_id': userId, 'p_make_admin': makeAdmin},
    );
  }
}
