import '../../domain/entities/quiz_entity.dart';
import '../../domain/repositories/i_quiz_repository.dart';
import '../datasources/remote/quiz_remote_datasource.dart';
import '../datasources/models/quiz_model.dart';

/// Implementation of IQuizRepository
/// Handles conversion between models and entities
class QuizRepositoryImpl implements IQuizRepository {
  final QuizRemoteDataSource remoteDataSource;

  QuizRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<QuizEntity>> getQuizzesByCourse(String courseId) async {
    try {
      final quizModels = await remoteDataSource.getQuizzesByCourse(courseId);
      return quizModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuizEntity>> getQuizzesByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      final quizModels = await remoteDataSource.getQuizzesByGroup(
        courseId,
        groupId,
      );
      return quizModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuizEntity?> getQuizById(String quizId) async {
    try {
      final quizModel = await remoteDataSource.getQuizById(quizId);
      return quizModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuizEntity>> getOpenQuizzes(String courseId) async {
    try {
      final quizModels = await remoteDataSource.getOpenQuizzes(courseId);
      return quizModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuizEntity>> getUpcomingQuizzes(
    String courseId,
    int daysAhead,
  ) async {
    try {
      final quizModels = await remoteDataSource.getUpcomingQuizzes(
        courseId,
        daysAhead,
      );
      return quizModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuizEntity> createQuiz(QuizEntity quiz) async {
    try {
      final quizModel = QuizModel.fromEntity(quiz);
      final createdModel = await remoteDataSource.createQuiz(quizModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuizEntity> updateQuiz(QuizEntity quiz) async {
    try {
      final quizModel = QuizModel.fromEntity(quiz);
      final updatedModel = await remoteDataSource.updateQuiz(quizModel);
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    try {
      await remoteDataSource.deleteQuiz(quizId);
    } catch (e) {
      rethrow;
    }
  }
}
