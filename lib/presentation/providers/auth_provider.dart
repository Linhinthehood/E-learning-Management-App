import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

/// Provider for remote data source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

/// Provider for local data source
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl();
});

/// Provider for auth repository
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    localDataSource: ref.read(authLocalDataSourceProvider),
  );
});

/// Provider for login use case
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

/// Provider for register use case
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

/// Provider for logout use case
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

/// Provider for get current user use case
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

/// Auth state notifier - manages authentication state
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthLocalDataSource _localDataSource;

  AuthNotifier(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._localDataSource,
  ) : super(const AsyncValue.loading()) {
    // Check if user is already logged in on initialization
    _checkCurrentUser();
  }

  /// Check if user is currently logged in
  Future<void> _checkCurrentUser() async {
    try {
      debugPrint('🔍 Checking current user...');

      // First, try to get the currently authenticated user from Firebase
      final user = await _getCurrentUserUseCase.execute();
      if (user != null) {
        debugPrint('✅ Found authenticated user: ${user.email}');
        state = AsyncValue.data(user);
        return;
      }

      debugPrint('❌ No authenticated user found in Firebase Auth');

      // If no user is authenticated, check for cached credentials (Remember Me)
      final credentials = await _localDataSource.getCachedCredentials();
      if (credentials != null) {
        debugPrint('🔑 Found cached credentials, attempting auto-login...');
        // Auto-login with cached credentials
        final email = credentials['email']!;
        final password = credentials['password']!;
        try {
          final loggedInUser = await _loginUseCase.execute(email, password);
          debugPrint('✅ Auto-login successful');
          state = AsyncValue.data(loggedInUser);
        } catch (e) {
          debugPrint('❌ Auto-login failed: $e');
          // Clear invalid credentials
          await _localDataSource.clearCredentials();
          state = const AsyncValue.data(null);
        }
      } else {
        debugPrint('ℹ️ No cached credentials, user needs to login');
        // No cached credentials, user needs to login
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      debugPrint('⚠️ Error in _checkCurrentUser: $e');
      // If auto-login fails, clear cached credentials and show login screen
      await _localDataSource.clearCredentials();
      state = const AsyncValue.data(null);
    }
  }

  /// Login with email and password
  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    debugPrint('🔐 Login called for: $email (rememberMe: $rememberMe)');

    // Clear any previous error state before attempting login
    state = const AsyncValue.loading();

    try {
      debugPrint('🔄 Executing login use case...');
      final user = await _loginUseCase.execute(email, password);
      debugPrint('✅ Login successful: ${user?.email}');

      // Save credentials if remember me is checked
      if (rememberMe) {
        debugPrint('💾 Saving credentials for remember me');
        await _localDataSource.saveCredentials(email, password);
      } else {
        debugPrint(
          '🗑️ Clearing any cached credentials (remember me not checked)',
        );
        // Clear any existing cached credentials if remember me is not checked
        await _localDataSource.clearCredentials();
      }

      state = AsyncValue.data(user);
      debugPrint('✅ Login state updated');
    } catch (e, stack) {
      debugPrint('❌ Login failed: $e');
      // Clear credentials on login failure to prevent auto-login issues
      await _localDataSource.clearCredentials();
      state = AsyncValue.error(e, stack);
    }
  }

  /// Register new user with email, password, display name and role
  Future<void> register(
    String email,
    String password,
    String displayName,
    UserRole role,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = await _registerUseCase.execute(
        email,
        password,
        displayName,
        role,
      );
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      debugPrint('🚪 Logout called');
      // Set loading state
      state = const AsyncValue.loading();

      debugPrint('🔄 Logging out from Firebase...');
      // Logout from Firebase
      await _logoutUseCase.execute();

      debugPrint('🗑️ Clearing all cached data...');
      // Clear all cached data
      await _localDataSource.clearCredentials();
      await _localDataSource.clearCache();

      debugPrint('✅ Logout complete, setting state to null');
      // Set state to null (not logged in)
      state = const AsyncValue.data(null);
    } catch (e, _) {
      debugPrint('⚠️ Logout error: $e');
      // Even if logout fails, clear all data and set state to null
      await _localDataSource.clearCredentials();
      await _localDataSource.clearCache();
      state = const AsyncValue.data(null);
    }
  }

  /// Clear any error state (useful after showing an error message)
  void clearError() {
    // If current state is error, reset to null (not logged in)
    state.whenOrNull(error: (_, __) => state = const AsyncValue.data(null));
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    await _checkCurrentUser();
  }
}

/// Provider for auth state notifier
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
      return AuthNotifier(
        ref.read(loginUseCaseProvider),
        ref.read(registerUseCaseProvider),
        ref.read(logoutUseCaseProvider),
        ref.read(getCurrentUserUseCaseProvider),
        ref.read(authLocalDataSourceProvider),
      );
    });
