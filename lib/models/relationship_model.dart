// File: lib/models/relationship_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class RelationshipModel {
  final String id;
  final String partnerAId;
  final String partnerBId;
  final String inviteCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RelationshipModel({
    required this.id,
    required this.partnerAId,
    required this.partnerBId,
    required this.inviteCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partnerAId': partnerAId,
      'partnerBId': partnerBId,
      'inviteCode': inviteCode,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RelationshipModel.fromMap(Map<String, dynamic> map) {
    return RelationshipModel(
      id: map['id'] ?? '',
      partnerAId: map['partnerAId'] ?? '',
      partnerBId: map['partnerBId'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      isActive: map['isActive'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  factory RelationshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RelationshipModel.fromMap({...data, 'id': doc.id});
  }

  RelationshipModel copyWith({
    String? id,
    String? partnerAId,
    String? partnerBId,
    String? inviteCode,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RelationshipModel(
      id: id ?? this.id,
      partnerAId: partnerAId ?? this.partnerAId,
      partnerBId: partnerBId ?? this.partnerBId,
      inviteCode: inviteCode ?? this.inviteCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
