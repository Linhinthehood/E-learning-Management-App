import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// Remote data source for messages
/// Handles Firestore calls for messages
abstract class MessageRemoteDataSource {
  /// Get all messages for a chat
  Future<List<MessageModel>> getMessagesByChat(String chatId);

  /// Get a single message by ID
  Future<MessageModel?> getMessageById(String chatId, String messageId);

  /// Send a new message
  Future<MessageModel> sendMessage(MessageModel message);

  /// Mark a message as read
  Future<void> markMessageAsRead(String chatId, String messageId);

  /// Get unread messages count for a chat
  Future<int> getUnreadMessageCount(String chatId, String userId);

  /// Listen to new messages in real-time (returns stream)
  Stream<List<MessageModel>> listenToMessages(String chatId);
}

/// Implementation of MessageRemoteDataSource using Firestore
class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<MessageModel>> getMessagesByChat(String chatId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final messages = querySnapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by timestamp ascending (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } catch (e) {
      throw Exception('Failed to get messages: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel?> getMessageById(String chatId, String messageId) async {
    try {
      final docSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return MessageModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get message: ${e.toString()}');
    }
  }

  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      final docRef = await _firestore
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .add(message.toJson());

      final docSnapshot = await docRef.get();
      return MessageModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  @override
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark message as read: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadMessageCount(String chatId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      // Filter messages where the user is NOT the sender
      final unreadMessages = querySnapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
          .where((message) => message.senderId != userId)
          .toList();

      return unreadMessages.length;
    } catch (e) {
      throw Exception('Failed to get unread message count: ${e.toString()}');
    }
  }

  @override
  Stream<List<MessageModel>> listenToMessages(String chatId) {
    try {
      return _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to listen to messages: ${e.toString()}');
    }
  }
}
