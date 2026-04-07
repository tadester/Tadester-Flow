import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get backendApiUrl => _require('BACKEND_API_URL');
  static String? get googleMapsApiKey => _optional('GOOGLE_MAPS_API_KEY');

  static bool get hasGoogleMapsKey {
    final String? value = googleMapsApiKey;
    return value != null &&
        value.isNotEmpty &&
        value != 'YOUR_GOOGLE_MAPS_API_KEY';
  }

  static String _require(String key) {
    final String? value = dotenv.env[key];

    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }

    return value;
  }

  static String? _optional(String key) {
    final String? value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
