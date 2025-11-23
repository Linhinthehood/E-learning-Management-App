import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/user_presence_remote_datasource.dart';
import '../../data/repositories/user_presence_repository_impl.dart';
import '../../domain/entities/user_presence_entity.dart';
import '../../domain/repositories/i_user_presence_repository.dart';

/// Provider for user presence remote data source
final userPresenceRemoteDataSourceProvider =
    Provider<UserPresenceRemoteDataSource>((ref) {
      return UserPresenceRemoteDataSourceImpl();
    });

/// Provider for user presence repository
final userPresenceRepositoryProvider = Provider<IUserPresenceRepository>((ref) {
  return UserPresenceRepositoryImpl(
    remoteDataSource: ref.read(userPresenceRemoteDataSourceProvider),
  );
});

/// User presence state notifier - manages user presence status
class UserPresenceNotifier
    extends StateNotifier<AsyncValue<UserPresenceEntity?>> {
  final IUserPresenceRepository _repository;

  UserPresenceNotifier(this._repository) : super(const AsyncValue.loading());

  /// Get user presence
  Future<void> getUserPresence(String userId) async {
    state = const AsyncValue.loading();
    try {
      final presence = await _repository.getUserPresence(userId);
      state = AsyncValue.data(presence);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update presence status (online/offline/away)
  Future<void> updatePresenceStatus(String userId, String status) async {
    try {
      await _repository.updatePresenceStatus(userId, status);
      await getUserPresence(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen(String userId) async {
    try {
      await _repository.updateLastSeen(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Set typing status for a chat
  Future<void> setTypingStatus(
    String userId,
    String chatId,
    bool isTyping,
  ) async {
    try {
      await _repository.setTypingStatus(userId, chatId, isTyping);
    } catch (e) {
      rethrow;
    }
  }

  /// Initialize presence for a new user
  Future<void> initializePresence(String userId) async {
    try {
      await _repository.initializePresence(userId);
      await getUserPresence(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Clean up presence when user logs out
  Future<void> cleanupPresence(String userId) async {
    try {
      await _repository.cleanupPresence(userId);
      state = const AsyncValue.data(null);
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for user presence state notifier
final userPresenceProvider =
    StateNotifierProvider<
      UserPresenceNotifier,
      AsyncValue<UserPresenceEntity?>
    >((ref) {
      return UserPresenceNotifier(ref.read(userPresenceRepositoryProvider));
    });

/// Provider for real-time user presence stream
final userPresenceStreamProvider =
    StreamProvider.family<UserPresenceEntity?, String>((ref, userId) {
      final repository = ref.read(userPresenceRepositoryProvider);
      return repository.listenToUserPresence(userId);
    });

/// Provider for real-time typing status in a chat
final typingStatusStreamProvider =
    StreamProvider.family<Map<String, bool>, String>((ref, chatId) {
      final repository = ref.read(userPresenceRepositoryProvider);
      return repository.listenToTypingInChat(chatId);
    });
