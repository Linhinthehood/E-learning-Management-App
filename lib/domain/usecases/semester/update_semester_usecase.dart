import '../../entities/semester_entity.dart';
import '../../repositories/i_semester_repository.dart';

/// Use case for updating an existing semester
class UpdateSemesterUseCase {
  final ISemesterRepository _repository;

  UpdateSemesterUseCase(this._repository);

  Future<void> execute(SemesterEntity semester) async {
    // Business logic validations
    if (semester.name.isEmpty) {
      throw Exception('Semester name cannot be empty');
    }

    if (semester.code.isEmpty) {
      throw Exception('Semester code cannot be empty');
    }

    if (semester.startDate.isAfter(semester.endDate)) {
      throw Exception('Start date must be before end date');
    }

    // Check if code already exists for another semester
    final codeExists = await _repository.semesterCodeExists(
      semester.code,
      excludeId: semester.id,
    );
    if (codeExists) {
      throw Exception('Semester code already exists');
    }

    await _repository.updateSemester(semester);
  }
}
