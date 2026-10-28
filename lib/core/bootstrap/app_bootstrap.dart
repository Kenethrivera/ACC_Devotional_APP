import '../../features/auth/data/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

import '../../features/authorization/data/supabase_authorization_repository.dart';
import '../../features/authorization/domain/repositories/authorization_repository.dart';

import '../config/app_config.dart';
import '../config/supabase_config.dart';

class AppBootstrap {
  final AuthRepository authRepository;
  final AuthorizationRepository authorizationRepository;

  const AppBootstrap._({
    required this.authRepository,
    required this.authorizationRepository,
  });

  static Future<AppBootstrap> initialize() async {
    // Load environment configuration.
    final config = await AppConfig.load();

    // Initialize shared Supabase infrastructure.
    final client = await SupabaseConfig.initialize(config);

    // Independent authentication service.
    final authRepository = SupabaseAuthRepository(client);

    // Independent authorization service.
    final authorizationRepository = SupabaseAuthorizationRepository(client);

    return AppBootstrap._(
      authRepository: authRepository,
      authorizationRepository: authorizationRepository,
    );
  }
}
