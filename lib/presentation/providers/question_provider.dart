import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/question_remote_datasource.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/entities/question_bank_entity.dart';
import '../../domain/repositories/i_question_repository.dart';

/// Provider for question remote data source
final questionRemoteDataSourceProvider = Provider<QuestionRemoteDataSource>((
  ref,
) {
  return QuestionRemoteDataSourceImpl();
});

/// Provider for question repository
final questionRepositoryProvider = Provider<IQuestionRepository>((ref) {
  return QuestionRepositoryImpl(
    remoteDataSource: ref.read(questionRemoteDataSourceProvider),
  );
});

/// Question Bank state notifier - manages question banks for a course
class QuestionBankNotifier
    extends StateNotifier<AsyncValue<List<QuestionBankEntity>>> {
  final IQuestionRepository _repository;
  String? _currentCourseId;

  QuestionBankNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load question banks for a course
  Future<void> loadQuestionBanks(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final questionBanks = await _repository.getQuestionBanksByCourse(
        courseId,
      );
      state = AsyncValue.data(questionBanks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new question bank
  Future<void> createQuestionBank(QuestionBankEntity questionBank) async {
    try {
      await _repository.createQuestionBank(questionBank);
      if (_currentCourseId != null) {
        await loadQuestionBanks(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing question bank
  Future<void> updateQuestionBank(QuestionBankEntity questionBank) async {
    try {
      await _repository.updateQuestionBank(questionBank);
      if (_currentCourseId != null) {
        await loadQuestionBanks(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a question bank
  Future<void> deleteQuestionBank(String questionBankId) async {
    try {
      await _repository.deleteQuestionBank(questionBankId);
      if (_currentCourseId != null) {
        await loadQuestionBanks(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current question banks
  Future<void> refresh() async {
    if (_currentCourseId != null) {
      await loadQuestionBanks(_currentCourseId!);
    }
  }
}

/// Provider for question bank state notifier
final questionBankProvider =
    StateNotifierProvider<
      QuestionBankNotifier,
      AsyncValue<List<QuestionBankEntity>>
    >((ref) {
      return QuestionBankNotifier(ref.read(questionRepositoryProvider));
    });

/// Provider for fetching a single question bank by ID
final questionBankByIdProvider =
    FutureProvider.family<QuestionBankEntity?, String>((
      ref,
      questionBankId,
    ) async {
      final repository = ref.read(questionRepositoryProvider);
      return await repository.getQuestionBankById(questionBankId);
    });

/// Question state notifier - manages questions for a question bank
class QuestionNotifier extends StateNotifier<AsyncValue<List<QuestionEntity>>> {
  final IQuestionRepository _repository;
  String? _currentQuestionBankId;

  QuestionNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load questions for a question bank
  Future<void> loadQuestions(String questionBankId) async {
    _currentQuestionBankId = questionBankId;
    state = const AsyncValue.loading();
    try {
      final questions = await _repository.getQuestionsByBank(questionBankId);
      state = AsyncValue.data(questions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load questions by difficulty
  Future<void> loadQuestionsByDifficulty(
    String questionBankId,
    QuestionDifficulty difficulty,
  ) async {
    _currentQuestionBankId = questionBankId;
    state = const AsyncValue.loading();
    try {
      final questions = await _repository.getQuestionsByDifficulty(
        questionBankId,
        difficulty,
      );
      state = AsyncValue.data(questions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load questions by type
  Future<void> loadQuestionsByType(
    String questionBankId,
    QuestionType type,
  ) async {
    _currentQuestionBankId = questionBankId;
    state = const AsyncValue.loading();
    try {
      final questions = await _repository.getQuestionsByType(
        questionBankId,
        type,
      );
      state = AsyncValue.data(questions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load random questions
  Future<void> loadRandomQuestions(String questionBankId, int count) async {
    _currentQuestionBankId = questionBankId;
    state = const AsyncValue.loading();
    try {
      final questions = await _repository.getRandomQuestions(
        questionBankId,
        count,
      );
      state = AsyncValue.data(questions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new question
  Future<void> createQuestion(QuestionEntity question) async {
    try {
      await _repository.createQuestion(question);
      if (_currentQuestionBankId != null) {
        await loadQuestions(_currentQuestionBankId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing question
  Future<void> updateQuestion(QuestionEntity question) async {
    try {
      await _repository.updateQuestion(question);
      if (_currentQuestionBankId != null) {
        await loadQuestions(_currentQuestionBankId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a question
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _repository.deleteQuestion(questionId);
      if (_currentQuestionBankId != null) {
        await loadQuestions(_currentQuestionBankId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current questions
  Future<void> refresh() async {
    if (_currentQuestionBankId != null) {
      await loadQuestions(_currentQuestionBankId!);
    }
  }
}

/// Provider for question state notifier
final questionProvider =
    StateNotifierProvider<QuestionNotifier, AsyncValue<List<QuestionEntity>>>((
      ref,
    ) {
      return QuestionNotifier(ref.read(questionRepositoryProvider));
    });

/// Provider for fetching a single question by ID
final questionByIdProvider = FutureProvider.family<QuestionEntity?, String>((
  ref,
  questionId,
) async {
  final repository = ref.read(questionRepositoryProvider);
  return await repository.getQuestionById(questionId);
});
