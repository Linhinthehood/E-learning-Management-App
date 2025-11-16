import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../datasources/remote/course_remote_datasource.dart';
import '../datasources/local/course_local_datasource.dart';
import '../datasources/models/course_model.dart';

/// Implementation of ICourseRepository
/// This class decides when to use remote or local data sources
class CourseRepositoryImpl implements ICourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  final CourseLocalDataSource? localDataSource;

  CourseRepositoryImpl({
    required this.remoteDataSource,
    this.localDataSource,
  });

  @override
  Future<List<CourseEntity>> getCoursesBySemester(String semesterId) async {
    try {
      // Try to get from remote first
      final courseModels = await remoteDataSource.getCoursesBySemester(
        semesterId,
      );

      // Cache the data for offline use
      if (localDataSource != null) {
        await localDataSource!.cacheCourses(semesterId, courseModels);
      }

      return courseModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If remote fails, try to get from cache
      if (localDataSource != null) {
        final cachedModels = await localDataSource!.getCachedCourses(semesterId);
        if (cachedModels.isNotEmpty) {
          return cachedModels.map((model) => model.toEntity()).toList();
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<CourseEntity>> getStudentCourses(
    String studentId,
    String semesterId,
  ) async {
    try {
      // Try to get from remote first
      final courseModels = await remoteDataSource.getStudentCourses(
        studentId,
        semesterId,
      );

      // Cache student courses (use student-specific key)
      if (localDataSource != null) {
        await localDataSource!.cacheCourses('${semesterId}_student_$studentId', courseModels);
      }

      return courseModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If remote fails, try to get from cache
      if (localDataSource != null) {
        final cachedModels = await localDataSource!.getCachedCourses('${semesterId}_student_$studentId');
        if (cachedModels.isNotEmpty) {
          return cachedModels.map((model) => model.toEntity()).toList();
        }
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, String>?> getInstructorInfo(String instructorId) async {
    try {
      return await remoteDataSource.getInstructorInfo(instructorId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<CourseEntity?> getCourseById(String courseId) async {
    try {
      final courseModel = await remoteDataSource.getCourseById(courseId);
      return courseModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CourseEntity> createCourse(CourseEntity course) async {
    try {
      final courseModel = CourseModel.fromEntity(course);
      final createdModel = await remoteDataSource.createCourse(courseModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CourseEntity> updateCourse(CourseEntity course) async {
    try {
      final courseModel = CourseModel.fromEntity(course);
      final updatedModel = await remoteDataSource.updateCourse(courseModel);
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    try {
      await remoteDataSource.deleteCourse(courseId);
    } catch (e) {
      rethrow;
    }
  }
}
