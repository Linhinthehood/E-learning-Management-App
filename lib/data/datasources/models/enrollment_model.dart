import '../../../domain/entities/enrollment_entity.dart';

/// Data model for Enrollment
/// Used to convert between API/Database format and Entity
class EnrollmentModel {
  final String id;
  final String studentId;
  final String courseId;
  final String groupId;
  final String semesterId;

  EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.groupId,
    required this.semesterId,
  });

  /// Convert from JSON (Firestore document)
  factory EnrollmentModel.fromJson(Map<String, dynamic> json, String id) {
    return EnrollmentModel(
      id: id,
      studentId: json['studentId'] as String,
      courseId: json['courseId'] as String,
      groupId: json['groupId'] as String,
      semesterId: json['semesterId'] as String,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'groupId': groupId,
      'semesterId': semesterId,
    };
  }

  /// Convert to Entity (domain layer)
  EnrollmentEntity toEntity() {
    return EnrollmentEntity(
      id: id,
      studentId: studentId,
      courseId: courseId,
      groupId: groupId,
      semesterId: semesterId,
    );
  }

  /// Convert from Entity (domain layer)
  factory EnrollmentModel.fromEntity(EnrollmentEntity entity) {
    return EnrollmentModel(
      id: entity.id,
      studentId: entity.studentId,
      courseId: entity.courseId,
      groupId: entity.groupId,
      semesterId: entity.semesterId,
    );
  }
}
