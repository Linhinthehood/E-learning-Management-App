import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/datasources/local/course_local_datasource.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/course/get_student_courses_usecase.dart';
import '../../domain/usecases/course/get_courses_by_semester_usecase.dart';
import '../../domain/usecases/course/create_course_usecase.dart';
import '../../domain/usecases/course/update_course_usecase.dart';
import '../../domain/usecases/course/delete_course_usecase.dart';

/// Provider for course remote data source
final courseRemoteDataSourceProvider = Provider<CourseRemoteDataSource>((ref) {
  return CourseRemoteDataSourceImpl();
});

/// Provider for course local data source
final courseLocalDataSourceProvider = Provider<CourseLocalDataSource>((ref) {
  return CourseLocalDataSourceImpl();
});

/// Provider for course repository
final courseRepositoryProvider = Provider<CourseRepositoryImpl>((ref) {
  return CourseRepositoryImpl(
    remoteDataSource: ref.read(courseRemoteDataSourceProvider),
    localDataSource: ref.read(courseLocalDataSourceProvider),
  );
});

/// Provider for get student courses use case
final getStudentCoursesUseCaseProvider = Provider<GetStudentCoursesUseCase>((
  ref,
) {
  return GetStudentCoursesUseCase(ref.read(courseRepositoryProvider));
});

/// Provider for get courses by semester use case
final getCoursesBySemesterUseCaseProvider =
    Provider<GetCoursesBySemesterUseCase>((ref) {
      return GetCoursesBySemesterUseCase(ref.read(courseRepositoryProvider));
    });

/// Provider for create course use case
final createCourseUseCaseProvider = Provider<CreateCourseUseCase>((ref) {
  return CreateCourseUseCase(ref.read(courseRepositoryProvider));
});

/// Provider for update course use case
final updateCourseUseCaseProvider = Provider<UpdateCourseUseCase>((ref) {
  return UpdateCourseUseCase(ref.read(courseRepositoryProvider));
});

/// Provider for delete course use case
final deleteCourseUseCaseProvider = Provider<DeleteCourseUseCase>((ref) {
  return DeleteCourseUseCase(ref.read(courseRepositoryProvider));
});

/// Course state notifier for instructor - manages courses CRUD
class CourseNotifier extends StateNotifier<AsyncValue<List<CourseEntity>>> {
  final GetCoursesBySemesterUseCase _getCoursesBySemesterUseCase;
  final CreateCourseUseCase _createCourseUseCase;
  final UpdateCourseUseCase _updateCourseUseCase;
  final DeleteCourseUseCase _deleteCourseUseCase;

  CourseNotifier(
    this._getCoursesBySemesterUseCase,
    this._createCourseUseCase,
    this._updateCourseUseCase,
    this._deleteCourseUseCase,
  ) : super(const AsyncValue.loading());

  /// Load courses for a semester
  Future<void> loadCourses(String semesterId) async {
    state = const AsyncValue.loading();
    try {
      final courses = await _getCoursesBySemesterUseCase.execute(semesterId);
      state = AsyncValue.data(courses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new course
  Future<void> createCourse(CourseEntity course) async {
    try {
      await _createCourseUseCase.execute(course);
      await loadCourses(course.semesterId); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing course
  Future<void> updateCourse(CourseEntity course) async {
    try {
      await _updateCourseUseCase.execute(course);
      await loadCourses(course.semesterId); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String courseId, String semesterId) async {
    try {
      await _deleteCourseUseCase.execute(courseId);
      await loadCourses(semesterId); // Reload list
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for course state notifier (for instructor)
final courseProvider =
    StateNotifierProvider<CourseNotifier, AsyncValue<List<CourseEntity>>>((
      ref,
    ) {
      return CourseNotifier(
        ref.read(getCoursesBySemesterUseCaseProvider),
        ref.read(createCourseUseCaseProvider),
        ref.read(updateCourseUseCaseProvider),
        ref.read(deleteCourseUseCaseProvider),
      );
    });

/// Course state notifier - manages student courses for a semester
class StudentCoursesNotifier
    extends StateNotifier<AsyncValue<List<CourseEntity>>> {
  final GetStudentCoursesUseCase _getStudentCoursesUseCase;
  String? _currentStudentId;
  String? _currentSemesterId;

  StudentCoursesNotifier(this._getStudentCoursesUseCase)
    : super(const AsyncValue.loading());

  /// Load courses for a student in a specific semester
  Future<void> loadCourses(String studentId, String semesterId) async {
    if (_currentStudentId == studentId && _currentSemesterId == semesterId) {
      // Already loaded this data, skip
      return;
    }

    _currentStudentId = studentId;
    _currentSemesterId = semesterId;

    state = const AsyncValue.loading();
    try {
      final courses = await _getStudentCoursesUseCase.execute(
        studentId,
        semesterId,
      );
      state = AsyncValue.data(courses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh courses
  Future<void> refresh() async {
    if (_currentStudentId != null && _currentSemesterId != null) {
      _currentStudentId = null;
      _currentSemesterId = null;
      await loadCourses(_currentStudentId!, _currentSemesterId!);
    }
  }
}

/// Provider for student courses state notifier
final studentCoursesProvider =
    StateNotifierProvider<
      StudentCoursesNotifier,
      AsyncValue<List<CourseEntity>>
    >((ref) {
      return StudentCoursesNotifier(ref.read(getStudentCoursesUseCaseProvider));
    });
