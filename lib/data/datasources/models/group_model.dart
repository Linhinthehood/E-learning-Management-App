import '../../../domain/entities/group_entity.dart';

/// Data model for Group
/// Used to convert between API/Database format and Entity
class GroupModel {
  final String id;
  final String name;
  final String courseId;
  final String semesterId;

  GroupModel({
    required this.id,
    required this.name,
    required this.courseId,
    required this.semesterId,
  });

  /// Convert from JSON (Firestore document)
  factory GroupModel.fromJson(Map<String, dynamic> json, String id) {
    return GroupModel(
      id: id,
      name: json['name'] as String,
      courseId: json['courseId'] as String,
      semesterId: json['semesterId'] as String,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'courseId': courseId,
      'semesterId': semesterId,
    };
  }

  /// Convert to Entity (domain layer)
  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      name: name,
      courseId: courseId,
      semesterId: semesterId,
    );
  }

  /// Convert from Entity (domain layer)
  factory GroupModel.fromEntity(GroupEntity entity) {
    return GroupModel(
      id: entity.id,
      name: entity.name,
      courseId: entity.courseId,
      semesterId: entity.semesterId,
    );
  }
}

