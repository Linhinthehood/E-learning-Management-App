import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Local data source for authentication
/// Handles caching user data for offline capability using Hive
abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();

  // Remember me functionality
  Future<void> saveCredentials(String email, String password);
  Future<Map<String, String>?> getCachedCredentials();
  Future<void> clearCredentials();
}

/// Implementation of AuthLocalDataSource using Hive
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userBoxName = 'userBox';
  static const String _userKey = 'current_user';
  static const String _emailKey = 'cached_email';
  static const String _passwordKey = 'cached_password';

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
      debugPrint('🗑️ Hive: Clearing user cache...');
      final box = Hive.box(_userBoxName);
      await box.delete(_userKey);
      debugPrint('✅ Hive: User cache cleared');
    } catch (e) {
      debugPrint('⚠️ Hive: Failed to clear cache: $e');
    }
  }

  @override
  Future<void> saveCredentials(String email, String password) async {
    try {
      debugPrint('💾 Hive: Saving credentials for $email');
      final box = Hive.box(_userBoxName);
      await box.put(_emailKey, email);
      await box.put(_passwordKey, password);
      debugPrint('✅ Hive: Credentials saved');
    } catch (e) {
      debugPrint('⚠️ Hive: Failed to save credentials: $e');
    }
  }

  @override
  Future<Map<String, String>?> getCachedCredentials() async {
    try {
      final box = Hive.box(_userBoxName);
      final email = box.get(_emailKey) as String?;
      final password = box.get(_passwordKey) as String?;

      debugPrint(
        '🔍 Hive: Checking cached credentials - email: $email, hasPassword: ${password != null}',
      );

      if (email != null && password != null) {
        debugPrint('✅ Hive: Found cached credentials');
        return {'email': email, 'password': password};
      }

      debugPrint('ℹ️ Hive: No cached credentials found');
      return null;
    } catch (e) {
      debugPrint('⚠️ Hive: Failed to get cached credentials: $e');
      return null;
    }
  }

  @override
  Future<void> clearCredentials() async {
    try {
      debugPrint('🗑️ Hive: Clearing credentials...');
      final box = Hive.box(_userBoxName);
      await box.delete(_emailKey);
      await box.delete(_passwordKey);
      debugPrint('✅ Hive: Credentials cleared');
    } catch (e) {
      debugPrint('⚠️ Hive: Failed to clear credentials: $e');
    }
  }
}
