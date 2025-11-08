import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/forum_reply_remote_datasource.dart';
import '../../data/repositories/forum_reply_repository_impl.dart';
import '../../domain/entities/forum_reply_entity.dart';
import '../../domain/repositories/i_forum_reply_repository.dart';
import './forum_topic_provider.dart';

/// Provider for forum reply remote data source
final forumReplyRemoteDataSourceProvider =
    Provider<ForumReplyRemoteDataSource>((ref) {
  return ForumReplyRemoteDataSourceImpl();
});

/// Provider for forum reply repository
final forumReplyRepositoryProvider = Provider<IForumReplyRepository>((ref) {
  return ForumReplyRepositoryImpl(
    remoteDataSource: ref.read(forumReplyRemoteDataSourceProvider),
  );
});

/// Forum reply state notifier - manages forum replies for a topic
class ForumReplyNotifier
    extends StateNotifier<AsyncValue<List<ForumReplyEntity>>> {
  final IForumReplyRepository _repository;
  final Ref _ref;
  String? _currentTopicId;

  ForumReplyNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  /// Load forum replies for a topic
  Future<void> loadReplies(String topicId) async {
    _currentTopicId = topicId;
    state = const AsyncValue.loading();
    try {
      final replies = await _repository.getRepliesByTopic(topicId);
      state = AsyncValue.data(replies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load threaded replies (replies to a specific reply)
  Future<void> loadThreadedReplies(String topicId, String replyToId) async {
    _currentTopicId = topicId;
    state = const AsyncValue.loading();
    try {
      final replies = await _repository.getThreadedReplies(topicId, replyToId);
      state = AsyncValue.data(replies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new forum reply
  Future<void> createReply(ForumReplyEntity reply) async {
    try {
      await _repository.createReply(reply);

      // Increment reply count in the topic
      await _ref
          .read(forumTopicRepositoryProvider)
          .incrementReplyCount(reply.topicId);

      if (_currentTopicId != null) {
        await loadReplies(_currentTopicId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing forum reply
  Future<void> updateReply(ForumReplyEntity reply) async {
    try {
      await _repository.updateReply(reply);
      if (_currentTopicId != null) {
        await loadReplies(_currentTopicId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a forum reply
  Future<void> deleteReply(String replyId) async {
    try {
      await _repository.deleteReply(replyId);
      if (_currentTopicId != null) {
        await loadReplies(_currentTopicId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current replies
  Future<void> refresh() async {
    if (_currentTopicId != null) {
      await loadReplies(_currentTopicId!);
    }
  }
}

/// Provider for forum reply state notifier
final forumReplyProvider = StateNotifierProvider<
    ForumReplyNotifier,
    AsyncValue<List<ForumReplyEntity>>
>((ref) {
  return ForumReplyNotifier(
    ref.read(forumReplyRepositoryProvider),
    ref,
  );
});

/// Provider for fetching a single forum reply by ID
final forumReplyByIdProvider =
    FutureProvider.family<ForumReplyEntity?, String>((
  ref,
  replyId,
) async {
  final repository = ref.read(forumReplyRepositoryProvider);
  return await repository.getReplyById(replyId);
});
