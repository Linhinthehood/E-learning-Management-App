import '../../../domain/entities/quiz_participation_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Quiz Participation
class QuizParticipationModel {
  final String id;
  final String quizId;
  final String studentId;
  final DateTime joinedAt;
  final bool isActive;

  QuizParticipationModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.joinedAt,
    this.isActive = true,
  });

  factory QuizParticipationModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return QuizParticipationModel(
      id: id,
      quizId: json['quizId'] as String,
      studentId: json['studentId'] as String,
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
    };
  }

  QuizParticipationEntity toEntity() {
    return QuizParticipationEntity(
      id: id,
      quizId: quizId,
      studentId: studentId,
      joinedAt: joinedAt,
      isActive: isActive,
    );
  }

  factory QuizParticipationModel.fromEntity(QuizParticipationEntity entity) {
    return QuizParticipationModel(
      id: entity.id,
      quizId: entity.quizId,
      studentId: entity.studentId,
      joinedAt: entity.joinedAt,
      isActive: entity.isActive,
    );
  }
}
