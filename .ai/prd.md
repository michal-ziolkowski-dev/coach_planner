# Dokument wymagań produktu (PRD) - Coach Planner

## 1. Przegląd produktu
1. Cel biznesowy: dostarczyć trenerom i osobom trenującym prosty kanał rezerwacji indywidualnych sesji treningowych, eliminując wymianę wiadomości i konflikty terminów.
2. Docelowi użytkownicy: trenerzy prowadzący indywidualne lub małoosobowe treningi oraz osoby trenujące, które chcą samodzielnie rezerwować i zarządzać terminami.
3. Zakres MVP: webowa aplikacja umożliwiająca rejestrację kont (rola trener lub użytkownik), zarządzanie tygodniowym kalendarzem dostępności przez trenerów, rezerwacje i anulacje slotów przez użytkowników oraz przeglądanie nadchodzących treningów.
4. Modele operacyjne: samodzielna rejestracja bez weryfikacji trenerów, czasy prezentowane w strefie czasowej serwera, brak automatycznych powiadomień.
5. Główne założenia: domyślna długość slotu 60 minut, trener definiuje pojemność slotu (domyślnie 1 osoba), nakładanie się slotów jest dopuszczone, rezerwacje są pojedyncze (bez serii), brak płatności w aplikacji.
6. Zależności techniczne: moduł uwierzytelniania z obsługą rejestracji i zmiany hasła, moduł kalendarza tygodniowego 24h/dobę dla obu ról, mechanizm automatycznej zmiany statusu rezerwacji po upływie czasu, dedykowana tabela logów zmian kalendarza.

## 2. Problem użytkownika
1. Trenerzy aktualnie korzystają z improwizowanych metod (arkusze, komunikatory), co utrudnia zarządzanie dostępnością, śledzenie anulacji i historii zmian.
2. Osoby trenujące mają ograniczoną widoczność dostępnych terminów, co wymaga wielokrotnej komunikacji, wydłuża proces rezerwacji i zwiększa ryzyko podwójnych rezerwacji.
3. Brak centralnego systemu utrudnia śledzenie obłożenia treningów i podejmowanie decyzji na podstawie danych (np. największe obłożenie), a manualne odnotowywanie zmian zwiększa ryzyko błędów.

## 3. Wymagania funkcjonalne

### 3.1 Konta i uwierzytelnianie
1. System umożliwia samodzielną rejestrację konta z podaniem imienia, nazwiska, adresu e-mail i wyborem roli (trener lub użytkownik).
2. Unikalność adresu e-mail jest wymagana; brak dodatkowych pól czy walidacji kwalifikacji trenerskich w MVP.
4. Użytkownik może zmienić hasło w profilu po podaniu aktualnego hasła i nowego spełniającego minimalne wymagania bezpieczeństwa (do zdefiniowania przez zespół techniczny).
5. Użytkownik może wylogować się ręcznie; sesja wygasa po zdefiniowanym czasie bezczynności.
6. Użytkownik może usunąć konto; aktywne rezerwacje otrzymują etykietę anonimowy użytkownik oraz stają się ponownie dostępne do rezerwacji.

### 3.2 Widok trenerów i kalendarza
1. System prezentuje listę wszystkich trenerów w porządku alfabetycznym po nazwisku (lub imieniu, jeśli brak nazwiska).
2. Każdy profil trenera zawiera podstawowe dane (imię, nazwisko, e-mail kontaktowy) oraz link do tygodniowego kalendarza dostępności.
3. Kalendarz ma zakres tygodniowy (poniedziałek–niedziela), widok 24-godzinny i pozwala przełączać tygodnie do przodu i do tyłu.
4. W widoku kalendarza użytkownik widzi status każdego slotu (dostępny, pełny, odbyty, anulowany) oraz liczbę dostępnych miejsc przy pojemności większej niż 1.

### 3.3 Zarządzanie slotami przez trenera
1. Trener może tworzyć sloty dostępności, wskazując datę, godzinę rozpoczęcia, domyślną długość 60 minut (konfigurowalną w przyszłości) oraz pojemność (domyślnie 1, maksymalna wartość do zdefiniowania technicznie).
2. Trener może edytować slot (czas, pojemność) tak długo, jak rezerwacja nie została oznaczona jako odbyta; zmiany są odnotowywane w logach.
3. Trener może usuwać sloty bez aktywnych rezerwacji; jeśli istnieją rezerwacje, system blokuje usunięcie i informuje o konieczności anulowania rezerwacji.
4. System dopuszcza nachodzenie slotów i nie wymusza rozwiązań konfliktów czasowych.
5. Wszystkie zmiany slotów są zapisywane w dedykowanej tabeli logów z informacją o rodzaju zmiany, osobie wykonującej i znaczniku czasu.

