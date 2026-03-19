# Label Wise

Label Wise is a Flutter app for personalized food label analysis.

It helps users scan a product barcode or capture a food package photo, extract food information, compare it against saved dietary preferences, and reopen past results from local history.

Created by Suresh Lama at Novia UAS.

## What It Does

- Scan packaged food products by barcode
- Fall back to photo-based analysis when barcode data is missing
- Evaluate products against saved preferences such as:
  - religion
  - ethical choices
  - allergies
  - medical conditions
  - lifestyle goals
- Show a detailed result screen with:
  - ingredients
  - additives
  - allergens
  - nutrition
  - overall status
  - confidence
  - suggestions or alternatives
- Save results locally in Hive for:
  - recent history
  - reopening past results without recomputation
  - local insights/analytics

## Main Flow

1. Open the app
2. Complete onboarding and preference setup if needed
3. Scan a barcode
4. If the barcode exists in OpenFoodFacts:
   - the app fetches product data
   - extracts food information
   - runs the preference evaluation pipeline
   - opens the result page
5. If the barcode is not found:
   - the app offers photo capture
   - validates the image
   - extracts structured food data from the image
   - runs the same evaluation pipeline
   - opens the result page
6. Results are saved locally and shown again in Home history and Insights

## Current Features

- Branded splash screen
- Native Android/iOS launcher icons
- Native Android/iOS splash setup
- Barcode scanning with `mobile_scanner`
- Camera capture with `camera`
- OpenFoodFacts product lookup
- Photo validation and extraction flow
- Shared food analysis processor
- Result history saved locally in Hive
- Home insights + recent history
- Swipe to delete history item
- Clear all history
- Dedicated insights screen

## Project Structure

The app is organized around the active product flow:

```text
lib/
  ai/
    keys.dart
    services.dart
  dasboard/
    dashboard.dart
    home.dart
    insights_page.dart
    process_page.dart
    product_photo_page.dart
    profile.dart
    result_page.dart
    scan.dart
    models/
    services/
    widgets/
  diet_pref/
  state/
  splash_screen.dart
  main.dart
```

Key areas:

- `lib/dasboard/scan.dart`
  - live barcode scanner
- `lib/dasboard/process_page.dart`
  - branded loading and processing handoff
- `lib/dasboard/product_photo_page.dart`
  - camera fallback flow
- `lib/dasboard/result_page.dart`
  - final product result UI + local history snapshot save
- `lib/dasboard/services/food_analysis_processor.dart`
  - shared evaluation processor used by both barcode and photo flows
- `lib/dasboard/services/scan_history_service.dart`
  - Hive-backed local scan history

## Tech Stack

- Flutter
- Dart
- Hive CE
- Provider
- Mobile Scanner
- Camera
- OpenFoodFacts API
- OpenAI API for model-powered parts of the flow

## Requirements

- Flutter SDK compatible with the project Dart constraint in `pubspec.yaml`
- Dart SDK `^3.9.2`
- Android Studio / Xcode for mobile builds
- An OpenAI API key for AI-powered features

## Setup

1. Clone the repository

```bash
git clone <your-repo-url>
cd label_wise
```

2. Install dependencies

```bash
flutter pub get
```

3. Provide the OpenAI API key at runtime

The app no longer stores the API key in source control.

Use `--dart-define`:

```bash
flutter run --dart-define=OPEN_AI_KEY=your_key_here
```

## Run The App

### Run on web

```bash
flutter run -d chrome --dart-define=OPEN_AI_KEY=your_key_here
```

### Run on Android

```bash
flutter run -d android --dart-define=OPEN_AI_KEY=your_key_here
```

### Run on iOS

```bash
flutter run -d ios --dart-define=OPEN_AI_KEY=your_key_here
```

## Build Commands

### Android APK

```bash
flutter build apk --release --dart-define=OPEN_AI_KEY=your_key_here
```

### Android App Bundle

```bash
flutter build appbundle --release --dart-define=OPEN_AI_KEY=your_key_here
```

### iOS

```bash
flutter build ios --release --dart-define=OPEN_AI_KEY=your_key_here
```

## Native Assets

### Generate launcher icons

```bash
flutter pub run flutter_launcher_icons
```

### Generate native splash

```bash
dart run flutter_native_splash:create
```

## Notes About Secrets

- Do not commit real API keys
- This project expects the OpenAI key from:
  - `--dart-define=OPEN_AI_KEY=...`
- If a key was ever committed, revoke/rotate it before pushing

## Local Data

The app currently stores user-facing history locally using Hive:

- installation id
- onboarding state
- preference setup state
- scan result snapshots
- saved insights data derived from scan history

## Known Development Notes

- The active scan flow uses `ScanPage`, not legacy scanner screens
- Barcode and photo analysis now share the same downstream processor
- Reopened history results are loaded from local snapshot data instead of recomputing
- If your local Flutter/Dart SDK is older than the project requirement, `flutter analyze` and dependency resolution may fail until you upgrade Flutter

## Suggested First Run Checklist

1. Run `flutter pub get`
2. Run the app with `--dart-define=OPEN_AI_KEY=...`
3. Complete onboarding
4. Set preferences
5. Scan a product barcode
6. Check that result history appears on Home
7. Test photo fallback with a missing barcode

## Future Direction

This repository is evolving toward:

- stronger photo extraction
- richer result explainability
- server-backed device/install analytics
- improved packaged-food insights and trend reporting

## License

This project currently does not define a public license file.
