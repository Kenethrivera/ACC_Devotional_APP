import 'package:flutter/material.dart';

import '../../features/auth/domain/models/auth_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/auth_entry_screen.dart';
import '../../features/authorization/domain/models/user_role.dart';
import '../../features/authorization/domain/repositories/authorization_repository.dart';
import '../../features/authorization/presentation/controllers/authorization_controller.dart';
import '../../features/authorization/presentation/screens/manage_administrators_screen.dart';
import '../../features/dashboard/presentation/screens/member_dashboard_screen.dart';

class AppGate extends StatefulWidget {
  final AuthController authController;
  final AuthorizationRepository authorizationRepository;

  const AppGate({
    super.key,
    required this.authController,
    required this.authorizationRepository,
  });

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late final AuthorizationController authorizationController;
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    authorizationController =
        AuthorizationController(widget.authorizationRepository);
    widget.authController.addListener(_syncAuth);
    _syncAuth();
  }

  void _syncAuth() {
    final auth = widget.authController;
    final user = auth.user;
    if (user == null || !user.isEmailVerified || auth.isPasswordRecovery) {
      if (_activeUserId != null) {
        _activeUserId = null;
        authorizationController.clear();
      }
      return;
    }

    if (_activeUserId != user.id) {
      _activeUserId = user.id;
      authorizationController.loadRole(user.id);
    }
  }

  @override
  void dispose() {
    widget.authController.removeListener(_syncAuth);
    authorizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.authController,
        authorizationController,
      ]),
      builder: (context, _) {
        final auth = widget.authController;
        final user = auth.user;

        if (user == null || auth.isPasswordRecovery) {
          return AuthEntryScreen(controller: auth);
        }

        if (!user.isEmailVerified) {
          return Scaffold(
            appBar: AppBar(title: const Text('Verify Your Email')),
            body: Center(
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : auth.signOut,
                child: const Text('Email not verified — Log Out'),
              ),
            ),
          );
        }

        final access = authorizationController;
        if (access.userId != user.id || access.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (access.errorMessage != null || access.role == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load your role.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => access.loadRole(user.id, force: true),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: auth.isLoading ? null : auth.signOut,
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            ),
          );
        }

        return _RoleHome(
          role: access.role!,
          user: user,
          authController: auth,
          authorizationRepository: widget.authorizationRepository,
        );
      },
    );
  }
}

class _RoleHome extends StatelessWidget {
  final UserRole role;
  final AuthUser user;
  final AuthController authController;
  final AuthorizationRepository authorizationRepository;

  const _RoleHome({
    required this.role,
    required this.user,
    required this.authController,
    required this.authorizationRepository,
  });

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.member) {
      return MemberDashboardScreen(
        user: user,
        onSignOut: authController.signOut,
      );
    }

    final title = switch (role) {
      UserRole.member => 'Member Dashboard',
      UserRole.admin => 'Admin Dashboard',
      UserRole.superAdmin => 'Super Admin Dashboard',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Power of 4+'),
        actions: [
          TextButton(
            onPressed: authController.isLoading
                ? null
                : authController.signOut,
            child: const Text('Log Out'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text('Coming Soon'),
            if (role == UserRole.superAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ManageAdministratorsScreen(
                        repository: authorizationRepository,
                      ),
                    ),
                  );
                },
                child: const Text('Manage Administrators'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
