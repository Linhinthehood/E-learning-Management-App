import '../entities/semester_entity.dart';

/// Repository interface for Semester operations
abstract class ISemesterRepository {
  /// Get all semesters
  Future<List<SemesterEntity>> getAllSemesters();

  /// Get semester by ID
  Future<SemesterEntity?> getSemesterById(String id);

  /// Get currently active semester
  Future<SemesterEntity?> getActiveSemester();

  /// Create a new semester
  Future<void> createSemester(SemesterEntity semester);

  /// Update an existing semester
  Future<void> updateSemester(SemesterEntity semester);

  /// Delete a semester
  Future<void> deleteSemester(String id);

  /// Check if semester code already exists
  Future<bool> semesterCodeExists(String code, {String? excludeId});
}
