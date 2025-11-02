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
  Future<UserEntity?> register(
    String email,
    String password,
    String displayName,
    UserRole role,
  ) async {
    try {
      // Register via remote (Firebase)
      final roleString = role == UserRole.instructor ? 'instructor' : 'student';
      final userModel = await remoteDataSource.register(
        email,
        password,
        displayName,
        roleString,
      );

      if (userModel != null) {
        // Cache user data for offline access
        await localDataSource.cacheUser(userModel);
        return userModel.toEntity();
      }

      return null;
    } catch (e) {
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
      // Check Firebase Auth first
      final currentUser = await remoteDataSource.getCurrentUser();
      if (currentUser != null) {
        // Cache for offline access
        await localDataSource.cacheUser(currentUser);
        return currentUser.toEntity();
      }
      
      // If Firebase Auth has no user, clear cache
      await localDataSource.clearCache();
      return null;
    } catch (e) {
      // On error, clear cache and return null
      await localDataSource.clearCache();
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
