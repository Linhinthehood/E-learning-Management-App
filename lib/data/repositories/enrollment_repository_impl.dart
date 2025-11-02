import '../../domain/entities/enrollment_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_enrollment_repository.dart';
import '../datasources/remote/enrollment_remote_datasource.dart';
import '../datasources/models/enrollment_model.dart';

/// Implementation of IEnrollmentRepository
class EnrollmentRepositoryImpl implements IEnrollmentRepository {
  final EnrollmentRemoteDataSource remoteDataSource;

  EnrollmentRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<EnrollmentEntity>> getEnrollmentsByCourse(String courseId) async {
    try {
      final enrollmentModels = await remoteDataSource.getEnrollmentsByCourse(courseId);
      return enrollmentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<EnrollmentEntity>> getEnrollmentsByStudent(String studentId, String semesterId) async {
    try {
      final enrollmentModels = await remoteDataSource.getEnrollmentsByStudent(studentId, semesterId);
      return enrollmentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EnrollmentEntity?> getEnrollmentByStudentAndCourse(String studentId, String courseId) async {
    try {
      final enrollmentModel = await remoteDataSource.getEnrollmentByStudentAndCourse(studentId, courseId);
      return enrollmentModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<EnrollmentEntity> createEnrollment(EnrollmentEntity enrollment) async {
    try {
      final enrollmentModel = EnrollmentModel.fromEntity(enrollment);
      final createdModel = await remoteDataSource.createEnrollment(enrollmentModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteEnrollment(String enrollmentId) async {
    try {
      await remoteDataSource.deleteEnrollment(enrollmentId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserEntity>> getAllStudents() async {
    try {
      final userModels = await remoteDataSource.getAllStudents();
      return userModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isStudentEnrolledInCourse(String studentId, String courseId) async {
    try {
      return await remoteDataSource.isStudentEnrolledInCourse(studentId, courseId);
    } catch (e) {
      return false;
    }
  }
}

