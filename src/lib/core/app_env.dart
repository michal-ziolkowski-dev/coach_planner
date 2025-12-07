import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration wrapper for accessing environment variables.
///
/// This class provides type-safe access to environment variables loaded from
/// the .env file. It ensures all required variables are present and throws
/// an error if any are missing.
class AppEnv {
  AppEnv._();

  /// Supabase project URL from environment variables.
  static String get supabaseUrl => _read('SUPABASE_URL');

  /// Supabase anonymous key from environment variables.
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');

  /// Reads an environment variable and throws if it's missing or empty.
  ///
  /// [key] The name of the environment variable to read.
  ///
  /// Throws [StateError] if the variable is not found or is empty.
  static String _read(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Brak zmiennej środowiskowej $key w pliku .env');
    }
    return value;
  }
}
