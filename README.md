# Sathi

Sathi is a Flutter app built for Nepalese students abroad. It combines voice reflection, photo sharing, weekly wellbeing check-ins, a private social feed, and an Android home-screen widget into one supportive experience.

## Project overview

Sathi is designed around three core ideas:

- help users reflect through **voice journals** and **weekly check-ins**
- help trusted friends and family understand how someone is doing through a **private feed**
- surface that wellbeing snapshot in a **phone widget** for quick awareness

The project currently supports:

- Flutter mobile app
- optional Firebase-backed sharing and connections
- Python backend for transcription + mood analysis
- Android home-screen widget support

## Main features

- **Combined posts**: users can share a photo, a voice message, or both in one post
- **Voice journals**: record audio, transcribe it, and generate supportive feedback
- **Weekly check-ins**: structured mental-health check-ins with trend analysis
- **Insights tab**: combines weekly check-in data and recent voice signals into a wellbeing score
- **Private circle feed**: trusted connections can see photos, voice posts, and weekly wellbeing updates
- **Android widget**: shows a quick wellbeing snapshot using photo + keywords + suggestion

## Team members and roles

## The Team behind Sathi

- **🧑‍💻 Precious Nyaupane** — Team Lead & Flutter Engineering
- **🧑‍💻 Shavya Shrestha** — UX & UI Design
- **🧑‍💻 Laxman Puri** — AI Integration (Gemini)
- **🧑‍💻 Aarjan Khatiwada** — Backend & Data

## Tech stack

### Frontend
- Flutter
- Dart

### Backend / services
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Python transcription backend
- Whisper
- Gemini API

### Key Flutter packages
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `image_picker`
- `record`
- `audioplayers`
- `share_plus`
- `http`
- `home_widget`
- `path_provider`
- `intl`

## Project modes

Sathi currently supports two app modes.

### 1. Demo mode

Use this when you only want to explore the UI locally.

```bash
flutter run
```

Demo mode limitations:

- uses local in-memory data only
- app restarts clear local history
- real device-to-device connections do not work
- feed data may use demo fallback behavior

### 2. Firebase mode

Use this when you want real:

- anonymous auth
- user connections
- feed sharing
- Storage uploads
- deletion across shared feeds

```bash
flutter run --dart-define=USE_FIREBASE=true
```

Important:

- if Firebase initialization fails, the app currently falls back to demo mode
- the Home screen shows a demo-mode warning when that happens

## Prerequisites

- Flutter SDK
- Dart SDK (bundled with Flutter)
- Android Studio / Android SDK for Android development
- Xcode for iOS and macOS development
- Firebase CLI for Firebase-backed mode
- Python 3 for the transcription backend

Check your Flutter environment:

```bash
flutter doctor
```

Install Flutter dependencies:

```bash
flutter pub get
```

## Firebase setup

This repository already contains the Firebase-side source files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `firestore.rules`
- `storage.rules`
- `firebase.json`

You still need to configure Firebase in the console.

### Required console setup

Enable these Firebase services:

- **Authentication** with **Anonymous** sign-in
- **Cloud Firestore**
- **Firebase Storage**

### Firebase CLI setup

```bash
firebase login
firebase use sathi-cd772
```

### Deploy rules

```bash
firebase deploy --only firestore,storage
```

This is required for:

- connections
- feed sharing
- voice journal uploads
- combined post uploads
- shared post deletion
- weekly wellbeing update sharing

## Python transcription backend setup

The backend lives in the `transcribe/` directory.

### What it does

- accepts an uploaded voice file
- transcribes it with Whisper
- analyzes the text with Gemini
- returns a Flutter-ready payload:
  - transcription
  - mood
  - energy
  - summary
  - suggestion
  - safety
  - share card fields

### Backend setup

From the `transcribe/` directory:

```bash
python main.py
```

Before running it, make sure you have:

- Whisper dependencies installed
- `ffmpeg` available in PATH
- a valid `GOOGLE_API_KEY` in the backend environment

### Notes

- restart the backend after changing the Gemini prompt or API key
- backend output is now the preferred source for voice feedback text

## Recommended local run commands

### Phone / backend / Firebase

Use the helper script:

```bash
./scripts/run_flutter_with_backend.sh R5CX12XNA3B
```

### Emulator / backend / Firebase

```bash
./scripts/run_flutter_with_backend.sh emulator-5554
```

### Manual command

```bash
flutter run \
  --dart-define=USE_FIREBASE=true \
  --dart-define=USE_TRANSCRIBE_BACKEND=true \
  --dart-define=TRANSCRIBE_API_BASE_URL=http://100.70.122.12:8000
```

## Android widget support

Sathi currently includes an **Android home-screen widget**.

### What it shows

- username
- photo snapshot
- mood keywords
- support suggestion

### Notes

- remove and re-add the widget after major widget layout changes
- the widget uses a Flutter-side snapshot pipeline and native Android `AppWidgetProvider`
- the widget is more reliable after the app has been opened once and data has synced

### iPhone widget status

iPhone widget support is **not fully implemented yet**.

The Flutter-side widget snapshot pipeline exists, but a real WidgetKit extension target still needs to be added in Xcode.

## Current architecture

- `lib/main.dart` — app bootstrap and Firebase initialization
- `lib/src/app/` — app shell and route setup
- `lib/src/screens/` — feature screens
- `lib/src/state/app_state.dart` — central app state and orchestration
- `lib/src/services/` — Firebase, demo repository, recorder, backend integration, widget snapshot service
- `lib/src/models/` — feed, widget, check-in, voice, and post models
- `lib/src/widgets/` — reusable UI widgets
- `transcribe/` — Python backend for transcription and Gemini-based analysis

## Important behavior notes

- combined post flow now exists in addition to some older separate photo/voice flows
- Home feed can show:
  - combined posts
  - voice journals
  - photos
  - weekly wellbeing updates
- Insights now include recent voice journal signal in the combined mental-health score
- widget data is derived from shared feed content, not pulled directly from Firebase inside the widget

## Common issues

### App opens with the same identity on multiple devices

This usually means the app is running in **demo mode**, not real Firebase mode.

### Combined post upload fails with Storage unauthorized

Deploy the latest Storage rules:

```bash
firebase deploy --only storage
```

### Shared deletion fails

Deploy the latest Firestore rules:

```bash
firebase deploy --only firestore
```

### Widget does not update correctly

- open the app once first
- let feed data sync
- remove and re-add the widget after layout changes

### Widget crashes on emulator

This was previously caused by oversized widget bitmaps.
The project now downsamples widget images, but if you still see issues, rebuild and re-add the widget.

## Permissions

The app uses:

- microphone access
- photo/media access
- optional camera access depending on flow

If permissions behave unexpectedly, verify:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## Contributor notes

- use demo mode for fast UI iteration
- use Firebase mode for any real sharing/connection/widget testing
- use the Python backend when testing voice transcription and mood analysis
- manual testing is still important because automated coverage is limited

## Troubleshooting quick reset

```bash
flutter clean
flutter pub get
flutter run
```

For Android cache issues:

```bash
flutter clean
rm -rf build .dart_tool android/.gradle
flutter pub get
flutter run
```
