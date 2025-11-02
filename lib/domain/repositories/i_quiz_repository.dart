import '../entities/quiz_entity.dart';

/// Quiz repository interface
/// This defines the contract that data layer must implement
abstract class IQuizRepository {
  /// Get all quizzes for a course
  Future<List<QuizEntity>> getQuizzesByCourse(String courseId);

  /// Get quizzes for a specific group
  Future<List<QuizEntity>> getQuizzesByGroup(
    String courseId,
    String groupId,
  );

  /// Get a single quiz by ID
  Future<QuizEntity?> getQuizById(String quizId);

  /// Get open quizzes (currently available)
  Future<List<QuizEntity>> getOpenQuizzes(String courseId);

  /// Get upcoming quizzes
  Future<List<QuizEntity>> getUpcomingQuizzes(
    String courseId,
    int daysAhead,
  );

  /// Create a new quiz
  Future<QuizEntity> createQuiz(QuizEntity quiz);

  /// Update an existing quiz
  Future<QuizEntity> updateQuiz(QuizEntity quiz);

  /// Delete a quiz
  Future<void> deleteQuiz(String quizId);
}
