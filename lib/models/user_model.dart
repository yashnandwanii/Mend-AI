// File: lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, other }

class UserModel {
  final String id;
  final String name;
  final String email;
  final Gender gender;
  final List<String> relationshipGoals;
  final List<String> currentChallenges;
  final String? relationshipId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,
    required this.relationshipGoals,
    required this.currentChallenges,
    this.relationshipId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'gender': gender.name,
      'relationshipGoals': relationshipGoals,
      'currentChallenges': currentChallenges,
      'relationshipId': relationshipId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      gender: Gender.values.firstWhere(
        (g) => g.name == map['gender'],
        orElse: () => Gender.other,
      ),
      relationshipGoals: List<String>.from(map['relationshipGoals'] ?? []),
      currentChallenges: List<String>.from(map['currentChallenges'] ?? []),
      relationshipId: map['relationshipId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap({...data, 'id': doc.id});
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    Gender? gender,
    List<String>? relationshipGoals,
    List<String>? currentChallenges,
    String? relationshipId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      relationshipGoals: relationshipGoals ?? this.relationshipGoals,
      currentChallenges: currentChallenges ?? this.currentChallenges,
      relationshipId: relationshipId ?? this.relationshipId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
