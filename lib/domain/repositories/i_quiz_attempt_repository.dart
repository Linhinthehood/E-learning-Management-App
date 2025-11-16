import '../entities/quiz_attempt_entity.dart';

/// Repository interface for quiz attempts
abstract class IQuizAttemptRepository {
  /// Create a new quiz attempt
  Future<String> createAttempt(QuizAttemptEntity attempt);

  /// Get a specific attempt by ID
  Future<QuizAttemptEntity?> getAttempt(String attemptId);

  /// Get all attempts for a quiz
  Future<List<QuizAttemptEntity>> getAttemptsByQuiz(String quizId);

  /// Get attempts by a student for a quiz
  Future<List<QuizAttemptEntity>> getStudentAttempts(
    String quizId,
    String studentId,
  );

  /// Get student's latest attempt for a quiz
  Future<QuizAttemptEntity?> getLatestAttempt(String quizId, String studentId);

  /// Get student's in-progress attempt for a quiz
  Future<QuizAttemptEntity?> getInProgressAttempt(
    String quizId,
    String studentId,
  );

  /// Update an attempt (for saving answers or grading)
  Future<void> updateAttempt(QuizAttemptEntity attempt);

  /// Delete an attempt
  Future<void> deleteAttempt(String attemptId);

  /// Get all attempts by a student across all quizzes
  Future<List<QuizAttemptEntity>> getAllStudentAttempts(String studentId);

  /// Count attempts for a student on a quiz
  Future<int> countStudentAttempts(String quizId, String studentId);
}
