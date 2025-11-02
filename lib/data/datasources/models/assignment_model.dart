import '../../../domain/entities/assignment_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Assignment
/// Used to convert between API/Database format and Entity
class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String courseId;
  final List<String> scopedGroupIds;
  final DateTime startDate;
  final DateTime deadline;
  final DateTime? lateDeadline;
  final int maxAttempts;
  final List<String> allowedFileFormats;
  final int maxFileSizeMB;
  final DateTime createdAt;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseId,
    required this.scopedGroupIds,
    required this.startDate,
    required this.deadline,
    this.lateDeadline,
    required this.maxAttempts,
    required this.allowedFileFormats,
    required this.maxFileSizeMB,
    required this.createdAt,
  });

  /// Convert from JSON (Firestore document)
  factory AssignmentModel.fromJson(Map<String, dynamic> json, String id) {
    return AssignmentModel(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      courseId: json['courseId'] as String,
      scopedGroupIds: List<String>.from(json['scopedGroupIds'] ?? []),
      startDate: (json['startDate'] as Timestamp).toDate(),
      deadline: (json['deadline'] as Timestamp).toDate(),
      lateDeadline: json['lateDeadline'] != null
          ? (json['lateDeadline'] as Timestamp).toDate()
          : null,
      maxAttempts: json['maxAttempts'] as int? ?? 1,
      allowedFileFormats: List<String>.from(json['allowedFileFormats'] ?? []),
      maxFileSizeMB: json['maxFileSizeMB'] as int? ?? 10,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId,
      'scopedGroupIds': scopedGroupIds,
      'startDate': Timestamp.fromDate(startDate),
      'deadline': Timestamp.fromDate(deadline),
      if (lateDeadline != null)
        'lateDeadline': Timestamp.fromDate(lateDeadline!),
      'maxAttempts': maxAttempts,
      'allowedFileFormats': allowedFileFormats,
      'maxFileSizeMB': maxFileSizeMB,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to Entity (domain layer)
  AssignmentEntity toEntity() {
    return AssignmentEntity(
      id: id,
      title: title,
      description: description,
      courseId: courseId,
      scopedGroupIds: scopedGroupIds,
      startDate: startDate,
      deadline: deadline,
      lateDeadline: lateDeadline,
      maxAttempts: maxAttempts,
      allowedFileFormats: allowedFileFormats,
      maxFileSizeMB: maxFileSizeMB,
      createdAt: createdAt,
    );
  }

  /// Convert from Entity (domain layer)
  factory AssignmentModel.fromEntity(AssignmentEntity entity) {
    return AssignmentModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      courseId: entity.courseId,
      scopedGroupIds: entity.scopedGroupIds,
      startDate: entity.startDate,
      deadline: entity.deadline,
      lateDeadline: entity.lateDeadline,
      maxAttempts: entity.maxAttempts,
      allowedFileFormats: entity.allowedFileFormats,
      maxFileSizeMB: entity.maxFileSizeMB,
      createdAt: entity.createdAt,
    );
  }
}
