import '../../domain/entities/forum_topic_entity.dart';
import '../../domain/repositories/i_forum_topic_repository.dart';
import '../datasources/remote/forum_topic_remote_datasource.dart';
import '../datasources/models/forum_topic_model.dart';

/// Implementation of IForumTopicRepository
/// Handles conversion between models and entities
class ForumTopicRepositoryImpl implements IForumTopicRepository {
  final ForumTopicRemoteDataSource remoteDataSource;

  ForumTopicRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ForumTopicEntity>> getTopicsByCourse(String courseId) async {
    try {
      final topicModels = await remoteDataSource.getTopicsByCourse(courseId);
      return topicModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ForumTopicEntity?> getTopicById(String topicId) async {
    try {
      final topicModel = await remoteDataSource.getTopicById(topicId);
      return topicModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ForumTopicEntity> createTopic(ForumTopicEntity topic) async {
    try {
      final topicModel = ForumTopicModel.fromEntity(topic);
      final createdModel = await remoteDataSource.createTopic(topicModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ForumTopicEntity> updateTopic(ForumTopicEntity topic) async {
    try {
      final topicModel = ForumTopicModel.fromEntity(topic);
      final updatedModel = await remoteDataSource.updateTopic(topicModel);
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    try {
      await remoteDataSource.deleteTopic(topicId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ForumTopicEntity>> searchTopics(
    String courseId,
    String keyword,
  ) async {
    try {
      final topicModels = await remoteDataSource.searchTopics(
        courseId,
        keyword,
      );
      return topicModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ForumTopicEntity>> getRecentTopics(
    String courseId,
    int days,
  ) async {
    try {
      final topicModels = await remoteDataSource.getRecentTopics(
        courseId,
        days,
      );
      return topicModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> incrementReplyCount(String topicId) async {
    try {
      await remoteDataSource.incrementReplyCount(topicId);
    } catch (e) {
      rethrow;
    }
  }
}
