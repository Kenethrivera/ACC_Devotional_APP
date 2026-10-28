import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static Future<SupabaseClient> initialize(AppConfig config) async {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );

    return Supabase.instance.client;
  }
}
