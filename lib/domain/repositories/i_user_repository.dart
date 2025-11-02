import '../entities/user_entity.dart';

/// User repository interface
/// This defines the contract that data layer must implement
abstract class IUserRepository {
  /// Update user profile (avatar, etc.)
  /// Note: displayName cannot be updated
  Future<UserEntity> updateUserProfile(String userId, String? avatarUrl);
}

