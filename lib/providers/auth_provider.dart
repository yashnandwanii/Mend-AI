// File: lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../models/user_model.dart';

// Auth service provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// User profile provider
final userProfileProvider = StreamProvider.family<UserModel?, String>((
  ref,
  userId,
) async* {
  final authService = ref.watch(authServiceProvider);
  final profile = await authService.getUserProfile(userId);
  yield profile;
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _authService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.signInWithEmail(email, password);
      if (result != null) {
        state = AsyncValue.data(result.user);
      } else {
        state = const AsyncValue.error('Failed to sign in', StackTrace.empty);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createAccount(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.createAccount(email, password);
      if (result != null) {
        state = AsyncValue.data(result.user);
      } else {
        state = const AsyncValue.error(
          'Failed to create account',
          StackTrace.empty,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _authService.createUserProfile(user);
    } catch (e) {
      // Handle error
      print('Error creating user profile: $e');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _authService.updateUserProfile(user);
    } catch (e) {
      // Handle error
      print('Error updating user profile: $e');
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService);
    });
