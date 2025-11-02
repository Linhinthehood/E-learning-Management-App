import '../../entities/enrollment_entity.dart';
import '../../repositories/i_enrollment_repository.dart';

/// Use case for getting all enrollments for a course
class GetEnrollmentsByCourseUseCase {
  final IEnrollmentRepository _enrollmentRepository;

  GetEnrollmentsByCourseUseCase(this._enrollmentRepository);

  /// Execute the use case
  /// Returns list of enrollments for the given course
  Future<List<EnrollmentEntity>> execute(String courseId) async {
    if (courseId.isEmpty) {
      throw Exception('Course ID cannot be empty');
    }

    return await _enrollmentRepository.getEnrollmentsByCourse(courseId);
  }
}
