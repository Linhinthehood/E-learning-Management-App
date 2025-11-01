import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

/// Use case for getting the current logged-in user
class GetCurrentUserUseCase {
  final IAuthRepository _authRepository;

  GetCurrentUserUseCase(this._authRepository);

  /// Execute the get current user use case
  /// Returns UserEntity if user is logged in, null otherwise
  Future<UserEntity?> execute() async {
    return await _authRepository.getCurrentUser();
  }
}
