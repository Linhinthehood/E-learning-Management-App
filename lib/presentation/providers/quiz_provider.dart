import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/quiz_remote_datasource.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/quiz_entity.dart';
import '../../domain/repositories/i_quiz_repository.dart';

/// Provider for quiz remote data source
final quizRemoteDataSourceProvider = Provider<QuizRemoteDataSource>((ref) {
  return QuizRemoteDataSourceImpl();
});

/// Provider for quiz repository
final quizRepositoryProvider = Provider<IQuizRepository>((ref) {
  return QuizRepositoryImpl(
    remoteDataSource: ref.read(quizRemoteDataSourceProvider),
  );
});

/// Quiz state notifier - manages quizzes for a course
class QuizNotifier extends StateNotifier<AsyncValue<List<QuizEntity>>> {
  final IQuizRepository _repository;
  String? _currentCourseId;

  QuizNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load quizzes for a course
  Future<void> loadQuizzes(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final quizzes = await _repository.getQuizzesByCourse(courseId);
      state = AsyncValue.data(quizzes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load quizzes for a specific group
  Future<void> loadGroupQuizzes(String courseId, String groupId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final quizzes = await _repository.getQuizzesByGroup(courseId, groupId);
      state = AsyncValue.data(quizzes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load open quizzes (currently available)
  Future<void> loadOpenQuizzes(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final quizzes = await _repository.getOpenQuizzes(courseId);
      state = AsyncValue.data(quizzes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load upcoming quizzes
  Future<void> loadUpcomingQuizzes(String courseId, int daysAhead) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final quizzes = await _repository.getUpcomingQuizzes(courseId, daysAhead);
      state = AsyncValue.data(quizzes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new quiz
  /// Returns the created quiz with the generated ID
  Future<QuizEntity> createQuiz(QuizEntity quiz) async {
    try {
      final createdQuiz = await _repository.createQuiz(quiz);
      if (_currentCourseId != null) {
        await loadQuizzes(_currentCourseId!); // Reload list
      }
      return createdQuiz;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing quiz
  Future<void> updateQuiz(QuizEntity quiz) async {
    try {
      await _repository.updateQuiz(quiz);
      if (_currentCourseId != null) {
        await loadQuizzes(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a quiz
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _repository.deleteQuiz(quizId);
      if (_currentCourseId != null) {
        await loadQuizzes(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current quizzes
  Future<void> refresh() async {
    if (_currentCourseId != null) {
      await loadQuizzes(_currentCourseId!);
    }
  }
}

/// Provider for quiz state notifier
final quizProvider =
    StateNotifierProvider<QuizNotifier, AsyncValue<List<QuizEntity>>>((ref) {
      return QuizNotifier(ref.read(quizRepositoryProvider));
    });

/// Provider for fetching a single quiz by ID
final quizByIdProvider = FutureProvider.family<QuizEntity?, String>((
  ref,
  quizId,
) async {
  final repository = ref.read(quizRepositoryProvider);
  return await repository.getQuizById(quizId);
});
