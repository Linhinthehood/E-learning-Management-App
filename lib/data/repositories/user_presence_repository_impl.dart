import '../../domain/entities/user_presence_entity.dart';
import '../../domain/repositories/i_user_presence_repository.dart';
import '../datasources/remote/user_presence_remote_datasource.dart';

/// Implementation of IUserPresenceRepository
/// Handles conversion between models and entities
class UserPresenceRepositoryImpl implements IUserPresenceRepository {
  final UserPresenceRemoteDataSource remoteDataSource;

  UserPresenceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserPresenceEntity?> getUserPresence(String userId) async {
    try {
      final presenceModel = await remoteDataSource.getUserPresence(userId);
      return presenceModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePresenceStatus(String userId, String status) async {
    try {
      await remoteDataSource.updatePresenceStatus(userId, status);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    try {
      await remoteDataSource.updateLastSeen(userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setTypingStatus(
    String userId,
    String chatId,
    bool isTyping,
  ) async {
    try {
      await remoteDataSource.setTypingStatus(userId, chatId, isTyping);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<UserPresenceEntity?> listenToUserPresence(String userId) {
    try {
      return remoteDataSource
          .listenToUserPresence(userId)
          .map((model) => model?.toEntity());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<Map<String, bool>> listenToTypingInChat(String chatId) {
    try {
      return remoteDataSource.listenToTypingInChat(chatId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> initializePresence(String userId) async {
    try {
      await remoteDataSource.initializePresence(userId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> cleanupPresence(String userId) async {
    try {
      await remoteDataSource.cleanupPresence(userId);
    } catch (e) {
      rethrow;
    }
  }
}
