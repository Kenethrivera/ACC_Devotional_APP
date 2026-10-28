import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/managed_user.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/authorization_repository.dart';
import '../../../../core/ui/app_feedback.dart';

class ManageAdministratorsScreen extends StatefulWidget {
  final AuthorizationRepository repository;

  const ManageAdministratorsScreen({super.key, required this.repository});

  @override
  State<ManageAdministratorsScreen> createState() =>
      _ManageAdministratorsScreenState();
}

class _ManageAdministratorsScreenState
    extends State<ManageAdministratorsScreen> {
  final _search = TextEditingController();

  late Future<List<ManagedUser>> _usersFuture;
  String? _busyUserId;

  @override
  void initState() {
    super.initState();

    _usersFuture = widget.repository.listManageableUsers();
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _reload() {
    setState(() {
      _usersFuture = widget.repository.listManageableUsers();
    });
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.member:
        return 'Member';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  Future<void> _changeRole(ManagedUser user) async {
    if (user.role == UserRole.superAdmin || _busyUserId != null) {
      return;
    }

    final promote = user.role == UserRole.member;
    final action = promote ? 'Promote' : 'Remove Admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$action?'),
          content: Text(
            promote
                ? 'Give ${user.email} administrator access?'
                : 'Remove administrator access from ${user.email}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _busyUserId = user.userId;
    });

    try {
      await widget.repository.setAdminAccess(
        userId: user.userId,
        makeAdmin: promote,
      );

      if (!mounted) return;

      
AppFeedback.show(
        context,
        message: promote
            ? '${user.email} is now an Admin.'
            : '${user.email} is now a Member.',
        type: AppMessageType.success,
      );


      _reload();
    } catch (error) {
      debugPrint('Role update failed: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update permissions. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyUserId = null;
        });
      }
    }
  }

  Widget _userCard(ManagedUser user, bool isNarrow) {
    final protected = user.role == UserRole.superAdmin;
    final promote = user.role == UserRole.member;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _roleLabel(user.role),
          style: const TextStyle(color: AppColors.blue, fontSize: 13),
        ),
      ],
    );

    final action = protected
        ? const Text(
            'Protected',
            style: TextStyle(color: AppColors.navy, fontSize: 13),
          )
        : OutlinedButton(
            onPressed: _busyUserId != null ? null : () => _changeRole(user),
            child: _busyUserId == user.userId
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(promote ? 'Promote to Admin' : 'Remove Admin'),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [details, const SizedBox(height: 12), action],
            )
          : Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                action,
              ],
            ),
    );
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Administrators'),
        actions: [
          TextButton(
            onPressed: _busyUserId == null ? _reload : null,
            child: const Text('Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member Permissions',
                    style: GoogleFonts.lora(
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage administrator access for '
                    'registered members.',
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'Search by email',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 560;

                        return FutureBuilder<List<ManagedUser>>(
                          future: _usersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Unable to load members.'),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _reload,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final query = _search.text.trim().toLowerCase();

                            final users = (snapshot.data ?? [])
                                .where(
                                  (user) =>
                                      user.email.toLowerCase().contains(query),
                                )
                                .toList();

                            if (users.isEmpty) {
                              return const Center(
                                child: Text('No members found.'),
                              );
                            }

                            return ListView.separated(
                              itemCount: users.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _userCard(users[index], isNarrow);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
