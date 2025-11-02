import '../entities/question_entity.dart';
import '../entities/question_bank_entity.dart';

/// Question and Question Bank repository interface
/// This defines the contract that data layer must implement
abstract class IQuestionRepository {
  // Question Bank operations

  /// Get all question banks for a course
  Future<List<QuestionBankEntity>> getQuestionBanksByCourse(String courseId);

  /// Get a single question bank by ID
  Future<QuestionBankEntity?> getQuestionBankById(String questionBankId);

  /// Create a new question bank
  Future<QuestionBankEntity> createQuestionBank(
    QuestionBankEntity questionBank,
  );

  /// Update an existing question bank
  Future<QuestionBankEntity> updateQuestionBank(
    QuestionBankEntity questionBank,
  );

  /// Delete a question bank
  Future<void> deleteQuestionBank(String questionBankId);

  // Question operations

  /// Get all questions in a question bank
  Future<List<QuestionEntity>> getQuestionsByBank(String questionBankId);

  /// Get a single question by ID
  Future<QuestionEntity?> getQuestionById(String questionId);

  /// Get questions by difficulty
  Future<List<QuestionEntity>> getQuestionsByDifficulty(
    String questionBankId,
    QuestionDifficulty difficulty,
  );

  /// Get questions by type
  Future<List<QuestionEntity>> getQuestionsByType(
    String questionBankId,
    QuestionType type,
  );

  /// Get random questions from bank
  Future<List<QuestionEntity>> getRandomQuestions(
    String questionBankId,
    int count,
  );

  /// Create a new question
  Future<QuestionEntity> createQuestion(QuestionEntity question);

  /// Update an existing question
  Future<QuestionEntity> updateQuestion(QuestionEntity question);

  /// Delete a question
  Future<void> deleteQuestion(String questionId);
}
