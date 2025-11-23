import '../../repositories/i_semester_repository.dart';
import '../../repositories/i_course_repository.dart';

/// Use case for deleting a semester
class DeleteSemesterUseCase {
  final ISemesterRepository _repository;
  final ICourseRepository _courseRepository;

  DeleteSemesterUseCase(this._repository, this._courseRepository);

  Future<void> execute(String semesterId) async {
    if (semesterId.isEmpty) {
      throw Exception('Semester ID cannot be empty');
    }

    // Check if semester has associated courses
    final courses = await _courseRepository.getCoursesBySemester(semesterId);

    if (courses.isNotEmpty) {
      throw Exception(
        'Cannot delete semester: Semester has ${courses.length} course(s) associated. '
        'Please delete or reassign all courses before deleting the semester.',
      );
    }

    await _repository.deleteSemester(semesterId);
  }
}
