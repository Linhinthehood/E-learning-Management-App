import '../entities/user_entity.dart';

/// User repository interface
/// This defines the contract that data layer must implement
abstract class IUserRepository {
  /// Update user profile (avatar, etc.)
  /// Note: displayName cannot be updated
  Future<UserEntity> updateUserProfile(String userId, String? avatarUrl);

  /// Get all students
  Future<List<UserEntity>> getAllStudents();

  /// Create a new student account
  Future<UserEntity> createStudent({
    required String email,
    required String password,
    required String displayName,
  });

  /// Update student information
  Future<UserEntity> updateStudent({
    required String userId,
    required String displayName,
    required String email,
  });

  /// Delete a student account
  Future<void> deleteStudent(String userId);
}
