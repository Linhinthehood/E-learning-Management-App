import '../entities/comment_entity.dart';

/// Repository interface for comments
abstract class CommentRepository {
  /// Get all comments for an announcement
  Future<List<CommentEntity>> getCommentsByAnnouncementId(
    String announcementId,
  );

  /// Add a new comment
  Future<void> addComment({
    required String announcementId,
    required String content,
  });

  /// Update a comment
  Future<void> updateComment({
    required String commentId,
    required String content,
  });

  /// Delete a comment
  Future<void> deleteComment(String commentId);
}
