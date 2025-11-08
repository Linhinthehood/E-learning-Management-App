import '../../../domain/entities/forum_reply_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Forum Reply
/// Used to convert between API/Database format and Entity
class ForumReplyModel {
  final String id;
  final String topicId;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final String? replyToId;

  ForumReplyModel({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.replyToId,
  });

  /// Convert from JSON (Firestore document)
  factory ForumReplyModel.fromJson(Map<String, dynamic> json, String id) {
    return ForumReplyModel(
      id: id,
      topicId: json['topicId'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      replyToId: json['replyToId'] as String?,
    );
  }

  /// Convert to JSON (Firestore document)
  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'content': content,
      'authorId': authorId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (replyToId != null) 'replyToId': replyToId,
    };
  }

  /// Convert to Entity (domain layer)
  ForumReplyEntity toEntity() {
    return ForumReplyEntity(
      id: id,
      topicId: topicId,
      content: content,
      authorId: authorId,
      createdAt: createdAt,
      replyToId: replyToId,
    );
  }

  /// Convert from Entity (domain layer)
  factory ForumReplyModel.fromEntity(ForumReplyEntity entity) {
    return ForumReplyModel(
      id: entity.id,
      topicId: entity.topicId,
      content: entity.content,
      authorId: entity.authorId,
      createdAt: entity.createdAt,
      replyToId: entity.replyToId,
    );
  }
}
