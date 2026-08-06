import 'package:equatable/equatable.dart';

class ScanResult extends Equatable {
  final String? id;
  final String userId;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final String? imageUrl;
  final double vitaminDLevel;
  final String status; // Sufficient, Insufficient, Deficient
  final double aiConfidence;
  final String? aiRawResponse;
  final List<RecommendedFood> recommendations;
  final List<String> lifestyleTips;
  final DateTime createdAt;

  const ScanResult({
    this.id,
    required this.userId,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.imageUrl,
    required this.vitaminDLevel,
    required this.status,
    required this.aiConfidence,
    this.aiRawResponse,
    required this.recommendations,
    required this.lifestyleTips,
    required this.createdAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      patientName: json['patient_name'] as String?,
      patientAge: json['patient_age'] != null ? (json['patient_age'] as num).toInt() : null,
      patientGender: json['patient_gender'] as String?,
      imageUrl: json['image_url'] as String?,
      vitaminDLevel: (json['vitamin_d_level'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Insufficient',
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble() ?? 0.9,
      aiRawResponse: json['ai_raw_response'] as String?,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => RecommendedFood.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      lifestyleTips: (json['lifestyle_tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final bool hasValidUserId = userId.isNotEmpty && userId != 'guest_user';
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      if (hasValidUserId) 'user_id': userId,
      if (patientName != null && patientName!.isNotEmpty) 'patient_name': patientName,
      if (patientAge != null) 'patient_age': patientAge,
      if (patientGender != null && patientGender!.isNotEmpty) 'patient_gender': patientGender,
      if (imageUrl != null) 'image_url': imageUrl,
      'vitamin_d_level': vitaminDLevel,
      'status': status,
      'ai_confidence': aiConfidence,
      if (aiRawResponse != null) 'ai_raw_response': aiRawResponse,
      'recommendations': recommendations.map((e) => e.toJson()).toList(),
      'lifestyle_tips': lifestyleTips,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        patientName,
        patientAge,
        patientGender,
        imageUrl,
        vitaminDLevel,
        status,
        aiConfidence,
        aiRawResponse,
        recommendations,
        lifestyleTips,
        createdAt,
      ];
}

class RecommendedFood extends Equatable {
  final String name;
  final String description;
  final String? category;

  const RecommendedFood({
    required this.name,
    required this.description,
    this.category,
  });

  factory RecommendedFood.fromJson(Map<String, dynamic> json) {
    return RecommendedFood(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (category != null) 'category': category,
    };
  }

  @override
  List<Object?> get props => [name, description, category];
}
