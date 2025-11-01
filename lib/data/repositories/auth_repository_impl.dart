import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';

/// Implementation of IAuthRepository
/// This class decides when to use remote or local data sources
class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      // Try to login via remote (API)
      final userModel = await remoteDataSource.login(email, password);

      if (userModel != null) {
        // Cache user data for offline access
        await localDataSource.cacheUser(userModel);
        return userModel.toEntity();
      }

      return null;
    } catch (e) {
      // If remote fails, you could try local cache
      // For login, we typically don't allow offline login
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.clearCache();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      // Try to get from cache first (faster)
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return cachedUser.toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
