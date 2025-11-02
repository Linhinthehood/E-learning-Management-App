import '../../repositories/i_course_repository.dart';

/// Use case for deleting a course
class DeleteCourseUseCase {
  final ICourseRepository _courseRepository;

  DeleteCourseUseCase(this._courseRepository);

  /// Execute the delete course use case
  Future<void> execute(String courseId) async {
    if (courseId.isEmpty) {
      throw Exception('Course ID cannot be empty');
    }

    return await _courseRepository.deleteCourse(courseId);
  }
}