### 3.4 Rezerwacje użytkowników
1. Użytkownik może zarezerwować dostępny slot, o ile pojemność nie jest wykorzystana; system blokuje wielokrotne rezerwacje tego samego slotu przez jednego użytkownika.
2. Rezerwacja otrzymuje status utworzona i jest widoczna w kalendarzu trenera oraz na liście nadchodzących treningów użytkownika.
3. Użytkownik może anulować rezerwację najpóźniej 1 godzinę przed startem; system odmawia późniejszych anulacji, prezentując komunikat o przekroczeniu limitu.
4. Anulowana rezerwacja ponownie zwiększa liczbę dostępnych miejsc w slocie i odnotowuje zmianę w logach.
5. System automatycznie aktualizuje status rezerwacji na odbyta po upływie czasu końca slotu oraz zachowuje historię zmian statusu.
6. Po upływie czasu startu slotu bez anulacji, rezerwacja pozostaje w kalendarzu jako odbyta niezależnie od obecności uczestnika (brak logiki no-show).

### 3.5 Raportowanie i dane operacyjne
1. System przechowuje logi zmian kalendarza i rezerwacji w dedykowanej tabeli z polami: identyfikator rekordu, typ zmiany, status przed i po, inicjator (rola i identyfikator), znacznik czasu.
2. Czas i daty są wyświetlane w strefie czasowej serwera; UI informuje użytkownika o zastosowanej strefie.

## 4. Granice produktu
1. Poza zakresem: płatności, integracje z kalendarzami zewnętrznymi, powiadomienia e-mail/SMS/push, aplikacje mobilne, reset hasła przez e-mail, onboarding i wsparcie kontekstowe.
2. Brak limitów weryfikacyjnych trenerów w MVP; zaufanie oparte na samoopisaniu.
3. Brak obsługi rezerwacji cyklicznych lub seryjnych; każda rezerwacja dotyczy pojedynczego slotu.

## 5. Historyjki użytkowników

### US-001 Rejestracja konta
Opis: Jako nowy użytkownik chcę założyć konto, aby uzyskać dostęp do aplikacji jako trener lub osoba trenująca.
Kryteria akceptacji:
- Formularz wymaga imienia, nazwiska, adresu e-mail, hasła oraz wyboru roli (trener lub użytkownik).
- System waliduje unikalność adresu e-mail i informuje o kolizjach.
- Po poprawnej rejestracji użytkownik otrzymuje potwierdzenie i może przejść do logowania.
- Błędnie wypełnione pola wyświetlają komunikaty walidacyjne.

### US-002 Logowanie do aplikacji
Opis: Jako zarejestrowany użytkownik chcę zalogować się do aplikacji, aby uzyskać dostęp do funkcji zgodnie z moją rolą.
Kryteria akceptacji:
- Formularz logowania przyjmuje adres e-mail i hasło.
- Poprawne dane uwierzytelniają użytkownika i przekierowują do widoku odpowiedniego dla roli.
- Błędne dane zwracają komunikat o nieprawidłowych poświadczeniach bez ujawniania szczegółów.
- Sesja wygasa po zdefiniowanym czasie bezczynności, wymuszając ponowne logowanie.

### US-003 Wylogowanie z aplikacji
Opis: Jako zalogowany użytkownik chcę wylogować się, aby zakończyć sesję na danym urządzeniu.
Kryteria akceptacji:
- Użytkownik ma dostępny przycisk wyloguj w interfejsie.
- Po wylogowaniu sesja zostaje unieważniona, a użytkownik trafia na stronę logowania.
- Ponowna próba wejścia na chronione widoki bez logowania przenosi użytkownika do formularza logowania.

### US-004 Zmiana hasła
Opis: Jako zalogowany użytkownik chcę zmienić hasło, aby utrzymać bezpieczeństwo konta.
Kryteria akceptacji:
- Formularz wymaga obecnego hasła oraz nowego hasła spełniającego politykę bezpieczeństwa.
- Błędne obecne hasło blokuje zmianę i zwraca komunikat o błędzie.
- Po zmianie hasła istniejąca sesja pozostaje aktywna lub jest odświeżana zgodnie z polityką bezpieczeństwa (do decyzji technicznej) i użytkownik otrzymuje potwierdzenie.

### US-005 Usunięcie konta
Opis: Jako zalogowany użytkownik chcę usunąć konto, aby zakończyć korzystanie z aplikacji.
Kryteria akceptacji:
- Proces wymaga potwierdzenia (np. ponownego wpisania hasła).
- Po usunięciu konta użytkownik traci dostęp do aplikacji i zostaje wylogowany.
- Wszystkie przyszłe rezerwacje użytkownika są oznaczane jako dostępne w kalendarzu trenera z etykietą anonimowy użytkownik w historii.
- System zapisuje operację w logach zmian.

### US-006 Lista trenerów
Opis: Jako zalogowany użytkownik chcę przeglądać listę trenerów, aby wybrać osobę prowadzącą trening.
Kryteria akceptacji:
- Lista prezentuje trenerów alfabetycznie wraz z imieniem i nazwiskiem.
- Kliknięcie pozycji otwiera szczegóły trenera i jego kalendarz.
- Widok jest dostępny dla obu ról (trenerzy również widzą listę innych trenerów do celów porównawczych).

