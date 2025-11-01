import '../models/user_model.dart';

/// Remote data source for authentication
/// Handles API calls for authentication
abstract class AuthRemoteDataSource {
  Future<UserModel?> login(String email, String password);
  Future<void> logout();
}

/// Implementation of AuthRemoteDataSource
/// TODO: Implement actual API calls (Firebase, REST API, etc.)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel?> login(String email, String password) async {
    // TODO: Implement actual API call
    // Example: Call Firebase Auth, REST API, etc.
    throw UnimplementedError('API call not implemented yet');
  }

  @override
  Future<void> logout() async {
    // TODO: Implement actual logout
    throw UnimplementedError('Logout not implemented yet');
  }
}
