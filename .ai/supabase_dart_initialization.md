## Supabase Flutter Initialization (Markdown)

### Prerequisites
- Flutter 4.x, Dart 3.5+
- `pubspec.yaml` dependencies: `supabase_flutter`, `flutter_dotenv`
- `.env` at repo root with `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `src/lib/models/generated_classes.dart` generated via [Supadart](https://github.com/mmvergara/supadart) CLI; ensure it exposes `Database` type

---

### 1. Environment Wrapper (`src/lib/core/app_env.dart`)
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

---

### 2. Supabase Client (`src/lib/services/supabase_client.dart`)
```dart
   import 'package:supabase_flutter/supabase_flutter.dart';
     import '../core/app_env.dart';

     late final SupabaseClient supabaseClient;

     Future<void> initSupabase() async {
       await Supabase.initialize(
         url: AppEnv.supabaseUrl,
         anonKey: AppEnv.supabaseAnonKey,
       );
       supabaseClient = Supabase.instance.client;
     }
```

---

### 3. Main Entry (`src/lib/main.dart`)
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

### 4. Użycie w kodzie (`src/lib/features/auth/data/auth_repository.dart`)
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

---