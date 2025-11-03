import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/quiz_attempt_entity.dart';

/// Model for quiz attempts in Firestore
class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final String courseId;
  final int attemptNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> answers;
  final double? score;
  final double maxScore;
  final QuizAttemptStatus status;
  final String? feedback;
  final bool autoGraded;

  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.courseId,
    required this.attemptNumber,
    required this.startTime,
    this.endTime,
    required this.answers,
    this.score,
    required this.maxScore,
    required this.status,
    this.feedback,
    required this.autoGraded,
  });

  /// Convert to entity
  QuizAttemptEntity toEntity() {
    return QuizAttemptEntity(
      id: id,
      quizId: quizId,
      studentId: studentId,
      courseId: courseId,
      attemptNumber: attemptNumber,
      startTime: startTime,
      endTime: endTime,
      answers: answers,
      score: score,
      maxScore: maxScore,
      status: status,
      feedback: feedback,
      autoGraded: autoGraded,
    );
  }

  /// Create from entity
  factory QuizAttemptModel.fromEntity(QuizAttemptEntity entity) {
    return QuizAttemptModel(
      id: entity.id,
      quizId: entity.quizId,
      studentId: entity.studentId,
      courseId: entity.courseId,
      attemptNumber: entity.attemptNumber,
      startTime: entity.startTime,
      endTime: entity.endTime,
      answers: entity.answers,
      score: entity.score,
      maxScore: entity.maxScore,
      status: entity.status,
      feedback: entity.feedback,
      autoGraded: entity.autoGraded,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'courseId': courseId,
      'attemptNumber': attemptNumber,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'answers': answers,
      'score': score,
      'maxScore': maxScore,
      'status': status.name,
      'feedback': feedback,
      'autoGraded': autoGraded,
    };
  }

  /// Create from Firestore JSON
  factory QuizAttemptModel.fromJson(Map<String, dynamic> json, String id) {
    return QuizAttemptModel(
      id: id,
      quizId: json['quizId'] as String,
      studentId: json['studentId'] as String,
      courseId: json['courseId'] as String,
      attemptNumber: json['attemptNumber'] as int,
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: json['endTime'] != null
          ? (json['endTime'] as Timestamp).toDate()
          : null,
      answers: Map<String, dynamic>.from(json['answers'] as Map),
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      maxScore: (json['maxScore'] as num).toDouble(),
      status: QuizAttemptStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QuizAttemptStatus.inProgress,
      ),
      feedback: json['feedback'] as String?,
      autoGraded: json['autoGraded'] as bool? ?? true,
    );
  }
}
