import 'package:flutter_test/flutter_test.dart';
import 'package:e_learning_management_app/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('should create instructor user with valid data', () {
      // Act
      final user = UserEntity(
        uid: 'user1',
        email: 'instructor@test.com',
        displayName: 'Test Instructor',
        role: UserRole.instructor,
      );

      // Assert
      expect(user.uid, 'user1');
      expect(user.email, 'instructor@test.com');
      expect(user.displayName, 'Test Instructor');
      expect(user.role, UserRole.instructor);
    });

    test('should create student user with valid data', () {
      // Act
      final user = UserEntity(
        uid: 'user2',
        email: 'student@test.com',
        displayName: 'Test Student',
        role: UserRole.student,
      );

      // Assert
      expect(user.uid, 'user2');
      expect(user.email, 'student@test.com');
      expect(user.displayName, 'Test Student');
      expect(user.role, UserRole.student);
    });

    test('should differentiate between instructor and student roles', () {
      // Arrange
      final instructor = UserEntity(
        uid: 'i1',
        email: 'ins@test.com',
        displayName: 'Instructor',
        role: UserRole.instructor,
      );

      final student = UserEntity(
        uid: 's1',
        email: 'stu@test.com',
        displayName: 'Student',
        role: UserRole.student,
      );

      // Act & Assert
      expect(instructor.role, UserRole.instructor);
      expect(student.role, UserRole.student);
      expect(instructor.role, isNot(student.role));
    });

    test('should handle optional avatar URL', () {
      // Act
      final userWithAvatar = UserEntity(
        uid: 'u1',
        email: 'user@test.com',
        displayName: 'User',
        role: UserRole.student,
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      final userWithoutAvatar = UserEntity(
        uid: 'u2',
        email: 'user2@test.com',
        displayName: 'User 2',
        role: UserRole.student,
      );

      // Assert
      expect(userWithAvatar.avatarUrl, 'https://example.com/avatar.jpg');
      expect(userWithoutAvatar.avatarUrl, null);
    });

    test('should have all required fields', () {
      // Act
      final user = UserEntity(
        uid: 'user1',
        email: 'test@example.com',
        displayName: 'Test User',
        role: UserRole.student,
      );

      // Assert
      expect(user.uid, isNotEmpty);
      expect(user.email, isNotEmpty);
      expect(user.displayName, isNotEmpty);
      expect(user.role, isNotNull);
    });
  });
}
