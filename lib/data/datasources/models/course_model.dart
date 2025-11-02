import '../../../domain/entities/course_entity.dart';

/// Data model for Course
/// Used to convert between API/Database format and Entity
class CourseModel {
  final String id;
  final String name;
  final String code;
  final String semesterId;
  final String instructorId;
  final String? coverImageUrl;
  final int sessions;

  CourseModel({
    required this.id,
    required this.name,
    required this.code,
    required this.semesterId,
    required this.instructorId,
    this.coverImageUrl,
    required this.sessions,
  });

  /// Convert from JSON (Firestore document)
  factory CourseModel.fromJson(Map<String, dynamic> json, String id) {
    return CourseModel(
      id: id,
      name: json['name'] as String,
      code: json['code'] as String,
      semesterId: json['semesterId'] as String,
      instructorId: json['instructorId'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      sessions: json['sessions'] as int? ?? 10,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'semesterId': semesterId,
      'instructorId': instructorId,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      'sessions': sessions,
    };
  }

  /// Convert to Entity (domain layer)
  CourseEntity toEntity() {
    return CourseEntity(
      id: id,
      name: name,
      code: code,
      semesterId: semesterId,
      instructorId: instructorId,
      coverImageUrl: coverImageUrl,
      sessions: sessions,
    );
  }

  /// Convert from Entity (domain layer)
  factory CourseModel.fromEntity(CourseEntity entity) {
    return CourseModel(
      id: entity.id,
      name: entity.name,
      code: entity.code,
      semesterId: entity.semesterId,
      instructorId: entity.instructorId,
      coverImageUrl: entity.coverImageUrl,
      sessions: entity.sessions,
    );
  }
}
