import '../repositories/i_auth_repository.dart';

/// Use case for user logout
class LogoutUseCase {
  final IAuthRepository _authRepository;

  LogoutUseCase(this._authRepository);

  /// Execute the logout use case
  Future<void> execute() async {
    await _authRepository.logout();
  }
}
