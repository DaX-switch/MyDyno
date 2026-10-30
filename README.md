# My Dyno v0.1

## Budowanie APK
1. `cd my_dyno && flutter create --platforms=android --org pl.dax --project-name my_dyno .`
   (generuje folder `android/`, nie nadpisuje `lib/` ani `pubspec.yaml`)
2. `flutter pub get`
3. W `android/app/build.gradle` ustaw `minSdkVersion 24` (jeśli build zgłosi wymagany minSdk dla SQLCipher).
4. W `android/app/src/main/AndroidManifest.xml` dodaj przed `<application>`:
   ```xml
   <queries>
     <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
   </queries>
   ```
5. Logo: podmień `assets/images/logo.png` na własne.
6. `flutter build apk --release`

## Do uzupełnienia
- `lib/constants.dart` → `kCoffeeUrl` (link Buy Me a Coffee), `kGeminiModel` (nazwa modelu Gemini).

## Uwagi
- Hasło SQLCipher jest w kodzie (`kDbPassword`) – chroni plik przed zwykłym podglądem, nie przed kimś, kto rozpakuje APK.
- Backup ZIP zawiera zaszyfrowany `mydyno.db` + `photos/`. Paczka `.mydyno` zawiera `vehicle.json` + zdjęcia.
- Merge: nowe UUID, model z dopiskiem „[Import]”, jedna transakcja, kopia pre-merge w `Dokumenty/backups/`.
