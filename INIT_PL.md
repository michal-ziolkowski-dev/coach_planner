Supabase Flutter Initialization
Ten dokument opisuje powtarzalny sposób przygotowania struktury plików do integracji Supabase z projektem Flutter (mobile/web).
0. Wymagania wstępne (sprawdź, zanim zaczniesz)
Projekt korzysta z Fluttera 4.x i Dart 3.5+.
W pliku pubspec.yaml dodano zależności:
supabase_flutter
flutter_dotenv (do obsługi zmiennych środowiskowych)
W katalogu głównym istnieje plik .env z wpisami SUPABASE_URL i SUPABASE_ANON_KEY.
Istnieje plik lib/db/database_types.dart zawierający typy wygenerowane przez Supabase CLI (np. supabase gen types dart ...).
Jeśli go brakuje, zatrzymaj się i wygeneruj typy zgodnie z dokumentacją Supabase, aby zachować bezpieczeństwo typów.
1. Konfiguracja zmiennych środowiskowych
Utwórz plik lib/core/app_env.dart:
SUPABASE_ANON
// lib/core/app_env.dartimport 'package:flutter_dotenv/flutter_dotenv.dart';/// Centralne źródło zmiennych środowiskowych./// Rzuca opisowy wyjątek, jeśli klucz nie jest ustawiony,/// dzięki czemu błąd wychwycisz od razu przy starcie aplikacji.class AppEnv {  AppEnv._();  static String get supabaseUrl => _read('SUPABASE_URL');  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');  static String _read(String key) {    final value = dotenv.env[key];    if (value == null || value.isEmpty) {      throw StateError('Brak zmiennej środowiskowej $key w pliku .env');    }    return value;  }}
2. Inicjalizacja klienta Supabase
Utwórz plik lib/services/supabase_client.dart:
// lib/services/supabase_client.dartimport 'package:supabase_flutter/supabase_flutter.dart';import '../core/app_env.dart';import '../db/database_types.dart';/// Globalny punkt dostępu do klienta Supabase./// `SupabaseClient<Database>` zapewnia pełne wsparcie typów.late final SupabaseClient<Database> supabaseClient;/// Wołaj tę funkcję przed uruchomieniem aplikacji (np. w `main()`).Future<void> initSupabase() async {  await Supabase.initialize(    url: AppEnv.supabaseUrl,    anonKey: AppEnv.supabaseAnonKey,  );  supabaseClient = Supabase.instance.client as SupabaseClient<Database>;}
> Uwaga: plik database_types.dart pochodzi z Supabase CLI i powinien eksportować typ Database, np. typedef Database = ...;. Dzięki temu zapytania do Supabase są typowane.
3. Uruchomienie aplikacji z inicjalizacją
Zaktualizuj lib/main.dart, aby ładować .env oraz Supabase zanim wywołasz runApp:
// lib/main.dartimport 'package:flutter/material.dart';import 'package:flutter_dotenv/flutter_dotenv.dart';import 'services/supabase_client.dart';import 'app.dart';Future<void> main() async {  WidgetsFlutterBinding.ensureInitialized();  await dotenv.load(fileName: '.env'); // 1. Ładujemy zmienne środowiskowe.  await initSupabase();                // 2. Inicjalizujemy Supabase.  runApp(const CoachPlannerApp());}
4. Korzystanie w widgetach / serwisach
Tam, gdzie potrzebujesz Supabase, importuj supabase_client.dart i używaj globalnej instancji:
// lib/features/auth/data/auth_repository.dartimport 'package:supabase_flutter/supabase_flutter.dart';import '../../services/supabase_client.dart';class AuthRepository {  Future<AuthResponse> signIn({    required String email,    required String password,  }) {    // supabaseClient ma typ SupabaseClient<Database>,    // więc masz podpowiedzi typów dla tabel i RPC.    return supabaseClient.auth.signInWithPassword(      email: email,      password: password,    );  }}
5. Dodatkowe uwagi
Hot reload: po zmianie .env wykonaj restart aplikacji – plik jest ładowany tylko raz.
Bezpieczeństwo: nigdy nie commituj .env z prawdziwymi kluczami; użyj plików .env.example.
Testy: w testach jednostkowych możesz stworzyć fake’owego klienta Supabase i wstrzyknąć go zamiast korzystać z globalnego singletonu.
