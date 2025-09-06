// File: lib/models/reflection_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReflectionModel {
  final String id;
  final String sessionId;
  final String userId;
  final String partnerAppreciation;
  final String personalImprovement;
  final String gratitudeMessage;
  final int moodRating; // 1-5 scale
  final DateTime createdAt;

  ReflectionModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.partnerAppreciation,
    required this.personalImprovement,
    required this.gratitudeMessage,
    required this.moodRating,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'partnerAppreciation': partnerAppreciation,
      'personalImprovement': personalImprovement,
      'gratitudeMessage': gratitudeMessage,
      'moodRating': moodRating,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReflectionModel.fromMap(Map<String, dynamic> map) {
    return ReflectionModel(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      partnerAppreciation: map['partnerAppreciation'] ?? '',
      personalImprovement: map['personalImprovement'] ?? '',
      gratitudeMessage: map['gratitudeMessage'] ?? '',
      moodRating: map['moodRating'] ?? 3,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  factory ReflectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReflectionModel.fromMap({...data, 'id': doc.id});
  }

  ReflectionModel copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? partnerAppreciation,
    String? personalImprovement,
    String? gratitudeMessage,
    int? moodRating,
    DateTime? createdAt,
  }) {
    return ReflectionModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      partnerAppreciation: partnerAppreciation ?? this.partnerAppreciation,
      personalImprovement: personalImprovement ?? this.personalImprovement,
      gratitudeMessage: gratitudeMessage ?? this.gratitudeMessage,
      moodRating: moodRating ?? this.moodRating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
