import '../../entities/semester_entity.dart';
import '../../repositories/i_semester_repository.dart';

/// Use case for creating a new semester
class CreateSemesterUseCase {
  final ISemesterRepository _repository;

  CreateSemesterUseCase(this._repository);

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

    // Check if code already exists
    final codeExists = await _repository.semesterCodeExists(semester.code);
    if (codeExists) {
      throw Exception('Semester code already exists');
    }

    await _repository.createSemester(semester);
  }
}
