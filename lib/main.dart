import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/routing/app_gate.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

import 'features/authorization/domain/repositories/authorization_repository.dart';
import 'features/devotional/domain/repositories/devotional_administration_repository.dart';
import 'features/devotional/domain/repositories/devotional_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration and repositories.
  final bootstrap = await AppBootstrap.initialize();

  runApp(
    PowerOfFourApp(
      authRepository: bootstrap.authRepository,
      authorizationRepository: bootstrap.authorizationRepository,
      devotionalRepository: bootstrap.devotionalRepository,
      devotionalAdministrationRepository:
          bootstrap.devotionalAdministrationRepository,
    ),
  );
}

class PowerOfFourApp extends StatefulWidget {
  final AuthRepository authRepository;
  final AuthorizationRepository authorizationRepository;
  final DevotionalRepository devotionalRepository;
  final DevotionalAdministrationRepository devotionalAdministrationRepository;

  const PowerOfFourApp({
    super.key,
    required this.authRepository,
    required this.authorizationRepository,
    required this.devotionalRepository,
    required this.devotionalAdministrationRepository,
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],

      // Centralized authentication and
      // role-based navigation.
      home: AppGate(
        authController: authController,
        authorizationRepository: widget.authorizationRepository,
        devotionalRepository: widget.devotionalRepository,
        devotionalAdministrationRepository:
            widget.devotionalAdministrationRepository,
      ),
    );
  }
}
