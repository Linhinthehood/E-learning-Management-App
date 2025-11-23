import '../entities/forum_reply_entity.dart';

/// Forum reply repository interface
/// This defines the contract that data layer must implement
abstract class IForumReplyRepository {
  /// Get all replies for a forum topic
  Future<List<ForumReplyEntity>> getRepliesByTopic(String topicId);

  /// Get a single forum reply by ID
  Future<ForumReplyEntity?> getReplyById(String replyId);

  /// Create a new forum reply
  Future<ForumReplyEntity> createReply(ForumReplyEntity reply);

  /// Update an existing forum reply
  Future<ForumReplyEntity> updateReply(ForumReplyEntity reply);

  /// Delete a forum reply
  Future<void> deleteReply(String replyId);

  /// Get threaded replies (replies to a specific reply)
  Future<List<ForumReplyEntity>> getThreadedReplies(
    String topicId,
    String replyToId,
  );

  /// Listen to replies for a forum topic in real-time (returns stream)
  Stream<List<ForumReplyEntity>> listenToRepliesByTopic(String topicId);
}
