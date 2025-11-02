import '../../../domain/entities/announcement_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Announcement
/// Used to convert between API/Database format and Entity
class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final List<String> attachments;
  final String courseId;
  final String authorId;
  final List<String> scopedGroupIds;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.attachments,
    required this.courseId,
    required this.authorId,
    required this.scopedGroupIds,
    required this.createdAt,
  });

  /// Convert from JSON (Firestore document)
  factory AnnouncementModel.fromJson(Map<String, dynamic> json, String id) {
    return AnnouncementModel(
      id: id,
      title: json['title'] as String,
      content: json['content'] as String,
      attachments: List<String>.from(json['attachments'] ?? []),
      courseId: json['courseId'] as String,
      authorId: json['authorId'] as String,
      scopedGroupIds: List<String>.from(json['scopedGroupIds'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'attachments': attachments,
      'courseId': courseId,
      'authorId': authorId,
      'scopedGroupIds': scopedGroupIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to Entity (domain layer)
  AnnouncementEntity toEntity() {
    return AnnouncementEntity(
      id: id,
      title: title,
      content: content,
      attachments: attachments,
      courseId: courseId,
      authorId: authorId,
      scopedGroupIds: scopedGroupIds,
      createdAt: createdAt,
    );
  }

  /// Convert from Entity (domain layer)
  factory AnnouncementModel.fromEntity(AnnouncementEntity entity) {
    return AnnouncementModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      attachments: entity.attachments,
      courseId: entity.courseId,
      authorId: entity.authorId,
      scopedGroupIds: entity.scopedGroupIds,
      createdAt: entity.createdAt,
    );
  }
}
