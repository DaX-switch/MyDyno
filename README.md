# My Dyno v0.12
Prosta aplikacja do obsługi pojazdów pod kątem chip tuningu. 
Twoja lokalna baza danych 

Relase Note:
My Dyno v0.12.0
Kluczowe zmiany (Highlights)
Trwałe usuwanie pojazdów: Rozwiązano problem automatycznego przywracania usuniętego auta do bazy SQLite po zamknięciu ekranu.

Wysoka rozdzielczość wykresów hamowni: Zakładki pomiarowe (MOC, Dyno, Power, Hamownia) zapisują wykresy w podwyższonej rozdzielczości, zapewniając pełną czytelność parametrów KM, Nm i wykresów obrotów.

Aktualizacja wersji aplikacji: Podniesiono wersję bazową i numerację kompilacji do 0.12.0+12.

Zmiany w plikach
lib/screens/tabs_screen.dart:

Dodano flagę _deleted = true, aktywowaną natychmiast po potwierdzeniu usunięcia pojazdu.

Zabezpieczono procedurę _save() przed wykonywaniem autozapisu w momencie zamykania widoku przez PopScope (if (_deleted) return;).

Uporządkowano domknięcia klamer w metodzie _load().

lib/services/photo_service.dart:

Przebudowano proces kompresji na model z izolatem (_CompressParams oraz _compressJob).

Wdrożono dynamiczny profil jakości: dla zakładek hamowni limit rozdzielczości podniesiono do 2560 px, a jakość JPG do 92% (pozostałe zdjęcia: 1280 px i 75%).

Wyczyszczono zbędne importy (dart:typed_data).

lib/widgets/photo_box.dart:

Przekazano parametr bieżącej zakładki (tab: widget.tab) do PhotoService.saveCompressed().

pubspec.yaml:

Podbito wersję do 0.12.0+12.

My Dyno v0.11.0
Kluczowe zmiany (Highlights)
Integracja z AI (Gemini BYOK): Wprowadzono obsługę własnego klucza API Gemini w trybie Bring-Your-Own-Key do analizy danych i generowania podsumowań.

Rozszerzenie konfiguracji warsztatu: Dodano opcje personalizacji widoków i trybów pracy pod specyfikę warsztatu tuningowego.

Zarządzanie bazą danych i kopiami: Rozbudowano narzędzia do pełnego eksportu, przywracania oraz inteligentnego scalania baz danych.

Zmiany w modułach
lib/screens/settings_screen.dart:

Dodano sekcję konfiguracji modułów: włączanie/wyłączanie zakładki Hamownia, uwzględnianie sekcji Hamownia Drogowa oraz przełącznik Tryb Slave (podgląd kosztu zakupu pliku / obsługi Mastera).

Zaimplementowano pole wprowadzania i bezpiecznego zapisu klucza API Gemini z możliwością podglądu hasła oraz bezpośrednim linkiem do Google AI Studio.

Zintegrowano obsługę tworzenia i wczytywania kopii zapasowej (pełny backup ZIP, zastępowanie bazy z automatyczną kopią ratunkową oraz scalanie baz z plików .zip / .mydyno).

Dodano sekcję informacyjną o projekcie, linki do profilu społecznościowego oraz wsparcia projektu.

lib/services/backup_service.dart:

Dodano procedury pakowania bazy SQLite oraz powiązanego katalogu zdjęć do jednolitego archiwum .zip.

Wdrożono mechanizm merge importujący nowe pojazdy z oznaczeniem [Import] bez nadpisywania istniejących rekordów.

lib/services/gemini_service.dart:

Utworzono serwis komunikacji z modelem językowym przechowujący klucz lokalnie na urządzeniu.

My Dyno v0.1.0
Kluczowe zmiany (Highlights)
Wydanie początkowe (Initial Prototype): Pierwsza funkcjonalna wersja aplikacji do ewidencji prac warsztatowych i modyfikacji pojazdów.

Lokalna baza danych (Offline-first): Pełna obsługa zapisu danych pojazdów, historii cen i parametrów modyfikacji w lokalnej bazie SQLite.

Dokumentacja fotograficzna: Wbudowany moduł przypisywania zdjęć do poszczególnych zakładek pojazdu z automatyczną kompresją i ochroną przed indeksowaniem w galerii systemowej.

Funkcjonalności bazowe
Ewidencja pojazdów (lib/db/repo.dart, lib/models/vehicle.dart):

Tworzenie kart pojazdów z podziałem na dedykowane sekcje robocze.

Śledzenie historii zmian cenowych dla poszczególnych usług.

Zarządzanie zdjęciami (lib/services/photo_service.dart, lib/widgets/photo_box.dart):

Obsługa robienia zdjęć aparatem lub wyboru z galerii systemowej (ImagePicker).

Podgląd zdjęć w oknie dialogowym z obsługą zoomu gestem (InteractiveViewer).

Zapis plików w dedykowanym katalogu aplikacji z plikiem .nomedia, uniemożliwiającym zaśmiecanie galerii telefonu.

Architektura interfejsu (lib/screens/home_screen.dart, lib/screens/tabs_screen.dart):

Ekran główny z listą obsługiwanych pojazdów i wyszukiwarką.

Edytor szczegółów pojazdu z podziałem na zakładki i automatycznym zapisem stanu (_save()).