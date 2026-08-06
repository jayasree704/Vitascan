import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String userEmail) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: userEmail,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, fullName, email, avatarUrl, dateOfBirth, gender, createdAt];
}
