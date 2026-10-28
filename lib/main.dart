import 'package:flutter/material.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/routing/app_gate.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

import 'features/authorization/domain/repositories/authorization_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration and repositories.
  final bootstrap = await AppBootstrap.initialize();

  runApp(
    PowerOfFourApp(
      authRepository: bootstrap.authRepository,
      authorizationRepository: bootstrap.authorizationRepository,
    ),
  );
}

class PowerOfFourApp extends StatefulWidget {
  final AuthRepository authRepository;
  final AuthorizationRepository authorizationRepository;

  const PowerOfFourApp({
    super.key,
    required this.authRepository,
    required this.authorizationRepository,
  });

  @override
  State<PowerOfFourApp> createState() => _PowerOfFourAppState();
}

class _PowerOfFourAppState extends State<PowerOfFourApp> {
  late final AuthController authController;

  @override
  void initState() {
    super.initState();

    authController = AuthController(widget.authRepository);
  }

  @override
  void dispose() {
    authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power of 4+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // Centralized authentication and
      // role-based navigation.
      home: AppGate(
        authController: authController,
        authorizationRepository: widget.authorizationRepository,
      ),
    );
  }
}
