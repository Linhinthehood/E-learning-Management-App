import '../../entities/user_entity.dart';
import '../../repositories/i_user_repository.dart';

/// Use case for updating user profile
class UpdateUserProfileUseCase {
  final IUserRepository _userRepository;

  UpdateUserProfileUseCase(this._userRepository);

  /// Execute the update user profile use case
  /// Note: displayName cannot be updated
  Future<UserEntity> execute(String userId, String? avatarUrl) async {
    if (userId.isEmpty) {
      throw Exception('User ID cannot be empty');
    }

    return await _userRepository.updateUserProfile(userId, avatarUrl);
  }
}

