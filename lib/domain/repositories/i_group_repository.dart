import '../entities/group_entity.dart';

/// Group repository interface
/// This defines the contract that data layer must implement
abstract class IGroupRepository {
  /// Get all groups for a course
  Future<List<GroupEntity>> getGroupsByCourse(String courseId);

  /// Get a single group by ID
  Future<GroupEntity?> getGroupById(String groupId);

  /// Create a new group
  Future<GroupEntity> createGroup(GroupEntity group);

  /// Delete a group
  Future<void> deleteGroup(String groupId);
}
