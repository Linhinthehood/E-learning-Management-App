import '../../domain/entities/forum_reply_entity.dart';
import '../../domain/repositories/i_forum_reply_repository.dart';
import '../datasources/remote/forum_reply_remote_datasource.dart';
import '../datasources/models/forum_reply_model.dart';

/// Implementation of IForumReplyRepository
/// Handles conversion between models and entities
class ForumReplyRepositoryImpl implements IForumReplyRepository {
  final ForumReplyRemoteDataSource remoteDataSource;

  ForumReplyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ForumReplyEntity>> getRepliesByTopic(String topicId) async {
    try {
      final replyModels = await remoteDataSource.getRepliesByTopic(topicId);
      return replyModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ForumReplyEntity?> getReplyById(String replyId) async {
    try {
      final replyModel = await remoteDataSource.getReplyById(replyId);
      return replyModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ForumReplyEntity> createReply(ForumReplyEntity reply) async {
    try {
      final replyModel = ForumReplyModel.fromEntity(reply);
      final createdModel = await remoteDataSource.createReply(replyModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ForumReplyEntity> updateReply(ForumReplyEntity reply) async {
    try {
      final replyModel = ForumReplyModel.fromEntity(reply);
      final updatedModel = await remoteDataSource.updateReply(replyModel);
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteReply(String replyId) async {
    try {
      await remoteDataSource.deleteReply(replyId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ForumReplyEntity>> getThreadedReplies(
    String topicId,
    String replyToId,
  ) async {
    try {
      final replyModels = await remoteDataSource.getThreadedReplies(
        topicId,
        replyToId,
      );
      return replyModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }
}
