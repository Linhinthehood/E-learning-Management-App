import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/repositories/i_chat_repository.dart';

/// Provider for chat remote data source
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl();
});

/// Provider for chat repository
final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  return ChatRepositoryImpl(
    remoteDataSource: ref.read(chatRemoteDataSourceProvider),
  );
});

/// Chat state notifier - manages chats for a user
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatEntity>>> {
  final IChatRepository _repository;
  String? _currentUserId;

  ChatNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load chats for a user
  Future<void> loadChats(String userId) async {
    _currentUserId = userId;
    state = const AsyncValue.loading();
    try {
      final chats = await _repository.getChatsByUser(userId);
      state = AsyncValue.data(chats);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Get or create a chat between student and instructor
  Future<ChatEntity> getOrCreateChat(
    String studentId,
    String instructorId,
  ) async {
    try {
      final chat = await _repository.getOrCreateChat(studentId, instructorId);

      // Refresh chat list if currently loaded
      if (_currentUserId != null) {
        await loadChats(_currentUserId!);
      }

      return chat;
    } catch (e) {
      rethrow;
    }
  }

  /// Update chat metadata (after sending a message)
  Future<void> updateChatMetadata(
    String chatId,
    String lastMessage,
    DateTime timestamp,
  ) async {
    try {
      await _repository.updateChatMetadata(chatId, lastMessage, timestamp);

      // Refresh chat list
      if (_currentUserId != null) {
        await loadChats(_currentUserId!);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark chat as read for a user
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _repository.markAsRead(chatId, userId);

      // Refresh chat list
      if (_currentUserId != null) {
        await loadChats(_currentUserId!);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get unread chat count for a user
  Future<int> getUnreadChatCount(String userId) async {
    try {
      return await _repository.getUnreadChatCount(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current chats
  Future<void> refresh() async {
    if (_currentUserId != null) {
      await loadChats(_currentUserId!);
    }
  }
}

/// Provider for chat state notifier
final chatProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatEntity>>>((ref) {
      return ChatNotifier(ref.read(chatRepositoryProvider));
    });

/// Provider for fetching a single chat by ID
final chatByIdProvider = FutureProvider.family<ChatEntity?, String>((
  ref,
  chatId,
) async {
  final repository = ref.read(chatRepositoryProvider);
  return await repository.getChatById(chatId);
});

/// Provider for unread chat count
final unreadChatCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final repository = ref.read(chatRepositoryProvider);
  return await repository.getUnreadChatCount(userId);
});
