import '../../entities/course_entity.dart';
import '../../repositories/i_course_repository.dart';

/// Use case for updating an existing course
class UpdateCourseUseCase {
  final ICourseRepository _courseRepository;

  UpdateCourseUseCase(this._courseRepository);

  /// Execute the update course use case
  Future<CourseEntity> execute(CourseEntity course) async {
    // Validate course data
    if (course.name.isEmpty) {
      throw Exception('Course name cannot be empty');
    }

    if (course.code.isEmpty) {
      throw Exception('Course code cannot be empty');
    }

    if (course.semesterId.isEmpty) {
      throw Exception('Semester ID cannot be empty');
    }

    if (course.instructorId.isEmpty) {
      throw Exception('Instructor ID cannot be empty');
    }

    if (course.sessions != 10 && course.sessions != 15) {
      throw Exception('Sessions must be either 10 or 15');
    }

    return await _courseRepository.updateCourse(course);
  }
}

