import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/repositories/i_assignment_submission_repository.dart';
import '../datasources/remote/assignment_submission_remote_datasource.dart';
import '../datasources/models/assignment_submission_model.dart';

/// Implementation of IAssignmentSubmissionRepository
class AssignmentSubmissionRepositoryImpl
    implements IAssignmentSubmissionRepository {
  final AssignmentSubmissionRemoteDatasource _remoteDatasource;

  AssignmentSubmissionRepositoryImpl({
    required AssignmentSubmissionRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<void> createSubmission(AssignmentSubmissionEntity submission) async {
    try {
      final model = AssignmentSubmissionModel.fromEntity(submission);
      await _remoteDatasource.createSubmission(model);
    } catch (e) {
      throw Exception('Failed to create submission: ${e.toString()}');
    }
  }

  @override
  Future<List<AssignmentSubmissionEntity>> getSubmissionsByAssignment(
    String assignmentId,
  ) async {
    try {
      final models = await _remoteDatasource.getSubmissionsByAssignment(
        assignmentId,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get submissions: ${e.toString()}');
    }
  }

  @override
  Future<List<AssignmentSubmissionEntity>> getStudentSubmissions(
    String assignmentId,
    String studentId,
  ) async {
    try {
      final models = await _remoteDatasource.getStudentSubmissions(
        assignmentId,
        studentId,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get student submissions: ${e.toString()}');
    }
  }

  @override
  Future<AssignmentSubmissionEntity?> getSubmission(String submissionId) async {
    try {
      final model = await _remoteDatasource.getSubmission(submissionId);
      return model?.toEntity();
    } catch (e) {
      throw Exception('Failed to get submission: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSubmission(AssignmentSubmissionEntity submission) async {
    try {
      final model = AssignmentSubmissionModel.fromEntity(submission);
      await _remoteDatasource.updateSubmission(submission.id, model);
    } catch (e) {
      throw Exception('Failed to update submission: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _remoteDatasource.deleteSubmission(submissionId);
    } catch (e) {
      throw Exception('Failed to delete submission: ${e.toString()}');
    }
  }

  @override
  Future<AssignmentSubmissionEntity?> getLatestSubmission(
    String assignmentId,
    String studentId,
  ) async {
    try {
      final model = await _remoteDatasource.getLatestSubmission(
        assignmentId,
        studentId,
      );
      return model?.toEntity();
    } catch (e) {
      throw Exception('Failed to get latest submission: ${e.toString()}');
    }
  }

  @override
  Future<List<AssignmentSubmissionEntity>> getAllStudentSubmissions(
    String studentId,
  ) async {
    try {
      final models = await _remoteDatasource.getAllStudentSubmissions(
        studentId,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get all student submissions: ${e.toString()}');
    }
  }
}
