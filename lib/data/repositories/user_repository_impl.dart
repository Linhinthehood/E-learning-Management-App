import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';

/// Implementation of IUserRepository
class UserRepositoryImpl implements IUserRepository {
  final AuthRemoteDataSource remoteDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<UserEntity> updateUserProfile(String userId, String? avatarUrl) async {
    try {
      final userModel = await remoteDataSource.updateUserProfile(userId, avatarUrl);
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserEntity>> getAllStudents() async {
    try {
      final userModels = await remoteDataSource.getAllStudents();
      return userModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> createStudent({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userModel = await remoteDataSource.createStudent(email, password, displayName);
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity> updateStudent({
    required String userId,
    required String displayName,
    required String email,
  }) async {
    try {
      final userModel = await remoteDataSource.updateStudent(userId, displayName, email);
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteStudent(String userId) async {
    try {
      await remoteDataSource.deleteStudent(userId);
    } catch (e) {
      rethrow;
    }
  }
}

