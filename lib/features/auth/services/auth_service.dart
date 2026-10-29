import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Реєстрація
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e);
    }
  }

  // Вхід
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e);
    }
  }

  // Вихід
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _parseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'email-already-in-use':
        return 'A user with this email already exists.';
      case 'weak-password':
        return 'The password is too weak (minimum 6 characters).';
      case 'invalid-email':
        return 'Invalid email format.';
      default:
        return e.message ?? 'Authentication error. Please try again later.';
    }
  }
}