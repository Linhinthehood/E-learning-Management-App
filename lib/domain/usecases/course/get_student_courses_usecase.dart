import '../../entities/course_entity.dart';
import '../../repositories/i_course_repository.dart';

/// Use case for getting courses that a student is enrolled in
class GetStudentCoursesUseCase {
  final ICourseRepository _courseRepository;

  GetStudentCoursesUseCase(this._courseRepository);

  /// Execute the use case
  /// Returns list of courses the student is enrolled in for the given semester
  Future<List<CourseEntity>> execute(String studentId, String semesterId) async {
    if (studentId.isEmpty || semesterId.isEmpty) {
      throw Exception('Student ID and Semester ID cannot be empty');
    }

    return await _courseRepository.getStudentCourses(studentId, semesterId);
  }
}

