import '../../entities/semester_entity.dart';
import '../../repositories/i_semester_repository.dart';

/// Use case for getting all semesters
class GetAllSemestersUseCase {
  final ISemesterRepository _repository;

  GetAllSemestersUseCase(this._repository);

  Future<List<SemesterEntity>> execute() async {
    return await _repository.getAllSemesters();
  }
}
