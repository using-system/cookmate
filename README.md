# CookMate

Create your Thermomix recipes with the CookMate assistant.

CookMate is a Flutter mobile app (Android + iOS) — an AI chat assistant
that helps you discover and craft recipes for your Thermomix, powered by
an on-device Gemma model.

## Development prerequisites

Install the following on your macOS machine:

- [Flutter SDK](https://docs.flutter.dev/get-started/install/macos) (stable channel)
  ```bash
  brew install --cask flutter
  ```
- [Android Studio](https://developer.android.com/studio) (provides Android SDK + emulator)
  ```bash
  brew install --cask android-studio
  ```
- [Xcode](https://apps.apple.com/app/xcode/id497799835) from the App Store, then:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  sudo gem install cocoapods
  ```

Validate the setup:

```bash
flutter doctor
```

All checks must be green before running the app.

## Run in development

```bash
git clone https://github.com/using-system/cookmate.git
cd cookmate
flutter pub get
flutter run
```

Pick your target device when prompted (`flutter devices` lists what is available).

### Launch an emulator or simulator

**iOS simulator** (ships with Xcode):

```bash
open -a Simulator
```

**Android emulator** — list existing AVDs, or create one via Android Studio
(*Tools → Device Manager → Create Device*):

```bash
flutter emulators                       # list available emulators
flutter emulators --launch <emulator-id> # start one
```

Once the simulator or emulator is running, `flutter devices` shows its id and
`flutter run -d <device-id>` targets it explicitly.

## Install on a device (non-developer path)

CookMate is not yet published on the App Store or Google Play. Until a release is
available, the only way to install the app on a physical phone is to build it from
source:

- **iPhone:** connect the device over USB, trust the computer, then run
  `flutter run --release -d <your-iphone>`. You need a free Apple ID signed into
  Xcode to sign the build for personal use.
- **Android:** enable Developer Options and USB debugging on the phone, connect it,
  then run `flutter run --release -d <your-android>` or
  `flutter build apk --release` and sideload the resulting APK from
  `build/app/outputs/flutter-apk/app-release.apk`.

Store-based installation instructions will be added here once the app is published.
