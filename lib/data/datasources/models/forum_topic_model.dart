import '../../../domain/entities/forum_topic_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Forum Topic
/// Used to convert between API/Database format and Entity
class ForumTopicModel {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final String authorId;
  final List<String> attachments;
  final DateTime createdAt;
  final int replyCount;

  ForumTopicModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.attachments,
    required this.createdAt,
    this.replyCount = 0,
  });

  /// Convert from JSON (Firestore document)
  factory ForumTopicModel.fromJson(Map<String, dynamic> json, String id) {
    return ForumTopicModel(
      id: id,
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      attachments: List<String>.from(json['attachments'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      replyCount: json['replyCount'] as int? ?? 0,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'replyCount': replyCount,
    };
  }

  /// Convert to Entity (domain layer)
  ForumTopicEntity toEntity() {
    return ForumTopicEntity(
      id: id,
      courseId: courseId,
      title: title,
      content: content,
      authorId: authorId,
      attachments: attachments,
      createdAt: createdAt,
      replyCount: replyCount,
    );
  }

  /// Convert from Entity (domain layer)
  factory ForumTopicModel.fromEntity(ForumTopicEntity entity) {
    return ForumTopicModel(
      id: entity.id,
      courseId: entity.courseId,
      title: entity.title,
      content: entity.content,
      authorId: entity.authorId,
      attachments: entity.attachments,
      createdAt: entity.createdAt,
      replyCount: entity.replyCount,
    );
  }
}
