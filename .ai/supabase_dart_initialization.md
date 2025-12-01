## Supabase Flutter Initialization (Markdown)

### Prerequisites
- Flutter 4.x, Dart 3.5+
- `pubspec.yaml` dependencies: `supabase_flutter`, `flutter_dotenv`
- `.env` at repo root with `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `lib/db/database_types.dart` generated via Supabase CLI; ensure it exposes `Database` type  
  *If coś brakuje → zatrzymaj się i uzupełnij przed dalszymi krokami.*

---

### 1. Environment Wrapper (`lib/core/app_env.dart`)
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');

  static String _read(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Brak zmiennej środowiskowej $key w pliku .env');
    }
    return value;
  }
}
```
Komentarz: centralizuje odczyt `.env`, rzuca błąd przy brakujących wartościach.

---

### 2. Supabase Client (`lib/services/supabase_client.dart`)
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_env.dart';
import '../db/database_types.dart';

late final SupabaseClient<Database> supabaseClient;

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
  supabaseClient = Supabase.instance.client as SupabaseClient<Database>;
}
```
Komentarz: singleton klienta typowanego `Database`; funkcję `initSupabase` wołamy przed `runApp`.

---

### 3. Main Entry (`lib/main.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_client.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await initSupabase();

  runApp(const CoachPlannerApp());
}
```
Komentarz: najpierw `.env`, potem inicjalizacja Supabase.

---

### 4. Użycie w kodzie (`lib/features/auth/data/auth_repository.dart`)
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_client.dart';

class AuthRepository {
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
```
Komentarz: `supabaseClient` udostępnia typowane API (tabele, RPC) zgodnie z `Database`.

---

### 5. Tips
- Po zmianach `.env` wykonaj pełny restart (nie hot reload).
- Nie commituj prawdziwych kluczy; użyj `.env.example`.
- W testach twórz fake klienta i wstrzykuj zależność zamiast singletonu.

