import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/env_config.dart';

class SupabaseClientManager {
  static SupabaseClient? _instance;

  static SupabaseClient get instance {
    if (_instance == null) {
      throw StateError('SupabaseClientManager not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  static Future<void> initialize() async {
    await dotenv.load();

    if (!EnvConfig.isConfigured) {
      throw StateError(
        'Supabase credentials not found in .env. '
        'Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set.',
      );
    }

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      // publishableKey is the successor to anonKey
      publishableKey: EnvConfig.supabaseAnonKey,
    );

    _instance = Supabase.instance.client;
  }

  static GoTrueClient get auth => instance.auth;

  static User? get currentUser => auth.currentUser;

  static String? get userId => currentUser?.id;
}
