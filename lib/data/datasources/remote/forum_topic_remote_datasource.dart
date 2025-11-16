import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum_topic_model.dart';

/// Remote data source for forum topics
/// Handles Firestore calls for forum topics
abstract class ForumTopicRemoteDataSource {
  /// Get all forum topics for a course
  Future<List<ForumTopicModel>> getTopicsByCourse(String courseId);

  /// Get a single forum topic by ID
  Future<ForumTopicModel?> getTopicById(String topicId);

  /// Create a new forum topic
  Future<ForumTopicModel> createTopic(ForumTopicModel topic);

  /// Update an existing forum topic
  Future<ForumTopicModel> updateTopic(ForumTopicModel topic);

  /// Delete a forum topic
  Future<void> deleteTopic(String topicId);

  /// Search forum topics by keyword
  Future<List<ForumTopicModel>> searchTopics(String courseId, String keyword);

  /// Get recent forum topics (last N days)
  Future<List<ForumTopicModel>> getRecentTopics(String courseId, int days);

  /// Increment reply count for a topic
  Future<void> incrementReplyCount(String topicId);
}

/// Implementation of ForumTopicRemoteDataSource using Firestore
class ForumTopicRemoteDataSourceImpl implements ForumTopicRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ForumTopicModel>> getTopicsByCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('forumTopics')
          .where('courseId', isEqualTo: courseId)
          .get();

      final topics = querySnapshot.docs
          .map((doc) => ForumTopicModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by createdAt descending (newest first)
      topics.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return topics;
    } catch (e) {
      throw Exception('Failed to get forum topics: ${e.toString()}');
    }
  }

  @override
  Future<ForumTopicModel?> getTopicById(String topicId) async {
    try {
      final docSnapshot = await _firestore
          .collection('forumTopics')
          .doc(topicId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return ForumTopicModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get forum topic: ${e.toString()}');
    }
  }

  @override
  Future<ForumTopicModel> createTopic(ForumTopicModel topic) async {
    try {
      final docRef = await _firestore
          .collection('forumTopics')
          .add(topic.toJson());

      final docSnapshot = await docRef.get();
      return ForumTopicModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create forum topic: ${e.toString()}');
    }
  }

  @override
  Future<ForumTopicModel> updateTopic(ForumTopicModel topic) async {
    try {
      await _firestore
          .collection('forumTopics')
          .doc(topic.id)
          .update(topic.toJson());

      return topic;
    } catch (e) {
      throw Exception('Failed to update forum topic: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    try {
      // Delete all replies first
      final repliesSnapshot = await _firestore
          .collection('forumReplies')
          .where('topicId', isEqualTo: topicId)
          .get();

      // Batch delete replies
      final batch = _firestore.batch();
      for (var doc in repliesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the topic
      batch.delete(_firestore.collection('forumTopics').doc(topicId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete forum topic: ${e.toString()}');
    }
  }

  @override
  Future<List<ForumTopicModel>> searchTopics(
    String courseId,
    String keyword,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('forumTopics')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Filter by keyword in memory (case-insensitive search)
      final topics = querySnapshot.docs
          .map((doc) => ForumTopicModel.fromJson(doc.data(), doc.id))
          .where(
            (topic) =>
                topic.title.toLowerCase().contains(keyword.toLowerCase()) ||
                topic.content.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();

      // Sort by createdAt descending
      topics.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return topics;
    } catch (e) {
      throw Exception('Failed to search forum topics: ${e.toString()}');
    }
  }

  @override
  Future<List<ForumTopicModel>> getRecentTopics(
    String courseId,
    int days,
  ) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final querySnapshot = await _firestore
          .collection('forumTopics')
          .where('courseId', isEqualTo: courseId)
          .get();

      // Filter and sort in memory
      final topics = querySnapshot.docs
          .map((doc) => ForumTopicModel.fromJson(doc.data(), doc.id))
          .where((topic) => topic.createdAt.isAfter(cutoffDate))
          .toList();

      // Sort by createdAt descending
      topics.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return topics;
    } catch (e) {
      throw Exception('Failed to get recent forum topics: ${e.toString()}');
    }
  }

  @override
  Future<void> incrementReplyCount(String topicId) async {
    try {
      await _firestore.collection('forumTopics').doc(topicId).update({
        'replyCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment reply count: ${e.toString()}');
    }
  }
}
