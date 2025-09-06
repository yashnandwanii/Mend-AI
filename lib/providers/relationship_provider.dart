// File: lib/providers/relationship_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_database_service.dart';
import '../models/relationship_model.dart';
import '../models/session_model.dart';
import '../models/reflection_model.dart';

// Database service provider
final databaseServiceProvider = Provider<FirebaseDatabaseService>((ref) {
  return FirebaseDatabaseService();
});

// Relationship state notifier
class RelationshipNotifier
    extends StateNotifier<AsyncValue<RelationshipModel?>> {
  final FirebaseDatabaseService _databaseService;

  RelationshipNotifier(this._databaseService)
    : super(const AsyncValue.loading());

  Future<void> createRelationship(String userId) async {
    state = const AsyncValue.loading();
    try {
      final relationship = await _databaseService.createRelationship(userId);
      state = AsyncValue.data(relationship);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> joinRelationship(String inviteCode, String userId) async {
    state = const AsyncValue.loading();
    try {
      final relationship = await _databaseService.joinRelationship(
        inviteCode,
        userId,
      );
      state = AsyncValue.data(relationship);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadRelationship(String userId) async {
    state = const AsyncValue.loading();
    try {
      final relationship = await _databaseService.getRelationshipByUserId(
        userId,
      );
      state = AsyncValue.data(relationship);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void clearRelationship() {
    state = const AsyncValue.data(null);
  }
}

final relationshipNotifierProvider =
    StateNotifierProvider<RelationshipNotifier, AsyncValue<RelationshipModel?>>(
      (ref) {
        final databaseService = ref.watch(databaseServiceProvider);
        return RelationshipNotifier(databaseService);
      },
    );

// Session state notifier
class SessionNotifier extends StateNotifier<AsyncValue<SessionModel?>> {
  final FirebaseDatabaseService _databaseService;

  SessionNotifier(this._databaseService) : super(const AsyncValue.data(null));

  Future<void> startSession(String relationshipId) async {
    state = const AsyncValue.loading();
    try {
      final session = await _databaseService.createSession(relationshipId);
      state = AsyncValue.data(session);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSession(SessionModel session) async {
    try {
      await _databaseService.updateSession(session);
      state = AsyncValue.data(session);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void endSession() {
    state = const AsyncValue.data(null);
  }
}

final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<SessionModel?>>((ref) {
      final databaseService = ref.watch(databaseServiceProvider);
      return SessionNotifier(databaseService);
    });

// Sessions history provider
final sessionsHistoryProvider =
    FutureProvider.family<List<SessionModel>, String>((
      ref,
      relationshipId,
    ) async {
      final databaseService = ref.watch(databaseServiceProvider);
      return databaseService.getSessionsByRelationshipId(relationshipId);
    });

// Reflections provider
final reflectionsProvider =
    FutureProvider.family<List<ReflectionModel>, String>((ref, userId) async {
      final databaseService = ref.watch(databaseServiceProvider);
      return databaseService.getReflectionsByUserId(userId);
    });
