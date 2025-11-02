import '../entities/user_entity.dart';

/// Authentication repository interface
/// This defines the contract that data layer must implement
abstract class IAuthRepository {
  /// Login with email and password
  Future<UserEntity?> login(String email, String password);

  /// Register new user with email and password
  Future<UserEntity?> register(String email, String password, String displayName, UserRole role);

  /// Logout current user
  Future<void> logout();

  /// Get currently logged in user
  Future<UserEntity?> getCurrentUser();

  /// Check if user is logged in
  Future<bool> isLoggedIn();
}
