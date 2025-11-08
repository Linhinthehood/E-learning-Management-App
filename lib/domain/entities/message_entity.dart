/// Message entity for individual chat messages
/// Stored as sub-collection under chats
class MessageEntity {
  final String id;
  final String chatId; // Parent chat ID
  final String senderId; // Who sent the message
  final String content;
  final DateTime timestamp;
  final bool isRead; // Has the message been read by the recipient

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });
}
