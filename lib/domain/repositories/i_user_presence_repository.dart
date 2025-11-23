import '../entities/user_presence_entity.dart';

/// UserPresence repository interface
/// This defines the contract that data layer must implement
abstract class IUserPresenceRepository {
  /// Get current presence status for a user
  Future<UserPresenceEntity?> getUserPresence(String userId);

  /// Update user presence status (online/offline/away)
  Future<void> updatePresenceStatus(String userId, String status);

  /// Update last seen timestamp
  Future<void> updateLastSeen(String userId);

  /// Set typing status for a chat
  Future<void> setTypingStatus(String userId, String chatId, bool isTyping);

  /// Listen to user presence changes in real-time (returns stream)
  Stream<UserPresenceEntity?> listenToUserPresence(String userId);

  /// Listen to typing status in a specific chat
  Stream<Map<String, bool>> listenToTypingInChat(String chatId);

  /// Initialize presence for a new user
  Future<void> initializePresence(String userId);

  /// Clean up presence when user logs out
  Future<void> cleanupPresence(String userId);
}
