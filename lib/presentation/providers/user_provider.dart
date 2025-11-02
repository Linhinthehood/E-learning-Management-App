import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/user/update_user_profile_usecase.dart';
import 'auth_provider.dart';

/// Provider for auth remote data source (used for user updates)
final userRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return ref.read(authRemoteDataSourceProvider);
});

/// Provider for user repository
final userRepositoryProvider = Provider<UserRepositoryImpl>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.read(userRemoteDataSourceProvider),
  );
});

/// Provider for update user profile use case
final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>((
  ref,
) {
  return UpdateUserProfileUseCase(ref.read(userRepositoryProvider));
});

/// User profile state notifier - manages user profile updates
class UserProfileNotifier extends StateNotifier<AsyncValue<UserEntity>> {
  final UpdateUserProfileUseCase _updateUserProfileUseCase;

  UserProfileNotifier(this._updateUserProfileUseCase)
    : super(const AsyncValue.loading());

  /// Update user profile (avatar URL)
  Future<void> updateProfile(String userId, String? avatarUrl) async {
    state = const AsyncValue.loading();
    try {
      final updatedUser = await _updateUserProfileUseCase.execute(
        userId,
        avatarUrl,
      );
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for user profile state notifier
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserEntity>>((ref) {
      return UserProfileNotifier(ref.read(updateUserProfileUseCaseProvider));
    });
