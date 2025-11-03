import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/remote/comment_remote_datasource.dart';

/// Implementation of comment repository
class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remoteDataSource;

  CommentRepositoryImpl({
    CommentRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? CommentRemoteDataSource();

  @override
  Future<List<CommentEntity>> getCommentsByAnnouncementId(
    String announcementId,
  ) async {
    try {
      final comments = await _remoteDataSource.getCommentsByAnnouncementId(
        announcementId,
      );
      return comments.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addComment({
    required String announcementId,
    required String content,
  }) async {
    try {
      await _remoteDataSource.addComment(
        announcementId: announcementId,
        content: content,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      await _remoteDataSource.updateComment(
        commentId: commentId,
        content: content,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await _remoteDataSource.deleteComment(commentId);
    } catch (e) {
      rethrow;
    }
  }
}
