import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/remote/chat_remote_datasource.dart';


/// Implementation of IChatRepository
/// Handles conversion between models and entities
class ChatRepositoryImpl implements IChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ChatEntity>> getChatsByUser(String userId) async {
    try {
      final chatModels = await remoteDataSource.getChatsByUser(userId);
      return chatModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ChatEntity?> getChatById(String chatId) async {
    try {
      final chatModel = await remoteDataSource.getChatById(chatId);
      return chatModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ChatEntity> getOrCreateChat(String studentId, String instructorId) async {
    try {
      final chatModel = await remoteDataSource.getOrCreateChat(
        studentId,
        instructorId,
      );
      return chatModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateChatMetadata(
    String chatId,
    String lastMessage,
    DateTime timestamp,
  ) async {
    try {
      await remoteDataSource.updateChatMetadata(chatId, lastMessage, timestamp);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await remoteDataSource.markAsRead(chatId, userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> incrementUnreadCount(String chatId, String recipientId) async {
    try {
      await remoteDataSource.incrementUnreadCount(chatId, recipientId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> getUnreadChatCount(String userId) async {
    try {
      return await remoteDataSource.getUnreadChatCount(userId);
    } catch (e) {
      rethrow;
    }
  }
}
