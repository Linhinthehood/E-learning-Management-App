import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forum_reply_model.dart';

/// Remote data source for forum replies
/// Handles Firestore calls for forum replies
abstract class ForumReplyRemoteDataSource {
  /// Get all replies for a forum topic
  Future<List<ForumReplyModel>> getRepliesByTopic(String topicId);

  /// Get a single forum reply by ID
  Future<ForumReplyModel?> getReplyById(String replyId);

  /// Create a new forum reply
  Future<ForumReplyModel> createReply(ForumReplyModel reply);

  /// Update an existing forum reply
  Future<ForumReplyModel> updateReply(ForumReplyModel reply);

  /// Delete a forum reply
  Future<void> deleteReply(String replyId);

  /// Get threaded replies (replies to a specific reply)
  Future<List<ForumReplyModel>> getThreadedReplies(
    String topicId,
    String replyToId,
  );

  /// Listen to replies for a forum topic in real-time (returns stream)
  Stream<List<ForumReplyModel>> listenToRepliesByTopic(String topicId);
}

/// Implementation of ForumReplyRemoteDataSource using Firestore
class ForumReplyRemoteDataSourceImpl implements ForumReplyRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ForumReplyModel>> getRepliesByTopic(String topicId) async {
    try {
      final querySnapshot = await _firestore
          .collection('forumReplies')
          .where('topicId', isEqualTo: topicId)
          .get();

      final replies = querySnapshot.docs
          .map((doc) => ForumReplyModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by createdAt ascending (oldest first for replies)
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return replies;
    } catch (e) {
      throw Exception('Failed to get forum replies: ${e.toString()}');
    }
  }

  @override
  Future<ForumReplyModel?> getReplyById(String replyId) async {
    try {
      final docSnapshot = await _firestore
          .collection('forumReplies')
          .doc(replyId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return ForumReplyModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get forum reply: ${e.toString()}');
    }
  }

  @override
  Future<ForumReplyModel> createReply(ForumReplyModel reply) async {
    try {
      final docRef = await _firestore
          .collection('forumReplies')
          .add(reply.toJson());

      final docSnapshot = await docRef.get();
      return ForumReplyModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create forum reply: ${e.toString()}');
    }
  }

  @override
  Future<ForumReplyModel> updateReply(ForumReplyModel reply) async {
    try {
      await _firestore
          .collection('forumReplies')
          .doc(reply.id)
          .update(reply.toJson());

      return reply;
    } catch (e) {
      throw Exception('Failed to update forum reply: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteReply(String replyId) async {
    try {
      await _firestore.collection('forumReplies').doc(replyId).delete();
    } catch (e) {
      throw Exception('Failed to delete forum reply: ${e.toString()}');
    }
  }

  @override
  Future<List<ForumReplyModel>> getThreadedReplies(
    String topicId,
    String replyToId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('forumReplies')
          .where('topicId', isEqualTo: topicId)
          .where('replyToId', isEqualTo: replyToId)
          .get();

      final replies = querySnapshot.docs
          .map((doc) => ForumReplyModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by createdAt ascending
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return replies;
    } catch (e) {
      throw Exception('Failed to get threaded replies: ${e.toString()}');
    }
  }

  @override
  Stream<List<ForumReplyModel>> listenToRepliesByTopic(String topicId) {
    try {
      return _firestore
          .collection('forumReplies')
          .where('topicId', isEqualTo: topicId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ForumReplyModel.fromJson(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to listen to forum replies: ${e.toString()}');
    }
  }
}
