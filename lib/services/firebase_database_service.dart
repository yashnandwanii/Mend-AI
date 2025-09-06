// File: lib/services/firebase_database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/relationship_model.dart';
import '../models/session_model.dart';
import '../models/reflection_model.dart';

class FirebaseDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Relationship Management
  Future<RelationshipModel> createRelationship(String partnerAId) async {
    try {
      final inviteCode = _generateInviteCode();
      final relationship = RelationshipModel(
        id: _uuid.v4(),
        partnerAId: partnerAId,
        partnerBId: '',
        inviteCode: inviteCode,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('relationships')
          .doc(relationship.id)
          .set(relationship.toMap());
      return relationship;
    } catch (e) {
      print('Error creating relationship: $e');
      rethrow;
    }
  }

  Future<RelationshipModel?> joinRelationship(
    String inviteCode,
    String partnerBId,
  ) async {
    try {
      final query = await _firestore
          .collection('relationships')
          .where('inviteCode', isEqualTo: inviteCode)
          .where('partnerBId', isEqualTo: '')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final relationship = RelationshipModel.fromFirestore(doc);

        final updatedRelationship = relationship.copyWith(
          partnerBId: partnerBId,
          isActive: true,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('relationships')
            .doc(relationship.id)
            .update(updatedRelationship.toMap());
        return updatedRelationship;
      }
      return null;
    } catch (e) {
      print('Error joining relationship: $e');
      return null;
    }
  }

  Future<RelationshipModel?> getRelationshipByUserId(String userId) async {
    try {
      // Check if user is partner A
      var query = await _firestore
          .collection('relationships')
          .where('partnerAId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return RelationshipModel.fromFirestore(query.docs.first);
      }

      // Check if user is partner B
      query = await _firestore
          .collection('relationships')
          .where('partnerBId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return RelationshipModel.fromFirestore(query.docs.first);
      }

      return null;
    } catch (e) {
      print('Error getting relationship: $e');
      return null;
    }
  }

  // Session Management
  Future<SessionModel> createSession(String relationshipId) async {
    try {
      final session = SessionModel(
        id: _uuid.v4(),
        relationshipId: relationshipId,
        startTime: DateTime.now(),
        duration: 0,
        partnerAScores: {},
        partnerBScores: {},
        transcript: [],
        aiSuggestions: [],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('sessions')
          .doc(session.id)
          .set(session.toMap());
      return session;
    } catch (e) {
      print('Error creating session: $e');
      rethrow;
    }
  }

  Future<void> updateSession(SessionModel session) async {
    try {
      await _firestore
          .collection('sessions')
          .doc(session.id)
          .update(session.toMap());
    } catch (e) {
      print('Error updating session: $e');
      rethrow;
    }
  }

  Future<List<SessionModel>> getSessionsByRelationshipId(
    String relationshipId,
  ) async {
    try {
      final query = await _firestore
          .collection('sessions')
          .where('relationshipId', isEqualTo: relationshipId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => SessionModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting sessions: $e');
      return [];
    }
  }

  // Reflection Management
  Future<void> saveReflection(ReflectionModel reflection) async {
    try {
      await _firestore
          .collection('reflections')
          .doc(reflection.id)
          .set(reflection.toMap());
    } catch (e) {
      print('Error saving reflection: $e');
      rethrow;
    }
  }

  Future<List<ReflectionModel>> getReflectionsByUserId(String userId) async {
    try {
      final query = await _firestore
          .collection('reflections')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ReflectionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting reflections: $e');
      return [];
    }
  }

  // Helper method to generate invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    for (int i = 0; i < 6; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }
}
