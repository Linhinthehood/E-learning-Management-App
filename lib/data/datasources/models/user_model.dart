import '../../../domain/entities/user_entity.dart';

/// Data model for User
/// Used to convert between API/Database format and Entity
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.role,
  });

  /// Convert from JSON (API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
    );
  }

  /// Convert to JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role,
    };
  }

  /// Convert to Entity (domain layer)
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role == 'instructor' ? UserRole.instructor : UserRole.student,
    );
  }

  /// Convert from Entity (domain layer)
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      avatarUrl: entity.avatarUrl,
      role: entity.role == UserRole.instructor ? 'instructor' : 'student',
    );
  }
}
