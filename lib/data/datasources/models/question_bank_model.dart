import '../../../domain/entities/question_bank_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for QuestionBank
/// Used to convert between API/Database format and Entity
class QuestionBankModel {
  final String id;
  final String courseId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  QuestionBankModel({
    required this.id,
    required this.courseId,
    required this.name,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert from JSON (Firestore document)
  factory QuestionBankModel.fromJson(Map<String, dynamic> json, String id) {
    return QuestionBankModel(
      id: id,
      courseId: json['courseId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'name': name,
      if (description != null) 'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Convert to Entity (domain layer)
  QuestionBankEntity toEntity() {
    return QuestionBankEntity(
      id: id,
      courseId: courseId,
      name: name,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Convert from Entity (domain layer)
  factory QuestionBankModel.fromEntity(QuestionBankEntity entity) {
    return QuestionBankModel(
      id: entity.id,
      courseId: entity.courseId,
      name: entity.name,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
