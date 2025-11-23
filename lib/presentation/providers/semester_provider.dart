import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/semester_local_datasource.dart';
import '../../data/datasources/remote/semester_remote_datasource.dart';
import '../../data/repositories/semester_repository_impl.dart';
import '../../domain/entities/semester_entity.dart';
import '../../domain/usecases/semester/create_semester_usecase.dart';
import '../../domain/usecases/semester/delete_semester_usecase.dart';
import '../../domain/usecases/semester/get_all_semesters_usecase.dart';
import '../../domain/usecases/semester/update_semester_usecase.dart';
import 'course_provider.dart';

/// Provider for remote data source
final semesterRemoteDataSourceProvider = Provider<SemesterRemoteDataSource>((
  ref,
) {
  return SemesterRemoteDataSourceImpl();
});

/// Provider for local data source
final semesterLocalDataSourceProvider = Provider<SemesterLocalDataSource>((
  ref,
) {
  return SemesterLocalDataSourceImpl();
});

/// Provider for semester repository
final semesterRepositoryProvider = Provider<SemesterRepositoryImpl>((ref) {
  return SemesterRepositoryImpl(
    remoteDataSource: ref.read(semesterRemoteDataSourceProvider),
    localDataSource: ref.read(semesterLocalDataSourceProvider),
  );
});

/// Provider for get all semesters use case
final getAllSemestersUseCaseProvider = Provider<GetAllSemestersUseCase>((ref) {
  return GetAllSemestersUseCase(ref.read(semesterRepositoryProvider));
});

/// Provider for create semester use case
final createSemesterUseCaseProvider = Provider<CreateSemesterUseCase>((ref) {
  return CreateSemesterUseCase(ref.read(semesterRepositoryProvider));
});

/// Provider for update semester use case
final updateSemesterUseCaseProvider = Provider<UpdateSemesterUseCase>((ref) {
  return UpdateSemesterUseCase(ref.read(semesterRepositoryProvider));
});

/// Provider for delete semester use case
final deleteSemesterUseCaseProvider = Provider<DeleteSemesterUseCase>((ref) {
  return DeleteSemesterUseCase(
    ref.read(semesterRepositoryProvider),
    ref.read(courseRepositoryProvider),
  );
});

/// Semester state notifier - manages semester state
class SemesterNotifier extends StateNotifier<AsyncValue<List<SemesterEntity>>> {
  final GetAllSemestersUseCase _getAllSemestersUseCase;
  final CreateSemesterUseCase _createSemesterUseCase;
  final UpdateSemesterUseCase _updateSemesterUseCase;
  final DeleteSemesterUseCase _deleteSemesterUseCase;

  SemesterNotifier(
    this._getAllSemestersUseCase,
    this._createSemesterUseCase,
    this._updateSemesterUseCase,
    this._deleteSemesterUseCase,
  ) : super(const AsyncValue.loading()) {
    loadSemesters();
  }

  /// Load all semesters
  Future<void> loadSemesters() async {
    state = const AsyncValue.loading();
    try {
      final semesters = await _getAllSemestersUseCase.execute();
      state = AsyncValue.data(semesters);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new semester
  Future<void> createSemester(SemesterEntity semester) async {
    try {
      await _createSemesterUseCase.execute(semester);
      await loadSemesters(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing semester
  Future<void> updateSemester(SemesterEntity semester) async {
    try {
      await _updateSemesterUseCase.execute(semester);
      await loadSemesters(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a semester
  Future<void> deleteSemester(String id) async {
    try {
      await _deleteSemesterUseCase.execute(id);
      await loadSemesters(); // Reload list
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for semester state notifier
final semesterProvider =
    StateNotifierProvider<SemesterNotifier, AsyncValue<List<SemesterEntity>>>((
      ref,
    ) {
      return SemesterNotifier(
        ref.read(getAllSemestersUseCaseProvider),
        ref.read(createSemesterUseCaseProvider),
        ref.read(updateSemesterUseCaseProvider),
        ref.read(deleteSemesterUseCaseProvider),
      );
    });
