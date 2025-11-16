import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/view_tracking_model.dart';

/// Remote datasource for view tracking
class ViewTrackingRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ViewTrackingRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Track a view or download action
  Future<void> trackAction({
    required String contentId,
    required String contentType,
    required String action,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name from users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName =
          userDoc.data()?['displayName'] as String? ?? 'Unknown User';

      // Check if this action was already tracked (avoid duplicates for views)
      if (action == 'view') {
        final existing = await _firestore
            .collection('viewTracking')
            .where('contentId', isEqualTo: contentId)
            .where('contentType', isEqualTo: contentType)
            .where('studentId', isEqualTo: user.uid)
            .where('action', isEqualTo: 'view')
            .limit(1)
            .get();

        // If already viewed, don't track again
        if (existing.docs.isNotEmpty) return;
      }

      // Add tracking record
      await _firestore.collection('viewTracking').add({
        'contentId': contentId,
        'contentType': contentType,
        'studentId': user.uid,
        'studentName': userName,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to track action: $e');
    }
  }

  /// Get tracking records for a specific content
  Future<List<ViewTrackingModel>> getTrackingByContentId(
    String contentId,
    String contentType,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('viewTracking')
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ViewTrackingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tracking data: $e');
    }
  }

  /// Get tracking records for a specific student
  Future<List<ViewTrackingModel>> getTrackingByStudentId(
    String studentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('viewTracking')
          .where('studentId', isEqualTo: studentId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ViewTrackingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tracking data: $e');
    }
  }

  /// Check if a student has viewed specific content
  Future<bool> hasStudentViewed(
    String studentId,
    String contentId,
    String contentType,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('viewTracking')
          .where('studentId', isEqualTo: studentId)
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .where('action', isEqualTo: 'view')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
