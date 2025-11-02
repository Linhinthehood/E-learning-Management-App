import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

/// Use case for user registration
/// Contains the business logic for user registration
class RegisterUseCase {
  final IAuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  /// Execute the register use case
  /// Returns UserEntity if successful, null if failed
  Future<UserEntity?> execute(
    String email,
    String password,
    String displayName,
    UserRole role,
  ) async {
    // Add business logic validations here
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      throw Exception('Email, password, and display name cannot be empty');
    }

    // Validate email format
    if (!email.contains('@') || !email.contains('.')) {
      throw Exception('Invalid email format');
    }

    // Validate password length
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Validate display name
    if (displayName.length < 2) {
      throw Exception('Display name must be at least 2 characters');
    }

    // Call repository to perform registration
    return await _authRepository.register(email, password, displayName, role);
  }
}
