import '../models/user_model.dart';

/// Local data source for authentication
/// Handles caching user data for offline capability
abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

/// Implementation of AuthLocalDataSource
/// TODO: Implement using Hive or SQLite
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  @override
  Future<UserModel?> getCachedUser() async {
    // TODO: Implement using Hive/SQLite
    throw UnimplementedError('Local storage not implemented yet');
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    // TODO: Implement caching
    throw UnimplementedError('Caching not implemented yet');
  }

  @override
  Future<void> clearCache() async {
    // TODO: Implement cache clearing
    throw UnimplementedError('Cache clearing not implemented yet');
  }
}
