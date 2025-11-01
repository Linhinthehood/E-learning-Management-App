import '../entities/course_entity.dart';

/// Course repository interface
/// This defines the contract that data layer must implement
abstract class ICourseRepository {
  /// Get all courses for a semester
  Future<List<CourseEntity>> getCoursesBySemester(String semesterId);

  /// Get a single course by ID
  Future<CourseEntity?> getCourseById(String courseId);

  /// Create a new course
  Future<CourseEntity> createCourse(CourseEntity course);

  /// Update an existing course
  Future<CourseEntity> updateCourse(CourseEntity course);

  /// Delete a course
  Future<void> deleteCourse(String courseId);
}
