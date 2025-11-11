import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Register a new user with email & password
  Future<User?> registerWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration failed';
    } catch (e) {
      throw 'Registration failed';
    }
  }

  // Sign in existing user with email & password
  Future<User?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Sign-in failed';
    } catch (e) {
      throw 'Sign-in failed';
    }
  }

  // Sign out current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

}