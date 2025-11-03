import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../data/repositories/comment_repository_impl.dart';

/// Provider for comment repository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepositoryImpl();
});

/// Provider for comments state
final commentProvider = StateNotifierProvider.family<
    CommentNotifier,
    AsyncValue<List<CommentEntity>>,
    String>((ref, announcementId) {
  return CommentNotifier(
    ref.read(commentRepositoryProvider),
    announcementId,
  );
});

/// Comment notifier
class CommentNotifier
    extends StateNotifier<AsyncValue<List<CommentEntity>>> {
  final CommentRepository _repository;
  final String _announcementId;

  CommentNotifier(this._repository, this._announcementId)
      : super(const AsyncValue.loading()) {
    loadComments();
  }

  /// Load comments for announcement
  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    try {
      final comments = await _repository.getCommentsByAnnouncementId(
        _announcementId,
      );
      state = AsyncValue.data(comments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add a new comment
  Future<void> addComment(String content) async {
    try {
      await _repository.addComment(
        announcementId: _announcementId,
        content: content,
      );
      await loadComments(); // Reload comments after adding
    } catch (e) {
      rethrow;
    }
  }

  /// Update a comment
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      await _repository.updateComment(
        commentId: commentId,
        content: content,
      );
      await loadComments(); // Reload comments after updating
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      await loadComments(); // Reload comments after deleting
    } catch (e) {
      rethrow;
    }
  }
}
