import '../../domain/entities/semester_entity.dart';
import '../../domain/repositories/i_semester_repository.dart';
import '../datasources/local/semester_local_datasource.dart';
import '../datasources/models/semester_model.dart';
import '../datasources/remote/semester_remote_datasource.dart';

/// Implementation of ISemesterRepository
class SemesterRepositoryImpl implements ISemesterRepository {
  final SemesterRemoteDataSource remoteDataSource;
  final SemesterLocalDataSource localDataSource;

  SemesterRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<SemesterEntity>> getAllSemesters() async {
    try {
      // Try to get from remote (Firebase)
      final remoteSemesters = await remoteDataSource.getAllSemesters();

      // Cache for offline access
      await localDataSource.cacheSemesters(remoteSemesters);

      return remoteSemesters.map((model) => model.toEntity()).toList();
    } catch (e) {
      // If remote fails, try to get from cache
      try {
        final cachedSemesters = await localDataSource.getCachedSemesters();
        return cachedSemesters.map((model) => model.toEntity()).toList();
      } catch (cacheError) {
        rethrow;
      }
    }
  }

  @override
  Future<SemesterEntity?> getSemesterById(String id) async {
    try {
      final remoteSemester = await remoteDataSource.getSemesterById(id);
      return remoteSemester?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SemesterEntity?> getActiveSemester() async {
    try {
      final allSemesters = await getAllSemesters();

      // Find the semester that is currently active based on dates
      for (var semester in allSemesters) {
        if (semester.isActive) {
          return semester;
        }
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> createSemester(SemesterEntity semester) async {
    try {
      final model = SemesterModel.fromEntity(semester);
      await remoteDataSource.createSemester(model);

      // Update cache
      final allSemesters = await remoteDataSource.getAllSemesters();
      await localDataSource.cacheSemesters(allSemesters);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateSemester(SemesterEntity semester) async {
    try {
      final model = SemesterModel.fromEntity(semester);
      await remoteDataSource.updateSemester(model);

      // Update cache
      final allSemesters = await remoteDataSource.getAllSemesters();
      await localDataSource.cacheSemesters(allSemesters);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteSemester(String id) async {
    try {
      await remoteDataSource.deleteSemester(id);

      // Update cache
      final allSemesters = await remoteDataSource.getAllSemesters();
      await localDataSource.cacheSemesters(allSemesters);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> semesterCodeExists(String code, {String? excludeId}) async {
    try {
      return await remoteDataSource.semesterCodeExists(
        code,
        excludeId: excludeId,
      );
    } catch (e) {
      rethrow;
    }
  }
}
