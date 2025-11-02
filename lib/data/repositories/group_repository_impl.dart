import '../../domain/entities/group_entity.dart';
import '../../domain/repositories/i_group_repository.dart';
import '../datasources/remote/enrollment_remote_datasource.dart';
import '../datasources/models/group_model.dart';

/// Implementation of IGroupRepository
class GroupRepositoryImpl implements IGroupRepository {
  final EnrollmentRemoteDataSource remoteDataSource;

  GroupRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<GroupEntity>> getGroupsByCourse(String courseId) async {
    try {
      final groupModels = await remoteDataSource.getGroupsByCourse(courseId);
      return groupModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GroupEntity?> getGroupById(String groupId) async {
    try {
      final groupModel = await remoteDataSource.getGroupById(groupId);
      return groupModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<GroupEntity> createGroup(GroupEntity group) async {
    try {
      final groupModel = GroupModel.fromEntity(group);
      final createdModel = await remoteDataSource.createGroup(groupModel);
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      await remoteDataSource.deleteGroup(groupId);
    } catch (e) {
      rethrow;
    }
  }
}
