import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../datasources/remote/course_remote_datasource.dart';
import '../datasources/models/course_model.dart';

/// Implementation of ICourseRepository
/// This class decides when to use remote or local data sources
class CourseRepositoryImpl implements ICourseRepository {
  final CourseRemoteDataSource remoteDataSource;

  CourseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseEntity>> getCoursesBySemester(String semesterId) async {
    try {
      final courseModels = await remoteDataSource.getCoursesBySemester(
        semesterId,
      );
      return courseModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CourseEntity>> getStudentCourses(
    String studentId,
    String semesterId,
  ) async {
    try {
      final courseModels = await remoteDataSource.getStudentCourses(
        studentId,
        semesterId,
      );
      return courseModels.map((model) => model.toEntity()).toList();
    } catch (e) {
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
