import '../../domain/entities/quiz_attempt_entity.dart';
import '../../domain/repositories/i_quiz_attempt_repository.dart';
import '../datasources/remote/quiz_attempt_remote_datasource.dart';
import '../datasources/models/quiz_attempt_model.dart';

/// Implementation of IQuizAttemptRepository
class QuizAttemptRepositoryImpl implements IQuizAttemptRepository {
  final QuizAttemptRemoteDatasource _remoteDatasource;

  QuizAttemptRepositoryImpl({
    required QuizAttemptRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  @override
  Future<String> createAttempt(QuizAttemptEntity attempt) async {
    try {
      final model = QuizAttemptModel.fromEntity(attempt);
      return await _remoteDatasource.createAttempt(model);
    } catch (e) {
      throw Exception('Failed to create attempt: ${e.toString()}');
    }
  }

  @override
  Future<QuizAttemptEntity?> getAttempt(String attemptId) async {
    try {
      final model = await _remoteDatasource.getAttempt(attemptId);
      return model?.toEntity();
    } catch (e) {
      throw Exception('Failed to get attempt: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizAttemptEntity>> getAttemptsByQuiz(String quizId) async {
    try {
      final models = await _remoteDatasource.getAttemptsByQuiz(quizId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get attempts: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizAttemptEntity>> getStudentAttempts(
    String quizId,
    String studentId,
  ) async {
    try {
      final models = await _remoteDatasource.getStudentAttempts(
        quizId,
        studentId,
      );
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get student attempts: ${e.toString()}');
    }
  }

  @override
  Future<QuizAttemptEntity?> getLatestAttempt(
    String quizId,
    String studentId,
  ) async {
    try {
      final model = await _remoteDatasource.getLatestAttempt(
        quizId,
        studentId,
      );
      return model?.toEntity();
    } catch (e) {
      throw Exception('Failed to get latest attempt: ${e.toString()}');
    }
  }

  @override
  Future<QuizAttemptEntity?> getInProgressAttempt(
    String quizId,
    String studentId,
  ) async {
    try {
      final model = await _remoteDatasource.getInProgressAttempt(
        quizId,
        studentId,
      );
      return model?.toEntity();
    } catch (e) {
      throw Exception('Failed to get in-progress attempt: ${e.toString()}');
    }
  }

  @override
  Future<void> updateAttempt(QuizAttemptEntity attempt) async {
    try {
      final model = QuizAttemptModel.fromEntity(attempt);
      await _remoteDatasource.updateAttempt(attempt.id, model);
    } catch (e) {
      throw Exception('Failed to update attempt: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAttempt(String attemptId) async {
    try {
      await _remoteDatasource.deleteAttempt(attemptId);
    } catch (e) {
      throw Exception('Failed to delete attempt: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizAttemptEntity>> getAllStudentAttempts(String studentId) async {
    try {
      final models = await _remoteDatasource.getAllStudentAttempts(studentId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get all student attempts: ${e.toString()}');
    }
  }

  @override
  Future<int> countStudentAttempts(String quizId, String studentId) async {
    try {
      return await _remoteDatasource.countStudentAttempts(quizId, studentId);
    } catch (e) {
      throw Exception('Failed to count student attempts: ${e.toString()}');
    }
  }
}
