import '../../domain/entities/question_entity.dart';
import '../../domain/entities/question_bank_entity.dart';
import '../../domain/repositories/i_question_repository.dart';
import '../datasources/remote/question_remote_datasource.dart';
import '../datasources/models/question_model.dart';
import '../datasources/models/question_bank_model.dart';

/// Implementation of IQuestionRepository
/// Handles conversion between models and entities
class QuestionRepositoryImpl implements IQuestionRepository {
  final QuestionRemoteDataSource remoteDataSource;

  QuestionRepositoryImpl({required this.remoteDataSource});

  // Question Bank operations

  @override
  Future<List<QuestionBankEntity>> getQuestionBanksByCourse(
    String courseId,
  ) async {
    try {
      final questionBankModels = await remoteDataSource
          .getQuestionBanksByCourse(courseId);
      return questionBankModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuestionBankEntity?> getQuestionBankById(String questionBankId) async {
    try {
      final questionBankModel = await remoteDataSource.getQuestionBankById(
        questionBankId,
      );
      return questionBankModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuestionBankEntity> createQuestionBank(
    QuestionBankEntity questionBank,
  ) async {
    try {
      final questionBankModel = QuestionBankModel.fromEntity(questionBank);
      final createdModel = await remoteDataSource.createQuestionBank(
        questionBankModel,
      );
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuestionBankEntity> updateQuestionBank(
    QuestionBankEntity questionBank,
  ) async {
    try {
      final questionBankModel = QuestionBankModel.fromEntity(questionBank);
      final updatedModel = await remoteDataSource.updateQuestionBank(
        questionBankModel,
      );
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteQuestionBank(String questionBankId) async {
    try {
      await remoteDataSource.deleteQuestionBank(questionBankId);
    } catch (e) {
      rethrow;
    }
  }

  // Question operations

  @override
  Future<List<QuestionEntity>> getQuestionsByBank(String questionBankId) async {
    try {
      final questionModels = await remoteDataSource.getQuestionsByBank(
        questionBankId,
      );
      return questionModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuestionEntity?> getQuestionById(String questionId) async {
    try {
      final questionModel = await remoteDataSource.getQuestionById(questionId);
      return questionModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuestionEntity>> getQuestionsByDifficulty(
    String questionBankId,
    QuestionDifficulty difficulty,
  ) async {
    try {
      final questionModels = await remoteDataSource.getQuestionsByDifficulty(
        questionBankId,
        difficulty,
      );
      return questionModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuestionEntity>> getQuestionsByType(
    String questionBankId,
    QuestionType type,
  ) async {
    try {
      final questionModels = await remoteDataSource.getQuestionsByType(
        questionBankId,
        type,
      );
      return questionModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<QuestionEntity>> getRandomQuestions(
    String questionBankId,
    int count,
  ) async {
    try {
      final questionModels = await remoteDataSource.getRandomQuestions(
        questionBankId,
        count,
      );
      return questionModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuestionEntity> createQuestion(QuestionEntity question) async {
    try {
      final questionModel = QuestionModel.fromEntity(question);
      final createdModel = await remoteDataSource.createQuestion(questionModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<QuestionEntity> updateQuestion(QuestionEntity question) async {
    try {
      final questionModel = QuestionModel.fromEntity(question);
      final updatedModel = await remoteDataSource.updateQuestion(questionModel);
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    try {
      await remoteDataSource.deleteQuestion(questionId);
    } catch (e) {
      rethrow;
    }
  }
}
