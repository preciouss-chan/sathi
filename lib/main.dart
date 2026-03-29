import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'src/app/sathi_app.dart';
import 'src/services/auth_service.dart';
import 'src/services/connectivity_service.dart';
import 'src/services/demo_repository.dart';
import 'src/state/app_state.dart';

const bool kUseFirebase =
    bool.fromEnvironment('USE_FIREBASE', defaultValue: false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;

  if (kUseFirebase) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AuthService().signInAnonymously();
      firebaseReady = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed. Falling back to demo mode.');
      debugPrint('$error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(
    SathiApp(
      appState: AppState(
        repository: DemoRepository(),
        connectivityService: ConnectivityService(useFirebase: firebaseReady),
      ),
    ),
  );
}
