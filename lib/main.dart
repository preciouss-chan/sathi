import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/app/sathi_app.dart';
import 'src/services/auth_service.dart';
import 'src/services/demo_repository.dart';
import 'src/state/app_state.dart';

const bool kUseFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kUseFirebase) {
    try {
      // TODO: Replace with Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      // after running FlutterFire CLI and adding firebase_options.dart.
      await Firebase.initializeApp();
      await AuthService().signInAnonymously();
    } catch (_) {
      // Fallback to demo mode silently so the hackathon demo still works.
    }
  }

  runApp(
    SathiApp(
      appState: AppState(repository: DemoRepository()),
    ),
  );
}
