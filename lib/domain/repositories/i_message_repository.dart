import '../entities/message_entity.dart';

/// Message repository interface
/// This defines the contract that data layer must implement
abstract class IMessageRepository {
  /// Get all messages for a chat
  Future<List<MessageEntity>> getMessagesByChat(String chatId);

  /// Get a single message by ID
  Future<MessageEntity?> getMessageById(String chatId, String messageId);

  /// Send a new message
  Future<MessageEntity> sendMessage(MessageEntity message);

  /// Mark a message as read
  Future<void> markMessageAsRead(String chatId, String messageId);

  /// Get unread messages count for a chat
  Future<int> getUnreadMessageCount(String chatId, String userId);

  /// Listen to new messages in real-time (returns stream)
  Stream<List<MessageEntity>> listenToMessages(String chatId);
}
