# API Endpoint Implementation Plan: GET /trainers

## 1. Przegląd punktu końcowego
Publiczny endpoint zwracający listę trenerów dostępnych w systemie. Źródłem danych jest widok/materialized-view `trainer_directory`, który udostępnia wyłącznie aktywnych trenerów (`deleted_at IS NULL AND role = 'trainer'`). Endpoint obsługuje paginację, wyszukiwanie pełnotekstowe po nazwie oraz sortowanie.

## 2. Szczegóły żądania
- **Metoda HTTP:** `GET`
- **URL:** `/trainers`
- **Parametry zapytania:**
  | Parametr | Typ | Wymagany | Domyślna wartość | Walidacja | Opis |
  |----------|-----|----------|------------------|-----------|------|
  | `search` | `string` | Nie | – | `length <= 100` | Filtrowanie `display_name ILIKE '%search%'` |
  | `page` | `int` | Nie | `1` | `>= 1` | Numer strony (1-indeksowane) |
  | `page_size` | `int` | Nie | `20` | `1..100` | Liczba rekordów na stronę |
  | `sort` | `string` | Nie | `display_name:asc` | RegExp `^(display_name|updated_at):(asc|desc)$` | Kolumna i kierunek sortowania |

Brak `Request Body` – wszystkie dane przekazywane w query string.

## 3. Wykorzystywane typy
- `TrainerDirectoryEntryDto` – reprezentuje pojedynczy rekord trenera (już istnieje w `src/lib/types.dart`).
- `PaginatedResponse<TrainerDirectoryEntryDto>` – opakowanie danych paginowanych (istnieje).
- **Nowy service:** `TrainerDirectoryService` w `src/lib/services/api/` z metodą
  ```dart
  Future<PaginatedResponse<TrainerDirectoryEntryDto>> fetchPublicTrainers({
    String? search,
    int page = 1,
    int pageSize = 20,
    String sort = 'display_name:asc',
  });
  ```

## 4. Szczegóły odpowiedzi
- **Status 200** (application/json)
```json
{
  "data": [
    { /* TrainerDirectoryEntryDto */ }
  ],
  "page": 1,
  "pageSize": 20,
  "total": 120
}
```
- **Nagłówki:** `Cache-Control: max-age=60, public` (do rozważenia)

## 5. Przepływ danych
1. Kontroler/API-route odbiera zapytanie i mapuje parametry na model wejściowy.
2. Walidator weryfikuje parametry (RegExp, zakresy, długości).
3. `TrainerDirectoryService` buduje zapytanie Supabase:
   - `from('trainer_directory')`
   - `select()`
   - `ilike('display_name', '%search%')` jeśli `search` niepuste
   - `order(sortColumn, ascending)`
   - `range((page-1)*pageSize, page*pageSize-1)`
4. W odpowiedzi Supabase zwraca tablicę i nagłówek `content-range`, z którego wyciągamy `total`.
5. Konwersja listy map → `TrainerDirectoryEntryDto` (via `fromEntity`).
6. Złożenie `PaginatedResponse` i zwrot 200.

## 6. Względy bezpieczeństwa
- Endpoint jest publiczny (brak JWT wymagany), ale:
  - Włączone RLS: rola anon ma `SELECT` wyłącznie na widoku `trainer_directory`.
  - Supabase zapobiega SQL-injection; dodatkowo parametry sort są białolistowane.
  - Ochrona przed **DoS**: limit `page_size` do 100 oraz nagłówki rate-limit (CDN / API-Gateway).

## 7. Obsługa błędów
| Kod | Sytuacja | Struktura błędu |
|-----|----------|-----------------|
| 400 | Nieprawidłowe parametry (`page < 1`, `sort` spoza wzorca`) | `{ "error": "Invalid query parameter: ..." }` |
| 404 | Strona poza zakresem (`page` > max) | `{ "error": "Page not found" }` |
| 500 | Błąd po stronie serwera / Supabase | `{ "error": "Internal server error" }` |

Błędy logujemy w `activity_logs` (action = `error`, entity_type = `trainer_directory`, metadata = validation / supabase error).

## 8. Rozważania dotyczące wydajności
- **Indeksy** w bazie: `display_name` (btree, collate "pl_PL"), `updated_at` (btree) dla sort.
- Materialized view odświeżany triggerem na `users` – upewnić się, że REFRESH jest inkrementalny.
- CDN caching 60s dla rezultatów bez `search`.

## 9. Etapy wdrożenia
1. **DB**: Potwierdź indeksy na kolumnach sortujących, przetestuj RLS dla roli anon.
2. **Service**: Utwórz `TrainerDirectoryService` z metodą `fetchPublicTrainers`.
3. **Validator**: Dodaj klasę `TrainerQueryValidator` wykorzystując `zod` lub manualną walidację.
4. **Route/Controller**: Zarejestruj route `/trainers` w module API, wstrzyknij service.
6. **Logging & Monitoring**: obsłuż błędy w middleware, loguj do `activity_logs` oraz stack trace do APM.
