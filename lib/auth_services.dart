import 'package:firebase_auth/firebase_auth.dart'; // Keep this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Modified to return Future<UserCredential>
  Future<UserCredential> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential; // Return the UserCredential
    } on FirebaseAuthException catch (e) {
      // Re-throw specific Firebase Auth exceptions for better handling in UI
      throw e;
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception("An unknown error occurred during login: $e");
    }
  }

  // Modified to return Future<UserCredential>
  Future<UserCredential> signup(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential; // Return the UserCredential
    } on FirebaseAuthException catch (e) {
      // Re-throw specific Firebase Auth exceptions
      throw e;
    } catch (e) {
      // Catch any other unexpected errors
      throw Exception("An unknown error occurred during signup: $e");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // You might find this useful later to quickly get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
