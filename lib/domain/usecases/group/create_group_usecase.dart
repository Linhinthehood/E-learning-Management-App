import '../../entities/group_entity.dart';
import '../../repositories/i_group_repository.dart';

/// Use case for creating a new group
class CreateGroupUseCase {
  final IGroupRepository _groupRepository;

  CreateGroupUseCase(this._groupRepository);

  /// Execute the create group use case
  Future<GroupEntity> execute(GroupEntity group) async {
    // Validate group data
    if (group.name.isEmpty) {
      throw Exception('Group name cannot be empty');
    }

    if (group.courseId.isEmpty) {
      throw Exception('Course ID cannot be empty');
    }

    if (group.semesterId.isEmpty) {
      throw Exception('Semester ID cannot be empty');
    }

    // Check if group name already exists in the course
    final existingGroups = await _groupRepository.getGroupsByCourse(group.courseId);
    final duplicateName = existingGroups.any(
      (g) => g.name.toLowerCase().trim() == group.name.toLowerCase().trim(),
    );

    if (duplicateName) {
      throw Exception('A group with this name already exists in this course');
    }

    return await _groupRepository.createGroup(group);
  }
}

