# Sathi

Sathi is a Flutter app for Nepalese students abroad. It combines voice journals, photo memories, weekly check-ins, and a private circle feed in a lightweight, supportive experience.

## Overview

Sathi supports two development modes:

- **Demo mode** for local UI and feature work without Firebase
- **Firebase mode** for anonymous auth, real sharing, and Storage-backed uploads

The project is intentionally MVP-sized. Some wellbeing summary behavior is local placeholder logic, not a production AI backend.

## Features

- Voice journal recording and transcript-based emotional summaries
- Photo memory uploads with captions
- Weekly check-ins with trend summaries and insight charts
- Private circle connections using Sathi codes
- Shared updates feed for photos and voice journals
- Manual sharing of summary cards

## Prerequisites

- Flutter SDK
- Dart SDK, included with Flutter
- Android Studio and Android SDK for Android development
- Xcode for iOS and macOS development
- Firebase CLI, only required for Firebase mode

Verify your environment:

```bash
flutter doctor
```

Install dependencies:

```bash
flutter pub get
```

## Quickstart

### Demo mode (recommended first run)

Demo mode does not require Firebase.

```bash
flutter run
```

What works in demo mode:

- navigation
- photo upload flow
- voice journal flow
- weekly check-in flow
- insights screen
- mock sharing behavior

Demo mode limitations:

- data is stored in memory only
- restarting the app clears demo history
- multi-user sharing is not real in this mode

If you only want to open the project and verify the app UI, use demo mode first.

### Firebase mode

Use Firebase mode when you need:

- anonymous authentication
- Firestore-backed user connections
- shared feed updates between users
- Firebase Storage uploads for photos and voice journals

Run:

```bash
flutter run --dart-define=USE_FIREBASE=true
```

Important:

- the app falls back to demo mode if Firebase initialization fails in `lib/main.dart`
- the app may still open even if Firebase is misconfigured
- real sharing will not behave correctly until Firebase is enabled in the console and rules are deployed

## Firebase setup

This repository already includes the source-side Firebase files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `firestore.rules`
- `storage.rules`
- `firebase.json`

In practice, most setup issues come from the Firebase console rather than missing local files.

### 1. Log in to Firebase CLI

```bash
firebase login
```

### 2. Select the Firebase project

```bash
firebase use sathi-cd772
```

If you are using a different Firebase project, replace the project ID above.

### 3. Enable required Firebase products

In Firebase Console, enable:

- **Authentication** with **Anonymous** sign-in
- **Cloud Firestore**
- **Firebase Storage**

### 4. Deploy rules

```bash
firebase deploy --only firestore,storage
```

This is required for:

- shared feed reads and writes
- voice journal uploads
- photo uploads
- deleting shared posts

## Common Firebase gotchas

### App opens, but sharing does not work

Usually one of these is missing:

- Anonymous Auth is not enabled
- Firestore is not enabled
- Storage is not enabled
- Firestore and Storage rules were not deployed
- the app was not started with `--dart-define=USE_FIREBASE=true`

### App Check warnings appear in logs

You may see warnings like:

```text
No AppCheckProvider installed
using placeholder token instead
```

This project does not currently configure Firebase App Check. For local development, these warnings are usually non-blocking.

### Voice journal uploads fail

Redeploy Storage rules:

```bash
firebase deploy --only storage
```

### Shared post deletion fails

Redeploy Firestore rules:

```bash
firebase deploy --only firestore
```

### Creator cannot see their own shared posts in Home

This also depends on the latest Firestore rules being deployed.

## Running on specific platforms

### Android

```bash
flutter run -d android
```

### iOS

```bash
flutter run -d ios
```

### macOS

```bash
flutter run -d macos
```

### List available devices

```bash
flutter devices
```

## Permissions

The app uses:

- microphone access
- photo library access
- optional camera/media access depending on platform flow

If permissions behave unexpectedly, verify the native project files.

### iOS

Check `ios/Runner/Info.plist` for:

- `NSMicrophoneUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSCameraUsageDescription`

### Android

Check `android/app/src/main/AndroidManifest.xml` for:

- `android.permission.RECORD_AUDIO`
- `android.permission.READ_MEDIA_IMAGES`
- `android.permission.CAMERA`

## Main packages used

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `image_picker`
- `record`
- `audioplayers`
- `share_plus`
- `intl`

## Contributor workflow

### UI or local feature work

```bash
flutter pub get
flutter run
```

### Firebase-connected work

```bash
firebase login
firebase use sathi-cd772
firebase deploy --only firestore,storage
flutter run --dart-define=USE_FIREBASE=true
```

### Notes for contributors

- demo mode is the safest way to verify the app starts cleanly
- Firebase mode should be tested whenever you touch sharing, connections, uploads, or deletion flows
- there is no meaningful automated test coverage in the repo yet, so manual verification is still important

## Architecture overview

- `lib/main.dart` — app bootstrap and optional Firebase initialization
- `lib/src/app/` — app shell and routes
- `lib/src/screens/` — feature screens
- `lib/src/state/app_state.dart` — central state management
- `lib/src/services/` — demo, Firebase, auth, recording, and analysis services
- `lib/src/models/` — data models
- `lib/src/widgets/` — reusable UI components
- `firestore.rules` and `storage.rules` — Firebase security rules
- `firebase.json` — Firebase project configuration

## Project notes

- voice and wellbeing analysis currently uses local placeholder logic
- `USE_FIREBASE=true` enables backend connectivity, not a real AI backend
- OpenAI is not required for local development
- weekly insights are generated from local app logic, not an external model

## Troubleshooting

### Clean and rebuild

```bash
flutter clean
flutter pub get
flutter run
```

### If Android build caches get corrupted

```bash
flutter clean
rm -rf build .dart_tool android/.gradle
flutter pub get
flutter run
```

### If Firebase mode is flaky

Confirm the app works in demo mode first:

```bash
flutter run
```

Then switch back to:

```bash
flutter run --dart-define=USE_FIREBASE=true
```

## Future hardening

- add Firebase App Check
- move AI calls to a backend or Cloud Function
- persist more non-Firebase local state if demo mode should survive restarts
- add automated tests for sharing and deletion flows
