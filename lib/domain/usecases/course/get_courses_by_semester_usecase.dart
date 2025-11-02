import '../../entities/course_entity.dart';
import '../../repositories/i_course_repository.dart';

/// Use case for getting all courses in a semester
class GetCoursesBySemesterUseCase {
  final ICourseRepository _courseRepository;

  GetCoursesBySemesterUseCase(this._courseRepository);

  /// Execute the use case
  /// Returns list of courses in the given semester
  Future<List<CourseEntity>> execute(String semesterId) async {
    if (semesterId.isEmpty) {
      throw Exception('Semester ID cannot be empty');
    }

    return await _courseRepository.getCoursesBySemester(semesterId);
  }
}

