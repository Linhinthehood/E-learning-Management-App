import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/i_message_repository.dart';
import '../datasources/remote/message_remote_datasource.dart';
import '../datasources/models/message_model.dart';

/// Implementation of IMessageRepository
/// Handles conversion between models and entities
class MessageRepositoryImpl implements IMessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MessageEntity>> getMessagesByChat(String chatId) async {
    try {
      final messageModels = await remoteDataSource.getMessagesByChat(chatId);
      return messageModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MessageEntity?> getMessageById(String chatId, String messageId) async {
    try {
      final messageModel = await remoteDataSource.getMessageById(
        chatId,
        messageId,
      );
      return messageModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MessageEntity> sendMessage(MessageEntity message) async {
    try {
      final messageModel = MessageModel.fromEntity(message);
      final sentModel = await remoteDataSource.sendMessage(messageModel);
      return sentModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await remoteDataSource.markMessageAsRead(chatId, messageId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> getUnreadMessageCount(String chatId, String userId) async {
    try {
      return await remoteDataSource.getUnreadMessageCount(chatId, userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<MessageEntity>> listenToMessages(String chatId) {
    try {
      return remoteDataSource
          .listenToMessages(chatId)
          .map(
            (messageModels) =>
                messageModels.map((model) => model.toEntity()).toList(),
          );
    } catch (e) {
      rethrow;
    }
  }
}
