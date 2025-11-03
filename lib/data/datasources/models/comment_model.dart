import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/comment_entity.dart';

/// Comment model for Firestore data
class CommentModel {
  final String id;
  final String announcementId;
  final String authorId;
  final String authorName;
  final String content;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  const CommentModel({
    required this.id,
    required this.announcementId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convert to entity
  CommentEntity toEntity() {
    return CommentEntity(
      id: id,
      announcementId: announcementId,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  /// Create from Firestore document
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      announcementId: data['announcementId'] as String,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      content: data['content'] as String,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'announcementId': announcementId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
