import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthResult {
  final UserCredential? userCredential;
  final String? errorMessage;

  AuthResult({this.userCredential, this.errorMessage});
}

class GoogleSignInResult extends AuthResult {
  GoogleSignInResult({super.userCredential, super.errorMessage});
}

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        return GoogleSignInResult(errorMessage: 'Sign-in cancelled by user.');
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return GoogleSignInResult(userCredential: userCredential);
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return GoogleSignInResult(
        errorMessage: 'Sign-in failed. Please try again.',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }

  // Get user profile data
  Map<String, dynamic>? get userProfile {
    final user = currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'createdAt': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult(userCredential: userCredential);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          errorMessage =
              'Invalid email or password. Please check your credentials.';
          break;
        default:
          errorMessage = 'Sign in failed: ${e.message}';
      }
      return AuthResult(errorMessage: errorMessage);
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      return AuthResult(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // No email verification needed

      return AuthResult(userCredential: userCredential);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password should be at least 6 characters long.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Sign up failed: ${e.message}';
      }
      return AuthResult(errorMessage: errorMessage);
    } catch (e) {
      debugPrint('Error signing up with email: $e');
      return AuthResult(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Alias for signUpWithEmail to match AuthProvider expectation
  Future<AuthResult> createAccount(String email, String password) {
    return signUpWithEmail(email, password);
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(userCredential: null);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        default:
          errorMessage = 'Failed to send reset email: ${e.message}';
      }
      return AuthResult(errorMessage: errorMessage);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      return AuthResult(
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Delete current user account
  Future<AuthResult> deleteCurrentUser() async {
    try {
      final user = currentUser;
      if (user != null) {
        await user.delete();
        return AuthResult(userCredential: null);
      }
      return AuthResult(errorMessage: 'No user to delete');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'requires-recent-login':
          errorMessage = 'Please sign in again to delete your account.';
          break;
        default:
          errorMessage = 'Failed to delete account: ${e.message}';
      }
      return AuthResult(errorMessage: errorMessage);
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return AuthResult(errorMessage: 'An unexpected error occurred.');
    }
  }

  // Check if user has a linked provider
  bool userHasProvider(String providerId) {
    final user = currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == providerId);
  }

  // Reauthenticate with Google for sensitive operations
  Future<AuthResult> reauthenticateWithGoogle() async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult(errorMessage: 'No authenticated user.');
      }

      await _googleSignIn.initialize();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        return AuthResult(errorMessage: 'Reauthentication cancelled.');
      }

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final cred = await user.reauthenticateWithCredential(credential);
      return AuthResult(userCredential: cred);
    } on FirebaseAuthException catch (e) {
      return AuthResult(errorMessage: e.message ?? 'Reauthentication failed.');
    } catch (e) {
      debugPrint('Error during Google reauthentication: $e');
      return AuthResult(errorMessage: 'Reauthentication failed.');
    }
  }

  // Get user creation time
  DateTime? get userCreationTime => currentUser?.metadata.creationTime;
}
