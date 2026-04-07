import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final String? value = dotenv.env[key];

    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }

    return value;
  }
}
