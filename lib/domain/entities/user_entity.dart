/// User entity representing both Instructor and Student roles
class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final UserRole role;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.role,
  });
}

enum UserRole { instructor, student }
