import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

/// Remote data source for chats
/// Handles Firestore calls for chats
abstract class ChatRemoteDataSource {
  /// Get all chats for a user (student or instructor)
  Future<List<ChatModel>> getChatsByUser(String userId);

  /// Get a specific chat between student and instructor
  Future<ChatModel?> getChatById(String chatId);

  /// Get or create a chat between student and instructor
  Future<ChatModel> getOrCreateChat(String studentId, String instructorId);

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

  /// Listen to chats for a user in real-time (returns stream)
  Stream<List<ChatModel>> listenToChatsByUser(String userId);
}

/// Implementation of ChatRemoteDataSource using Firestore
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ChatModel>> getChatsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .get();

      final chats = querySnapshot.docs
          .map((doc) => ChatModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by last message timestamp descending (newest first)
      chats.sort(
        (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
      );

      return chats;
    } catch (e) {
      throw Exception('Failed to get chats: ${e.toString()}');
    }
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final docSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return ChatModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get chat: ${e.toString()}');
    }
  }

  @override
  Future<ChatModel> getOrCreateChat(
    String studentId,
    String instructorId,
  ) async {
    try {
      // Create composite ID
      final chatId = '${studentId}_$instructorId';

      // Check if chat already exists
      final existingChat = await getChatById(chatId);
      if (existingChat != null) {
        return existingChat;
      }

      // Create new chat
      final newChat = ChatModel(
        id: chatId,
        participantIds: [studentId, instructorId],
        studentId: studentId,
        instructorId: instructorId,
        lastMessage: '',
        lastMessageTimestamp: DateTime.now(),
        unreadCountStudent: 0,
        unreadCountInstructor: 0,
      );

      await _firestore.collection('chats').doc(chatId).set(newChat.toJson());

      return newChat;
    } catch (e) {
      throw Exception('Failed to get or create chat: ${e.toString()}');
    }
  }

  @override
  Future<void> updateChatMetadata(
    String chatId,
    String lastMessage,
    DateTime timestamp,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': lastMessage,
        'lastMessageTimestamp': Timestamp.fromDate(timestamp),
      });
    } catch (e) {
      throw Exception('Failed to update chat metadata: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return;

      // Determine which unread count to reset
      final updateData = <String, dynamic>{};
      if (userId == chat.studentId) {
        updateData['unreadCountStudent'] = 0;
      } else if (userId == chat.instructorId) {
        updateData['unreadCountInstructor'] = 0;
      }

      if (updateData.isNotEmpty) {
        await _firestore.collection('chats').doc(chatId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to mark as read: ${e.toString()}');
    }
  }

  @override
  Future<void> incrementUnreadCount(String chatId, String recipientId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return;

      // Determine which unread count to increment
      if (recipientId == chat.studentId) {
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCountStudent': FieldValue.increment(1),
        });
      } else if (recipientId == chat.instructorId) {
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCountInstructor': FieldValue.increment(1),
        });
      }
    } catch (e) {
      throw Exception('Failed to increment unread count: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadChatCount(String userId) async {
    try {
      final chats = await getChatsByUser(userId);

      int unreadCount = 0;
      for (var chat in chats) {
        if (userId == chat.studentId && chat.unreadCountStudent > 0) {
          unreadCount++;
        } else if (userId == chat.instructorId &&
            chat.unreadCountInstructor > 0) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      throw Exception('Failed to get unread chat count: ${e.toString()}');
    }
  }

  @override
  Stream<List<ChatModel>> listenToChatsByUser(String userId) {
    try {
      return _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => ChatModel.fromJson(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to listen to chats: ${e.toString()}');
    }
  }
}
