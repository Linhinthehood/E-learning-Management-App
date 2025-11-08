import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/message_remote_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/i_message_repository.dart';
import './chat_provider.dart';

/// Provider for message remote data source
final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((ref) {
  return MessageRemoteDataSourceImpl();
});

/// Provider for message repository
final messageRepositoryProvider = Provider<IMessageRepository>((ref) {
  return MessageRepositoryImpl(
    remoteDataSource: ref.read(messageRemoteDataSourceProvider),
  );
});

/// Message state notifier - manages messages for a chat
class MessageNotifier extends StateNotifier<AsyncValue<List<MessageEntity>>> {
  final IMessageRepository _repository;
  final Ref _ref;
  String? _currentChatId;

  MessageNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  /// Load messages for a chat
  Future<void> loadMessages(String chatId) async {
    _currentChatId = chatId;
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getMessagesByChat(chatId);
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Send a new message
  Future<void> sendMessage(MessageEntity message) async {
    try {
      final sentMessage = await _repository.sendMessage(message);

      // Update chat metadata with last message
      await _ref.read(chatRepositoryProvider).updateChatMetadata(
            message.chatId,
            message.content,
            message.timestamp,
          );

      // Increment unread count for recipient
      final chat = await _ref.read(chatRepositoryProvider).getChatById(message.chatId);
      if (chat != null) {
        final recipientId = message.senderId == chat.studentId
            ? chat.instructorId
            : chat.studentId;
        await _ref
            .read(chatRepositoryProvider)
            .incrementUnreadCount(message.chatId, recipientId);
      }

      if (_currentChatId != null) {
        await loadMessages(_currentChatId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _repository.markMessageAsRead(chatId, messageId);
      if (_currentChatId != null) {
        await loadMessages(_currentChatId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread message count for a chat
  Future<int> getUnreadMessageCount(String chatId, String userId) async {
    try {
      return await _repository.getUnreadMessageCount(chatId, userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current messages
  Future<void> refresh() async {
    if (_currentChatId != null) {
      await loadMessages(_currentChatId!);
    }
  }
}

/// Provider for message state notifier
final messageProvider = StateNotifierProvider<
    MessageNotifier,
    AsyncValue<List<MessageEntity>>
>((ref) {
  return MessageNotifier(
    ref.read(messageRepositoryProvider),
    ref,
  );
});

/// Provider for real-time message stream
final messageStreamProvider = StreamProvider.family<List<MessageEntity>, String>((
  ref,
  chatId,
) {
  final repository = ref.read(messageRepositoryProvider);
  return repository.listenToMessages(chatId);
});

/// Provider for unread message count
final unreadMessageCountProvider =
    FutureProvider.family<int, ({String chatId, String userId})>((
  ref,
  params,
) async {
  final repository = ref.read(messageRepositoryProvider);
  return await repository.getUnreadMessageCount(params.chatId, params.userId);
});
