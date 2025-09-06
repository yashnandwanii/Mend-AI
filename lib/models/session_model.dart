// File: lib/models/session_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String relationshipId;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final Map<String, double> partnerAScores;
  final Map<String, double> partnerBScores;
  final List<String> transcript;
  final List<String> aiSuggestions;
  final String? summary;
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.relationshipId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.partnerAScores,
    required this.partnerBScores,
    required this.transcript,
    required this.aiSuggestions,
    this.summary,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'relationshipId': relationshipId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'partnerAScores': partnerAScores,
      'partnerBScores': partnerBScores,
      'transcript': transcript,
      'aiSuggestions': aiSuggestions,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? '',
      relationshipId: map['relationshipId'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      duration: map['duration'] ?? 0,
      partnerAScores: Map<String, double>.from(map['partnerAScores'] ?? {}),
      partnerBScores: Map<String, double>.from(map['partnerBScores'] ?? {}),
      transcript: List<String>.from(map['transcript'] ?? []),
      aiSuggestions: List<String>.from(map['aiSuggestions'] ?? []),
      summary: map['summary'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel.fromMap({...data, 'id': doc.id});
  }

  SessionModel copyWith({
    String? id,
    String? relationshipId,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    Map<String, double>? partnerAScores,
    Map<String, double>? partnerBScores,
    List<String>? transcript,
    List<String>? aiSuggestions,
    String? summary,
    DateTime? createdAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      relationshipId: relationshipId ?? this.relationshipId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      partnerAScores: partnerAScores ?? this.partnerAScores,
      partnerBScores: partnerBScores ?? this.partnerBScores,
      transcript: transcript ?? this.transcript,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
