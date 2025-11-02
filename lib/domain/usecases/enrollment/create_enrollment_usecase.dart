import '../../entities/enrollment_entity.dart';
import '../../repositories/i_enrollment_repository.dart';

/// Use case for creating a new enrollment
class CreateEnrollmentUseCase {
  final IEnrollmentRepository _enrollmentRepository;

  CreateEnrollmentUseCase(this._enrollmentRepository);

  /// Execute the create enrollment use case
  /// Throws exception if student is already enrolled in the course
  Future<EnrollmentEntity> execute(EnrollmentEntity enrollment) async {
    // Validate enrollment data
    if (enrollment.studentId.isEmpty) {
      throw Exception('Student ID cannot be empty');
    }

    if (enrollment.courseId.isEmpty) {
      throw Exception('Course ID cannot be empty');
    }

    if (enrollment.groupId.isEmpty) {
      throw Exception('Group ID cannot be empty');
    }

    if (enrollment.semesterId.isEmpty) {
      throw Exception('Semester ID cannot be empty');
    }

    // Check if student is already enrolled in this course
    final isEnrolled = await _enrollmentRepository.isStudentEnrolledInCourse(
      enrollment.studentId,
      enrollment.courseId,
    );

    if (isEnrolled) {
      throw Exception('Student is already enrolled in this course. A student can only belong to one group per course.');
    }

    return await _enrollmentRepository.createEnrollment(enrollment);
  }
}

