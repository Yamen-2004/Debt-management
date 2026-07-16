import 'package:firebase_auth/firebase_auth.dart';

/// Handles all communication with Firebase Authentication.
/// No other class should talk to FirebaseAuth directly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool isLoggedIn() => _auth.currentUser != null;

  Future<User?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return credential.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
