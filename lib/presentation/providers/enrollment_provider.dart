import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/enrollment_remote_datasource.dart';
import '../../data/repositories/enrollment_repository_impl.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/enrollment/create_enrollment_usecase.dart';
import '../../domain/usecases/enrollment/delete_enrollment_usecase.dart';
import '../../domain/usecases/enrollment/get_enrollments_by_course_usecase.dart';
import '../../domain/usecases/enrollment/get_all_students_usecase.dart';

/// Provider for enrollment remote data source
final enrollmentRemoteDataSourceProvider = Provider<EnrollmentRemoteDataSource>((ref) {
  return EnrollmentRemoteDataSourceImpl();
});

/// Provider for enrollment repository
final enrollmentRepositoryProvider = Provider<EnrollmentRepositoryImpl>((ref) {
  return EnrollmentRepositoryImpl(
    remoteDataSource: ref.read(enrollmentRemoteDataSourceProvider),
  );
});

/// Provider for create enrollment use case
final createEnrollmentUseCaseProvider = Provider<CreateEnrollmentUseCase>((ref) {
  return CreateEnrollmentUseCase(ref.read(enrollmentRepositoryProvider));
});

/// Provider for delete enrollment use case
final deleteEnrollmentUseCaseProvider = Provider<DeleteEnrollmentUseCase>((ref) {
  return DeleteEnrollmentUseCase(ref.read(enrollmentRepositoryProvider));
});

/// Provider for get enrollments by course use case
final getEnrollmentsByCourseUseCaseProvider = Provider<GetEnrollmentsByCourseUseCase>((ref) {
  return GetEnrollmentsByCourseUseCase(ref.read(enrollmentRepositoryProvider));
});

/// Provider for get all students use case
final getAllStudentsUseCaseProvider = Provider<GetAllStudentsUseCase>((ref) {
  return GetAllStudentsUseCase(ref.read(enrollmentRepositoryProvider));
});

/// Enrollment state notifier - manages enrollments for a course
class EnrollmentNotifier extends StateNotifier<AsyncValue<List<EnrollmentEntity>>> {
  final GetEnrollmentsByCourseUseCase _getEnrollmentsByCourseUseCase;
  final CreateEnrollmentUseCase _createEnrollmentUseCase;
  final DeleteEnrollmentUseCase _deleteEnrollmentUseCase;

  EnrollmentNotifier(
    this._getEnrollmentsByCourseUseCase,
    this._createEnrollmentUseCase,
    this._deleteEnrollmentUseCase,
  ) : super(const AsyncValue.loading());

  /// Load enrollments for a course
  Future<void> loadEnrollments(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final enrollments = await _getEnrollmentsByCourseUseCase.execute(courseId);
      state = AsyncValue.data(enrollments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new enrollment
  Future<void> createEnrollment(EnrollmentEntity enrollment) async {
    try {
      await _createEnrollmentUseCase.execute(enrollment);
      await loadEnrollments(enrollment.courseId); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an enrollment
  Future<void> deleteEnrollment(String enrollmentId, String courseId) async {
    try {
      await _deleteEnrollmentUseCase.execute(enrollmentId);
      await loadEnrollments(courseId); // Reload list
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for enrollment state notifier
final enrollmentProvider = StateNotifierProvider<EnrollmentNotifier, AsyncValue<List<EnrollmentEntity>>>((ref) {
  return EnrollmentNotifier(
    ref.read(getEnrollmentsByCourseUseCaseProvider),
    ref.read(createEnrollmentUseCaseProvider),
    ref.read(deleteEnrollmentUseCaseProvider),
  );
});

/// Students state notifier - manages list of all students
class StudentsNotifier extends StateNotifier<AsyncValue<List<UserEntity>>> {
  final GetAllStudentsUseCase _getAllStudentsUseCase;

  StudentsNotifier(this._getAllStudentsUseCase) : super(const AsyncValue.loading()) {
    loadStudents();
  }

  /// Load all students
  Future<void> loadStudents() async {
    state = const AsyncValue.loading();
    try {
      final students = await _getAllStudentsUseCase.execute();
      state = AsyncValue.data(students);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh students list
  Future<void> refresh() async {
    await loadStudents();
  }
}

/// Provider for students state notifier
final studentsProvider = StateNotifierProvider<StudentsNotifier, AsyncValue<List<UserEntity>>>((ref) {
  return StudentsNotifier(ref.read(getAllStudentsUseCaseProvider));
});

