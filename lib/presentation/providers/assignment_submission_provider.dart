import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/assignment_submission_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_assignment_submission_repository.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../domain/repositories/i_assignment_repository.dart';
import '../../data/repositories/assignment_submission_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/assignment_repository_impl.dart';
import '../../data/datasources/remote/assignment_submission_remote_datasource.dart';
import '../../data/datasources/remote/notification_remote_datasource.dart';
import '../../data/datasources/remote/assignment_remote_datasource.dart';

/// Provider for assignment submission repository
final assignmentSubmissionRepositoryProvider =
    Provider<IAssignmentSubmissionRepository>((ref) {
      return AssignmentSubmissionRepositoryImpl(
        remoteDatasource: AssignmentSubmissionRemoteDatasource(),
      );
    });

/// Provider for notification repository (for triggers)
final notificationRepositoryForSubmissionProvider =
    Provider<INotificationRepository>((ref) {
      return NotificationRepositoryImpl(
        remoteDataSource: NotificationRemoteDataSourceImpl(),
      );
    });

/// Provider for assignment repository (to get assignment details)
final assignmentRepositoryForSubmissionProvider =
    Provider<IAssignmentRepository>((ref) {
      return AssignmentRepositoryImpl(
        remoteDataSource: AssignmentRemoteDataSourceImpl(),
      );
    });

/// Provider for assignment submissions state
final assignmentSubmissionProvider =
    StateNotifierProvider<
      AssignmentSubmissionNotifier,
      AsyncValue<List<AssignmentSubmissionEntity>>
    >((ref) {
      final repository = ref.watch(assignmentSubmissionRepositoryProvider);
      final notificationRepo = ref.watch(
        notificationRepositoryForSubmissionProvider,
      );
      final assignmentRepo = ref.watch(
        assignmentRepositoryForSubmissionProvider,
      );
      return AssignmentSubmissionNotifier(
        repository,
        notificationRepo,
        assignmentRepo,
      );
    });

/// State notifier for assignment submissions
class AssignmentSubmissionNotifier
    extends StateNotifier<AsyncValue<List<AssignmentSubmissionEntity>>> {
  final IAssignmentSubmissionRepository _repository;
  final INotificationRepository _notificationRepository;
  final IAssignmentRepository _assignmentRepository;

  AssignmentSubmissionNotifier(
    this._repository,
    this._notificationRepository,
    this._assignmentRepository,
  ) : super(const AsyncValue.data([]));

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

      // Send confirmation notification
      await _sendSubmissionConfirmedNotification(submission);

      // Reload submissions after creating
      await loadStudentSubmissions(
        submission.assignmentId,
        submission.studentId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Send notification when submission is confirmed
  Future<void> _sendSubmissionConfirmedNotification(
    AssignmentSubmissionEntity submission,
  ) async {
    try {
      // Get assignment details
      final assignment = await _assignmentRepository.getAssignmentById(
        submission.assignmentId,
      );
      if (assignment == null) return;

      // Create notification
      final notification = NotificationEntity(
        id: '', // Firestore will generate
        studentId: submission.studentId,
        title: 'Submission Confirmed',
        message:
            'Your submission for "${assignment.title}" has been received successfully.',
        isRead: false,
        createdAt: DateTime.now(),
        linkTo: 'assignment/${submission.courseId}/${submission.assignmentId}',
        type: NotificationEntity.typeAssignment,
      );

      await _notificationRepository.createNotification(notification);
    } catch (e) {
      // Don't fail the submission if notification fails
      print('Failed to send submission confirmed notification: $e');
    }
  }

  /// Update submission (for grading)
  Future<void> updateSubmission(
    AssignmentSubmissionEntity submission, {
    AssignmentSubmissionEntity? previousSubmission,
  }) async {
    try {
      await _repository.updateSubmission(submission);

      // Send notification if assignment was just graded
      if (submission.grade != null &&
          (previousSubmission == null || previousSubmission.grade == null)) {
        await _sendGradedNotification(submission);
      }

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

  /// Send notification when assignment is graded
  Future<void> _sendGradedNotification(
    AssignmentSubmissionEntity submission,
  ) async {
    try {
      // Get assignment details
      final assignment = await _assignmentRepository.getAssignmentById(
        submission.assignmentId,
      );
      if (assignment == null) return;

      // Create notification
      final notification = NotificationEntity(
        id: '', // Firestore will generate
        studentId: submission.studentId,
        title: 'Assignment Graded',
        message:
            'Your assignment "${assignment.title}" has been graded. Score: ${submission.grade?.toStringAsFixed(1)}',
        isRead: false,
        createdAt: DateTime.now(),
        linkTo: 'assignment/${submission.courseId}/${submission.assignmentId}',
        type: NotificationEntity.typeGrade,
      );

      await _notificationRepository.createNotification(notification);
    } catch (e) {
      // Don't fail the update if notification fails
      print('Failed to send graded notification: $e');
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
