import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String supabaseUrl;
  final String supabasePublishableKey;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  static Future<AppConfig> load() async {
    await dotenv.load(fileName: 'asset/config.env');

    final url = dotenv.get('SUPABASE_URL').trim();
    final key = dotenv.get('SUPABASE_PUBLISHABLE_KEY').trim();

    final uri = Uri.tryParse(url);

    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('Invalid SUPABASE_URL');
    }

    if (key.isEmpty) {
      throw StateError('Missing SUPABASE_PUBLISHABLE_KEY');
    }

    return AppConfig(supabaseUrl: url, supabasePublishableKey: key);
  }
}
