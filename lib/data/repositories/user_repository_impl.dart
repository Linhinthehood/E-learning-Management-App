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
}

