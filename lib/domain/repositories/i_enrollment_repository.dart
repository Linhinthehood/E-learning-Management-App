import '../entities/enrollment_entity.dart';
import '../entities/user_entity.dart';

/// Enrollment repository interface
/// This defines the contract that data layer must implement
abstract class IEnrollmentRepository {
  /// Get all enrollments for a course
  Future<List<EnrollmentEntity>> getEnrollmentsByCourse(String courseId);

  /// Get all enrollments for a student in a semester
  Future<List<EnrollmentEntity>> getEnrollmentsByStudent(String studentId, String semesterId);

  /// Get enrollment for a student in a specific course
  Future<EnrollmentEntity?> getEnrollmentByStudentAndCourse(String studentId, String courseId);

  /// Create a new enrollment
  /// Returns the created enrollment
  /// Throws exception if student is already enrolled in another group for this course
  Future<EnrollmentEntity> createEnrollment(EnrollmentEntity enrollment);

  /// Delete an enrollment
  Future<void> deleteEnrollment(String enrollmentId);

  /// Get all students (users with role=student)
  Future<List<UserEntity>> getAllStudents();

  /// Check if student is already enrolled in the course
  Future<bool> isStudentEnrolledInCourse(String studentId, String courseId);
}

