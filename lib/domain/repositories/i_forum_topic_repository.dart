import '../entities/forum_topic_entity.dart';

/// Forum topic repository interface
/// This defines the contract that data layer must implement
abstract class IForumTopicRepository {
  /// Get all forum topics for a course
  Future<List<ForumTopicEntity>> getTopicsByCourse(String courseId);

  /// Get a single forum topic by ID
  Future<ForumTopicEntity?> getTopicById(String topicId);

  /// Create a new forum topic
  Future<ForumTopicEntity> createTopic(ForumTopicEntity topic);

  /// Update an existing forum topic
  Future<ForumTopicEntity> updateTopic(ForumTopicEntity topic);

  /// Delete a forum topic
  Future<void> deleteTopic(String topicId);

  /// Search forum topics by keyword
  Future<List<ForumTopicEntity>> searchTopics(String courseId, String keyword);

  /// Get recent forum topics (last N days)
  Future<List<ForumTopicEntity>> getRecentTopics(String courseId, int days);

  /// Increment reply count for a topic
  Future<void> incrementReplyCount(String topicId);
}
