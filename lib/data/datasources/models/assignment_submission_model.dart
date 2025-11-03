import '../../../domain/entities/assignment_submission_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Assignment Submission
/// Used to convert between API/Database format and Entity
class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String courseId;
  final DateTime submissionTime;
  final List<String> files;
  final int attemptNumber;
  final double? grade;
  final String? feedback;
  final SubmissionStatus status;

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.courseId,
    required this.submissionTime,
    required this.files,
    required this.attemptNumber,
    this.grade,
    this.feedback,
    required this.status,
  });

  /// Convert from JSON (Firestore document)
  factory AssignmentSubmissionModel.fromJson(
    Map<String, dynamic> json,
    String id,
  ) {
    return AssignmentSubmissionModel(
      id: id,
      assignmentId: json['assignmentId'] as String,
      studentId: json['studentId'] as String,
      courseId: json['courseId'] as String,
      submissionTime: (json['submissionTime'] as Timestamp).toDate(),
      files: List<String>.from(json['files'] ?? []),
      attemptNumber: json['attemptNumber'] as int? ?? 1,
      grade: json['grade'] as double?,
      feedback: json['feedback'] as String?,
      status: SubmissionStatusExtension.fromString(
        json['status'] as String? ?? 'submitted',
      ),
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'courseId': courseId,
      'submissionTime': Timestamp.fromDate(submissionTime),
      'files': files,
      'attemptNumber': attemptNumber,
      if (grade != null) 'grade': grade,
      if (feedback != null) 'feedback': feedback,
      'status': status.name,
    };
  }

  /// Convert to Entity (domain layer)
  AssignmentSubmissionEntity toEntity() {
    return AssignmentSubmissionEntity(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      courseId: courseId,
      submissionTime: submissionTime,
      files: files,
      attemptNumber: attemptNumber,
      grade: grade,
      feedback: feedback,
      status: status,
    );
  }

  /// Convert from Entity (domain layer)
  factory AssignmentSubmissionModel.fromEntity(
    AssignmentSubmissionEntity entity,
  ) {
    return AssignmentSubmissionModel(
      id: entity.id,
      assignmentId: entity.assignmentId,
      studentId: entity.studentId,
      courseId: entity.courseId,
      submissionTime: entity.submissionTime,
      files: entity.files,
      attemptNumber: entity.attemptNumber,
      grade: entity.grade,
      feedback: entity.feedback,
      status: entity.status,
    );
  }
}
