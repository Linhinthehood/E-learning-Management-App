import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_presence_model.dart';

/// Remote data source for user presence
/// Handles Firestore calls for user presence tracking
abstract class UserPresenceRemoteDataSource {
  /// Get current presence status for a user
  Future<UserPresenceModel?> getUserPresence(String userId);

  /// Update user presence status (online/offline/away)
  Future<void> updatePresenceStatus(String userId, String status);

  /// Update last seen timestamp
  Future<void> updateLastSeen(String userId);

  /// Set typing status for a chat
  Future<void> setTypingStatus(String userId, String chatId, bool isTyping);

  /// Listen to user presence changes in real-time (returns stream)
  Stream<UserPresenceModel?> listenToUserPresence(String userId);

  /// Listen to typing status in a specific chat
  Stream<Map<String, bool>> listenToTypingInChat(String chatId);

  /// Initialize presence for a new user
  Future<void> initializePresence(String userId);

  /// Clean up presence when user logs out
  Future<void> cleanupPresence(String userId);
}

/// Implementation of UserPresenceRemoteDataSource using Firestore
class UserPresenceRemoteDataSourceImpl implements UserPresenceRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserPresenceModel?> getUserPresence(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('userPresence')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return UserPresenceModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get user presence: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePresenceStatus(String userId, String status) async {
    try {
      await _firestore.collection('userPresence').doc(userId).set({
        'status': status,
        'lastSeen': FieldValue.serverTimestamp(),
        'isTyping': false,
        'typingInChatId': null,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update presence status: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    try {
      await _firestore.collection('userPresence').doc(userId).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last seen: ${e.toString()}');
    }
  }

  @override
  Future<void> setTypingStatus(
    String userId,
    String chatId,
    bool isTyping,
  ) async {
    try {
      await _firestore.collection('userPresence').doc(userId).set({
        'isTyping': isTyping,
        'typingInChatId': isTyping ? chatId : null,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to set typing status: ${e.toString()}');
    }
  }

  @override
  Stream<UserPresenceModel?> listenToUserPresence(String userId) {
    try {
      return _firestore.collection('userPresence').doc(userId).snapshots().map((
        snapshot,
      ) {
        if (!snapshot.exists) {
          return null;
        }
        return UserPresenceModel.fromJson(snapshot.data()!, snapshot.id);
      });
    } catch (e) {
      throw Exception('Failed to listen to user presence: ${e.toString()}');
    }
  }

  @override
  Stream<Map<String, bool>> listenToTypingInChat(String chatId) {
    try {
      return _firestore
          .collection('userPresence')
          .where('typingInChatId', isEqualTo: chatId)
          .where('isTyping', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            final typingUsers = <String, bool>{};
            for (var doc in snapshot.docs) {
              typingUsers[doc.id] = true;
            }
            return typingUsers;
          });
    } catch (e) {
      throw Exception('Failed to listen to typing in chat: ${e.toString()}');
    }
  }

  @override
  Future<void> initializePresence(String userId) async {
    try {
      await _firestore.collection('userPresence').doc(userId).set({
        'status': 'online',
        'lastSeen': FieldValue.serverTimestamp(),
        'isTyping': false,
        'typingInChatId': null,
      });
    } catch (e) {
      throw Exception('Failed to initialize presence: ${e.toString()}');
    }
  }

  @override
  Future<void> cleanupPresence(String userId) async {
    try {
      await _firestore.collection('userPresence').doc(userId).update({
        'status': 'offline',
        'lastSeen': FieldValue.serverTimestamp(),
        'isTyping': false,
        'typingInChatId': null,
      });
    } catch (e) {
      throw Exception('Failed to cleanup presence: ${e.toString()}');
    }
  }
}
