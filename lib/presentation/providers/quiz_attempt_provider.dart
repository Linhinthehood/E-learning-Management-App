import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/quiz_attempt_entity.dart';
import '../../domain/repositories/i_quiz_attempt_repository.dart';
import '../../data/repositories/quiz_attempt_repository_impl.dart';
import '../../data/datasources/remote/quiz_attempt_remote_datasource.dart';

/// Provider for quiz attempt repository
final quizAttemptRepositoryProvider = Provider<IQuizAttemptRepository>((ref) {
  return QuizAttemptRepositoryImpl(
    remoteDatasource: QuizAttemptRemoteDatasource(),
  );
});

/// Provider for quiz attempts state
final quizAttemptProvider = StateNotifierProvider<
    QuizAttemptNotifier,
    AsyncValue<List<QuizAttemptEntity>>
>((ref) {
  final repository = ref.watch(quizAttemptRepositoryProvider);
  return QuizAttemptNotifier(repository);
});

/// State notifier for quiz attempts
class QuizAttemptNotifier extends StateNotifier<AsyncValue<List<QuizAttemptEntity>>> {
  final IQuizAttemptRepository _repository;

  QuizAttemptNotifier(this._repository) : super(const AsyncValue.data([]));

  /// Load attempts for a quiz
  Future<void> loadAttempts(String quizId) async {
    state = const AsyncValue.loading();
    try {
      final attempts = await _repository.getAttemptsByQuiz(quizId);
      state = AsyncValue.data(attempts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load student attempts for a quiz
  Future<void> loadStudentAttempts(String quizId, String studentId) async {
    state = const AsyncValue.loading();
    try {
      final attempts = await _repository.getStudentAttempts(quizId, studentId);
      state = AsyncValue.data(attempts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new attempt
  Future<String> createAttempt(QuizAttemptEntity attempt) async {
    try {
      final attemptId = await _repository.createAttempt(attempt);
      // Reload attempts after creating
      await loadStudentAttempts(attempt.quizId, attempt.studentId);
      return attemptId;
    } catch (e) {
      rethrow;
    }
  }

  /// Update attempt (for saving answers or grading)
  Future<void> updateAttempt(QuizAttemptEntity attempt) async {
    try {
      await _repository.updateAttempt(attempt);
      // Update the state
      state.whenData((attempts) {
        final index = attempts.indexWhere((a) => a.id == attempt.id);
        if (index != -1) {
          final updated = List<QuizAttemptEntity>.from(attempts);
          updated[index] = attempt;
          state = AsyncValue.data(updated);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete attempt
  Future<void> deleteAttempt(String attemptId) async {
    try {
      await _repository.deleteAttempt(attemptId);
      // Update the state
      state.whenData((attempts) {
        final updated = attempts.where((a) => a.id != attemptId).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get latest attempt for a student
  Future<QuizAttemptEntity?> getLatestAttempt(
    String quizId,
    String studentId,
  ) async {
    try {
      return await _repository.getLatestAttempt(quizId, studentId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get in-progress attempt for a student
  Future<QuizAttemptEntity?> getInProgressAttempt(
    String quizId,
    String studentId,
  ) async {
    try {
      return await _repository.getInProgressAttempt(quizId, studentId);
    } catch (e) {
      rethrow;
    }
  }

  /// Count student attempts
  Future<int> countStudentAttempts(String quizId, String studentId) async {
    try {
      return await _repository.countStudentAttempts(quizId, studentId);
    } catch (e) {
      rethrow;
    }
  }
}
