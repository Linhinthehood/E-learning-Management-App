import '../entities/assignment_submission_entity.dart';

/// Repository interface for assignment submissions
abstract class IAssignmentSubmissionRepository {
  /// Create a new submission
  Future<void> createSubmission(AssignmentSubmissionEntity submission);

  /// Get submissions for an assignment
  Future<List<AssignmentSubmissionEntity>> getSubmissionsByAssignment(
    String assignmentId,
  );

  /// Get submissions by a student for an assignment
  Future<List<AssignmentSubmissionEntity>> getStudentSubmissions(
    String assignmentId,
    String studentId,
  );

  /// Get a specific submission
  Future<AssignmentSubmissionEntity?> getSubmission(String submissionId);

  /// Update submission (for grading)
  Future<void> updateSubmission(AssignmentSubmissionEntity submission);

  /// Delete submission
  Future<void> deleteSubmission(String submissionId);

  /// Get student's latest submission for an assignment
  Future<AssignmentSubmissionEntity?> getLatestSubmission(
    String assignmentId,
    String studentId,
  );

  /// Get all submissions by a student across all assignments
  Future<List<AssignmentSubmissionEntity>> getAllStudentSubmissions(
    String studentId,
  );
}
