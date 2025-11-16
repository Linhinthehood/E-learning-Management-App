import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';

/// Remote datasource for comments
class CommentRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CommentRemoteDataSource({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get comments by announcement ID
  Future<List<CommentModel>> getCommentsByAnnouncementId(
    String announcementId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('announcementId', isEqualTo: announcementId)
          .get();

      // Convert to list and sort in memory (avoids need for Firestore index)
      final comments = snapshot.docs
          .map((doc) => CommentModel.fromFirestore(doc))
          .toList();

      // Sort by createdAt (oldest first)
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return comments;
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  /// Add a new comment
  Future<void> addComment({
    required String announcementId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name from users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName =
          userDoc.data()?['displayName'] as String? ?? 'Unknown User';

      await _firestore.collection('comments').add({
        'announcementId': announcementId,
        'authorId': user.uid,
        'authorName': userName,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Update a comment
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('comments').doc(commentId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}
