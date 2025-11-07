Frontend - Astro z React dla komponentów interaktywnych:
- Flutter (3.x, Dart 3) jako główna technologia frontendowa.
- Jedna baza kodu dla:
- aplikacji webowej (panel trenera i użytkownika),
- oraz potencjalnie aplikacji mobilnej (Android/iOS) w kolejnych etapach.
- Responsywny UI dopasowany do desktop / tablet / mobile.
- Zarządzanie stanem: Riverpod lub Bloc (czytelna separacja logiki, skalowalne).
- Nawigacja: go_router – wsparcie dla URL (ważne dla wersji webowej).
- Formularze i walidacja: np. flutter_form_builder.
- Kalendarz i sloty: np. table_calendar / dedykowane widoki pod grafik trenerów.
- Integracja z backendem przez:
- Supabase Dart SDK (auth, baza, realtime),
- lub klasyczne REST/GraphQL (jeśli będzie dodatkowa warstwa).

Backend - Supabase jako kompleksowe rozwiązanie backendowe:
- Zapewnia bazę danych PostgreSQL
- Zapewnia SDK w wielu językach, które posłużą jako Backend-as-a-Service
- Jest rozwiązaniem open source, które można hostować lokalnie lub na własnym serwerze
- Posiada wbudowaną autentykację użytkowników

AI - Komunikacja z modelami przez usługę Openrouter.ai:
- Dostęp do szerokiej gamy modeli (OpenAI, Anthropic, Google i wiele innych), które pozwolą nam znaleźć rozwiązanie zapewniające wysoką efektywność i niskie koszta
- Pozwala na ustawianie limitów finansowych na klucze API

CI/CD i Hosting:
- Github Actions do tworzenia pipeline’ów CI/CD
- DigitalOcean do hostowania aplikacji za pośrednictwem obrazu docker