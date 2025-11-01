import 'package:hive/hive.dart';
import '../models/user_model.dart';

/// Local data source for authentication
/// Handles caching user data for offline capability using Hive
abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
}

/// Implementation of AuthLocalDataSource using Hive
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userBoxName = 'userBox';
  static const String _userKey = 'current_user';

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final box = Hive.box(_userBoxName);
      final userData = box.get(_userKey);

      if (userData != null && userData is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final box = Hive.box(_userBoxName);
      await box.put(_userKey, user.toJson());
    } catch (e) {
      // Silently fail - offline caching is not critical
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = Hive.box(_userBoxName);
      await box.delete(_userKey);
    } catch (e) {
      // Silently fail
    }
  }
}
