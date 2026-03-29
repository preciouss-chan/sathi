import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  Future<void> signInAnonymously() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;
}
