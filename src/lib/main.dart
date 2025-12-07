import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_client.dart';
import 'app.dart';

/// Main entry point of the Coach Planner application.
///
/// This function initializes all necessary services before running the app:
/// 1. Ensures Flutter bindings are initialized
/// 2. Loads environment variables from .env file
/// 3. Initializes Supabase client
/// 4. Runs the main application widget
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  // Initialize Supabase client
  await initSupabase();

  runApp(const CoachPlannerApp());
}
