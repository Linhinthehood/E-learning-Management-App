import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

/// Use case for user login
/// Contains the business logic for authentication
class LoginUseCase {
  final IAuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  /// Execute the login use case
  /// Returns UserEntity if successful, null if failed
  Future<UserEntity?> execute(String email, String password) async {
    // Add business logic validations here
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    // Call repository to perform login
    return await _authRepository.login(email, password);
  }
}
