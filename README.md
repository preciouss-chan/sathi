# Sathi

Sathi is a polished Flutter MVP for Nepalese students abroad — a tiny homesick companion focused on voice journaling, photo memories, weekly check-ins, and gentle emotional summaries.

## What is included

- Home
- Record Voice
- Upload Photo
- Weekly Check-in
- Insights / Trends
- Share Summary
- Warm in-app widget-style preview card
- Mock/demo-safe fallbacks so the app still works without Firebase/OpenAI keys

## Current project status

This repository contains the full Flutter app source (`lib/`) and `pubspec.yaml`.

Because Flutter is not installed in this environment, native platform folders were not generated automatically. To finish local setup on your machine:

```bash
flutter create .
flutter pub get
flutter run
```

If you want Android/iOS folders generated immediately, run:

```bash
flutter create --platforms=android,ios .
```

## Packages used

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `image_picker`
- `record`
- `path_provider`
- `share_plus`
- `intl`

## Demo-safe behavior

By default, the app runs in local mock mode.

- No Firebase setup required for first demo
- No OpenAI API key required for first demo
- Voice analysis and summaries are generated locally with placeholder logic
- Photos and check-ins are stored in memory for the running session

## Enabling Firebase

1. Add Firebase to your Flutter app.
2. Generate `firebase_options.dart` with FlutterFire CLI if desired.
3. Pass the flag below when running:

```bash
flutter run --dart-define=USE_FIREBASE=true
```

4. Replace the placeholder initialization comment in `lib/main.dart` with your generated Firebase options if you use them.

## Enabling OpenAI

The MVP includes a stubbed service in `lib/src/services/openai_wellbeing_service.dart`.

To connect a real backend later:

1. Add a secure backend or Cloud Function.
2. Do **not** ship your OpenAI key directly in a production mobile app.
3. Optionally test locally with:

```bash
flutter run --dart-define=USE_OPENAI=true --dart-define=OPENAI_API_KEY=your_key_here
```

At the moment, these flags are documented for future integration and do not enable a real API call yet. The current MVP still uses local placeholder analysis so the demo remains stable.

Recommended production flow:

- upload audio to Firebase Storage
- send the storage URL or transcript to a Cloud Function
- call OpenAI from the server
- store structured JSON in Firestore

## Product language guardrails

This MVP intentionally avoids diagnosis language.

Use:

- wellbeing pulse
- mood trend
- emotional summary

Avoid:

- diagnosis
- score
- mental health score

## Native permissions you still need to add

After running `flutter create .`, add permission descriptions for the media features.

### iOS: `ios/Runner/Info.plist`

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Sathi uses the microphone for voice journals.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Sathi lets you choose comforting photos to save in your memory feed.</string>
<key>NSCameraUsageDescription</key>
<string>Sathi can use the camera if you later enable direct photo capture.</string>
```

### Android: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.CAMERA" />
```

## Suggested next steps after the hackathon

- Replace mock repositories with Firestore-backed repositories
- Add Firebase anonymous auth or email auth
- Add Whisper/GPT-based Nepali transcription and summary generation via Cloud Functions
- Add real homescreen widgets for Android/iOS
- Add push reminders for weekly check-ins
