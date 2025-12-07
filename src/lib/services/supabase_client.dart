import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_env.dart';

/// Global Supabase client instance.
///
/// This client is initialized in [initSupabase] and should be used throughout
/// the application for all Supabase interactions.
late final SupabaseClient supabaseClient;

/// Initializes the Supabase client with credentials from environment variables.
///
/// This function must be called before any Supabase operations are performed.
/// It reads the Supabase URL and anonymous key from the environment
/// configuration and initializes the global [supabaseClient].
///
/// Throws [StateError] if environment variables are missing or invalid.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  supabaseClient = Supabase.instance.client;
}


