import '../../repositories/i_enrollment_repository.dart';

/// Use case for deleting an enrollment
class DeleteEnrollmentUseCase {
  final IEnrollmentRepository _enrollmentRepository;

  DeleteEnrollmentUseCase(this._enrollmentRepository);

  /// Execute the delete enrollment use case
  Future<void> execute(String enrollmentId) async {
    if (enrollmentId.isEmpty) {
      throw Exception('Enrollment ID cannot be empty');
    }

    return await _enrollmentRepository.deleteEnrollment(enrollmentId);
  }
}

