import 'package:firebase_auth/firebase_auth.dart';

class AuthRepo {
  AuthRepo(this.firebaseAuth);
  final FirebaseAuth firebaseAuth;

  Stream<User?> get userStream => firebaseAuth.authStateChanges();

  Future<String?> getCurrentUserId() async {
    return firebaseAuth.currentUser?.uid;
  }

  Future<void> signUp(String email, String password) async {
    await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }
}