import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/forum_topic_remote_datasource.dart';
import '../../data/repositories/forum_topic_repository_impl.dart';
import '../../domain/entities/forum_topic_entity.dart';
import '../../domain/repositories/i_forum_topic_repository.dart';

/// Provider for forum topic remote data source
final forumTopicRemoteDataSourceProvider = Provider<ForumTopicRemoteDataSource>(
  (ref) {
    return ForumTopicRemoteDataSourceImpl();
  },
);

/// Provider for forum topic repository
final forumTopicRepositoryProvider = Provider<IForumTopicRepository>((ref) {
  return ForumTopicRepositoryImpl(
    remoteDataSource: ref.read(forumTopicRemoteDataSourceProvider),
  );
});

/// Forum topic state notifier - manages forum topics for a course
class ForumTopicNotifier
    extends StateNotifier<AsyncValue<List<ForumTopicEntity>>> {
  final IForumTopicRepository _repository;
  String? _currentCourseId;

  ForumTopicNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load forum topics for a course
  Future<void> loadTopics(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final topics = await _repository.getTopicsByCourse(courseId);
      state = AsyncValue.data(topics);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Search forum topics by keyword
  Future<void> searchTopics(String courseId, String keyword) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final topics = await _repository.searchTopics(courseId, keyword);
      state = AsyncValue.data(topics);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load recent forum topics (last N days)
  Future<void> loadRecentTopics(String courseId, int days) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final topics = await _repository.getRecentTopics(courseId, days);
      state = AsyncValue.data(topics);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new forum topic
  Future<void> createTopic(ForumTopicEntity topic) async {
    try {
      await _repository.createTopic(topic);
      if (_currentCourseId != null) {
        await loadTopics(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing forum topic
  Future<void> updateTopic(ForumTopicEntity topic) async {
    try {
      await _repository.updateTopic(topic);
      if (_currentCourseId != null) {
        await loadTopics(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a forum topic
  Future<void> deleteTopic(String topicId) async {
    try {
      await _repository.deleteTopic(topicId);
      if (_currentCourseId != null) {
        await loadTopics(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current topics
  Future<void> refresh() async {
    if (_currentCourseId != null) {
      await loadTopics(_currentCourseId!);
    }
  }
}

/// Provider for forum topic state notifier
final forumTopicProvider =
    StateNotifierProvider<
      ForumTopicNotifier,
      AsyncValue<List<ForumTopicEntity>>
    >((ref) {
      return ForumTopicNotifier(ref.read(forumTopicRepositoryProvider));
    });

/// Provider for fetching a single forum topic by ID
final forumTopicByIdProvider = FutureProvider.family<ForumTopicEntity?, String>(
  (ref, topicId) async {
    final repository = ref.read(forumTopicRepositoryProvider);
    return await repository.getTopicById(topicId);
  },
);
