import '../../repositories/i_semester_repository.dart';

/// Use case for deleting a semester
class DeleteSemesterUseCase {
  final ISemesterRepository _repository;

  DeleteSemesterUseCase(this._repository);

  Future<void> execute(String semesterId) async {
    if (semesterId.isEmpty) {
      throw Exception('Semester ID cannot be empty');
    }

    // TODO: Add check if semester has associated courses
    // If it does, prevent deletion or cascade delete

    await _repository.deleteSemester(semesterId);
  }
}
