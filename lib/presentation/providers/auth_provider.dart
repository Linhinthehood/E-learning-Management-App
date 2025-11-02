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

  AuthNotifier(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
  ) : super(const AsyncValue.loading()) {
    // Check if user is already logged in on initialization
    _checkCurrentUser();
  }

  /// Check if user is currently logged in
  Future<void> _checkCurrentUser() async {
    try {
      final user = await _getCurrentUserUseCase.execute();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _loginUseCase.execute(email, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
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
      final user = await _registerUseCase.execute(email, password, displayName, role);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      state = const AsyncValue.loading();
      await _logoutUseCase.execute();
      state = const AsyncValue.data(null);
    } catch (e, _) {
      // Even if logout fails, set state to null
      state = const AsyncValue.data(null);
    }
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
      );
    });
