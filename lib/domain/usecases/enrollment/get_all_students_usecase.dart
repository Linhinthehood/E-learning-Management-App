import '../../entities/user_entity.dart';
import '../../repositories/i_enrollment_repository.dart';

/// Use case for getting all students
class GetAllStudentsUseCase {
  final IEnrollmentRepository _enrollmentRepository;

  GetAllStudentsUseCase(this._enrollmentRepository);

  /// Execute the use case
  /// Returns list of all users with role=student
  Future<List<UserEntity>> execute() async {
    return await _enrollmentRepository.getAllStudents();
  }
}
