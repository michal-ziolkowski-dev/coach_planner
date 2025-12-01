# Auto Conventional Commit

Napisz wiadomość commita w formacie Conventional Commits, podsumowując **WSZYSTKIE** aktualne zmiany w repozytorium.

## Wejście z gita

- Status: !`git status --short`
- Diff zmian zstage'owanych: !`git diff --cached`
- Diff zmian niezstage'owanych: !`git diff`

## Zasady

1. Najpierw przeanalizuj *cały* diff z powyższych komend – nie ignoruj żadnego pliku.
2. Wybierz odpowiedni typ z: `feat`, `fix`, `docs`, `chore`, `refactor`, `perf`, `test`, `ci`.
3. Napisz **jednolinijkowy** commit message w formacie:

   `type(scope?): opis w trybie rozkazującym`

   Przykład:  
   `feat(auth): add JWT-based login flow`
4. Opis ma obejmować wszystkie kluczowe zmiany (np. logikę, endpointy, modele, testy), nie tylko README.
5. Zwróć **tylko** treść commita, bez dodatkowego komentarza.