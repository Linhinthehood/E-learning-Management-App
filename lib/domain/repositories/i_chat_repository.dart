import '../entities/chat_entity.dart';

/// Chat repository interface
/// This defines the contract that data layer must implement
abstract class IChatRepository {
  /// Get all chats for a user (student or instructor)
  Future<List<ChatEntity>> getChatsByUser(String userId);

  /// Get a specific chat between student and instructor
  Future<ChatEntity?> getChatById(String chatId);

  /// Get or create a chat between student and instructor
  Future<ChatEntity> getOrCreateChat(String studentId, String instructorId);

  /// Update chat metadata (last message, timestamp)
  Future<void> updateChatMetadata(
    String chatId,
    String lastMessage,
    DateTime timestamp,
  );

  /// Mark messages as read for a user
  Future<void> markAsRead(String chatId, String userId);

  /// Increment unread count for a user
  Future<void> incrementUnreadCount(String chatId, String recipientId);

  /// Get unread chat count for a user
  Future<int> getUnreadChatCount(String userId);
}