### US-007 Widok kalendarza trenera
Opis: Jako użytkownik lub trener chcę widzieć tygodniowy kalendarz trenera, aby sprawdzić dostępne sloty lub zarządzać dostępnością.
Kryteria akceptacji:
- Kalendarz prezentuje pełny tydzień z możliwością przełączania tygodni do przodu i do tyłu.
- Sloty oznaczone są kolorystycznie lub etykietami wg statusu (dostępny, pełny, anulowany, odbyty) oraz liczbą dostępnych miejsc.
- Czas slotów wyświetla się w strefie czasowej serwera z komunikatem w UI.
- Użytkownik bez odpowiednich uprawnień nie widzi opcji edycji slotu.

### US-008 Zarządzanie slotami trenera
Opis: Jako trener chcę tworzyć, edytować i usuwać sloty, aby zarządzać swoją dostępnością.
Kryteria akceptacji:
- Formularz tworzenia slotu wymaga daty, czasu rozpoczęcia i pojemności; domyślna długość slotu to 60 minut i może zostać nadpisana tylko przez zespół techniczny poza MVP.
- Trener może ustawić pojemność większą niż 1, a system wyświetla liczbę wolnych miejsc.
- Sloty mogą nakładać się czasowo bez blokad.
- Edycja slotu aktualizuje kalendarz natychmiast i zapisuje wpis w logu zmian.
- Usunięcie slotu jest możliwe tylko, jeśli nie ma powiązanych przyszłych rezerwacji; w przeciwnym razie system informuje o konieczności anulowania rezerwacji.

### US-009 Rezerwacja slotu
Opis: Jako użytkownik chcę zarezerwować dostępny slot, aby zapewnić sobie miejsce na treningu.
Kryteria akceptacji:
- Kliknięcie dostępnego slotu umożliwia natychmiastową rezerwację bez dodatkowej akceptacji trenera.
- System weryfikuje, czy pojemność nie została przekroczona i że użytkownik nie ma już rezerwacji  w tym slocie.
- Po sukcesie system potwierdza rezerwację i aktualizuje licznik wolnych miejsc.
- Nieudana rezerwacja (slot pełny, błąd systemowy) generuje zrozumiały komunikat.

### US-010 Anulowanie rezerwacji
Opis: Jako użytkownik chcę anulować swoją rezerwację, aby zwolnić miejsce w kalendarzu trenera.
Kryteria akceptacji:
- Anulacja jest możliwa najpóźniej 60 minut przed startem slotu; system blokuje późniejsze próby i wyświetla informację o przekroczeniu limitu.
- Po anulacji slot znów staje się dostępny z odpowiednio zwiększoną liczbą miejsc.
- Historia rezerwacji przechowuje informację o anulacji wraz ze znacznikiem czasu i inicjatorem.
- System zapisuje operację anulacji w logach.

### US-011 Nadchodzące treningi użytkownika
Opis: Jako użytkownik chcę widzieć listę moich nadchodzących treningów, aby zarządzać planem.
Kryteria akceptacji:
- Widok prezentuje wszystkie przyszłe rezerwacje w układzie chronologicznym z kluczowymi informacjami (trener, data, godzina, status).
- Rezerwacje w przeszłości są ukryte lub oznaczane jako odbyta i przenoszone do historii (poza widokiem nadchodzących).
- Z widoku można przejść do szczegółów slotu w kalendarzu.

### US-012 Automatyczna zmiana statusu rezerwacji
Opis: Jako właściciel produktu chcę, aby system automatycznie aktualizował status rezerwacji, aby zapewnić spójność danych.
Kryteria akceptacji:
- Po upływie czasu trwania slotu status rezerwacji zmienia się z utworzona na odbyta bez udziału użytkownika.
- Automatyczna zmiana jest zapisywana w logach wraz z oznaczeniem, że akcję wykonał system.
- Anulowane rezerwacje zachowują status anulowana i nie podlegają automatycznej zmianie.

### US-013 Logi zmian kalendarza
Opis: Jako administrator systemu chcę mieć dostęp do logów zmian, aby śledzić historię operacji na slotach i rezerwacjach.
Kryteria akceptacji:
- Każda zmiana (utworzenie, edycja, anulacja, automatyczna zmiana statusu) tworzy wpis w tabeli logów z identyfikatorem obiektu, rodzajem operacji, inicjatorem, poprzednim i nowym statusem oraz znacznikiem czasu.
- Logi dostępne są do przeglądania przez uprawnionych członków zespołu w narzędziach administracyjnych lub poprzez zapytania do bazy danych.
- Błędne próby zapisu logu są rejestrowane w mechanizmie monitoringu technicznego (do implementacji technicznej).

## 6. Metryki sukcesu
1. Liczba aktywnych rezerwacji w zadanym okresie (np. tygodniowo, miesięcznie).
2. Średni procent zapełnienia slotów na trenera w tygodniu.
3. Liczba aktywnych trenerów (posiadających co najmniej jeden slot z rezerwacją) vs. zarejestrowanych trenerów.

