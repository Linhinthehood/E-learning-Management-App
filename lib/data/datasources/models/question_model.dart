import '../../../domain/entities/question_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Question
/// Used to convert between API/Database format and Entity
class QuestionModel {
  final String id;
  final String questionBankId;
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final dynamic correctAnswer;
  final QuestionDifficulty difficulty;
  final double points;
  final String? explanation;
  final String? imageUrl;
  final DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.questionBankId,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.points,
    this.explanation,
    this.imageUrl,
    required this.createdAt,
  });

  /// Convert from JSON (Firestore document)
  factory QuestionModel.fromJson(Map<String, dynamic> json, String id) {
    return QuestionModel(
      id: id,
      questionBankId: json['questionBankId'] as String,
      questionText: json['questionText'] as String,
      type: QuestionType.values.byName(json['type'] as String),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'],
      difficulty: QuestionDifficulty.values.byName(
        json['difficulty'] as String,
      ),
      points: (json['points'] as num?)?.toDouble() ?? 1.0,
      explanation: json['explanation'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'questionBankId': questionBankId,
      'questionText': questionText,
      'type': type.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty.name,
      'points': points,
      if (explanation != null) 'explanation': explanation,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to Entity (domain layer)
  QuestionEntity toEntity() {
    return QuestionEntity(
      id: id,
      questionBankId: questionBankId,
      questionText: questionText,
      type: type,
      options: options,
      correctAnswer: correctAnswer,
      difficulty: difficulty,
      points: points,
      explanation: explanation,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

  /// Convert from Entity (domain layer)
  factory QuestionModel.fromEntity(QuestionEntity entity) {
    return QuestionModel(
      id: entity.id,
      questionBankId: entity.questionBankId,
      questionText: entity.questionText,
      type: entity.type,
      options: entity.options,
      correctAnswer: entity.correctAnswer,
      difficulty: entity.difficulty,
      points: entity.points,
      explanation: entity.explanation,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
    );
  }
}
