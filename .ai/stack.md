<tech-stack>
Frontend 
- Flutter (3.x, Dart 3) jako główna technologia frontendowa.
- Jedna baza kodu dla:
- aplikacji webowej (panel trenera i użytkownika),
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

CI/CD i Hosting:
- Github Actions do tworzenia pipeline’ów CI/CD
- DigitalOcean do hostowania aplikacji za pośrednictwem obrazu docker
</tech-stack>

Dokonaj krytycznej lecz rzeczowej analizy czy <tech-stack> odpowiednio adresuje potrzeby @prd.md. Rozważ następujące pytania:
1. Czy technologia pozwoli nam szybko dostarczyć MVP?
2. Czy rozwiązanie będzie skalowalne w miarę wzrostu projektu?
3. Czy koszt utrzymania i rozwoju będzie akceptowalny?
4. Czy potrzebujemy aż tak złożonego rozwiązania?
5. Czy nie istnieje prostsze podejście, które spełni nasze wymagania?
6. Czy technologie pozwoli nam zadbać o odpowiednie bezpieczeństwo?