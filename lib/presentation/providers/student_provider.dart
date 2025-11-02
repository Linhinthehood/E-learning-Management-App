import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_user_repository.dart';
import 'auth_provider.dart';

/// Provider for user repository (student management)
final studentRepositoryProvider = Provider<IUserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
  );
});

/// State notifier for student management
class StudentNotifier extends StateNotifier<AsyncValue<List<UserEntity>>> {
  final IUserRepository _repository;

  StudentNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Load students on initialization
    loadStudents();
  }

  /// Load all students
  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final students = await _repository.getAllStudents();
      state = AsyncValue.data(students);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new student
  Future<void> createStudent({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _repository.createStudent(
        email: email,
        password: password,
        displayName: displayName,
      );
      // Reload students after creation
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }

  /// Update a student
  Future<void> updateStudent({
    required String userId,
    required String displayName,
    required String email,
  }) async {
    try {
      await _repository.updateStudent(
        userId: userId,
        displayName: displayName,
        email: email,
      );
      // Reload students after update
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a student
  Future<void> deleteStudent(String userId) async {
    try {
      await _repository.deleteStudent(userId);
      // Reload students after deletion
      await loadStudents();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for student notifier
final studentProvider =
    StateNotifierProvider<StudentNotifier, AsyncValue<List<UserEntity>>>((ref) {
      return StudentNotifier(ref.read(studentRepositoryProvider));
    });
