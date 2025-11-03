import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/repositories/i_assignment_submission_repository.dart';
import '../../data/repositories/assignment_submission_repository_impl.dart';
import '../../data/datasources/remote/assignment_submission_remote_datasource.dart';

/// Provider for assignment submission repository
final assignmentSubmissionRepositoryProvider =
    Provider<IAssignmentSubmissionRepository>((ref) {
      return AssignmentSubmissionRepositoryImpl(
        remoteDatasource: AssignmentSubmissionRemoteDatasource(),
      );
    });

/// Provider for assignment submissions state
final assignmentSubmissionProvider =
    StateNotifierProvider<
      AssignmentSubmissionNotifier,
      AsyncValue<List<AssignmentSubmissionEntity>>
    >((ref) {
      final repository = ref.watch(assignmentSubmissionRepositoryProvider);
      return AssignmentSubmissionNotifier(repository);
    });

/// State notifier for assignment submissions
class AssignmentSubmissionNotifier
    extends StateNotifier<AsyncValue<List<AssignmentSubmissionEntity>>> {
  final IAssignmentSubmissionRepository _repository;

  AssignmentSubmissionNotifier(this._repository)
    : super(const AsyncValue.data([]));

  /// Load submissions for an assignment
  Future<void> loadSubmissions(String assignmentId) async {
    state = const AsyncValue.loading();
    try {
      final submissions = await _repository.getSubmissionsByAssignment(
        assignmentId,
      );
      state = AsyncValue.data(submissions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load student submissions for an assignment
  Future<void> loadStudentSubmissions(
    String assignmentId,
    String studentId,
  ) async {
    state = const AsyncValue.loading();
    try {
      final submissions = await _repository.getStudentSubmissions(
        assignmentId,
        studentId,
      );
      state = AsyncValue.data(submissions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new submission
  Future<void> createSubmission(AssignmentSubmissionEntity submission) async {
    try {
      await _repository.createSubmission(submission);
      // Reload submissions after creating
      await loadStudentSubmissions(
        submission.assignmentId,
        submission.studentId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update submission (for grading)
  Future<void> updateSubmission(AssignmentSubmissionEntity submission) async {
    try {
      await _repository.updateSubmission(submission);
      // Update the state
      state.whenData((submissions) {
        final index = submissions.indexWhere((s) => s.id == submission.id);
        if (index != -1) {
          final updated = List<AssignmentSubmissionEntity>.from(submissions);
          updated[index] = submission;
          state = AsyncValue.data(updated);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _repository.deleteSubmission(submissionId);
      // Update the state
      state.whenData((submissions) {
        final updated = submissions.where((s) => s.id != submissionId).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get latest submission for a student
  Future<AssignmentSubmissionEntity?> getLatestSubmission(
    String assignmentId,
    String studentId,
  ) async {
    try {
      return await _repository.getLatestSubmission(assignmentId, studentId);
    } catch (e) {
      rethrow;
    }
  }
}
