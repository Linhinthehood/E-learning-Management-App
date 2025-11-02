import '../../repositories/i_group_repository.dart';

/// Use case for deleting a group
class DeleteGroupUseCase {
  final IGroupRepository _groupRepository;

  DeleteGroupUseCase(this._groupRepository);

  /// Execute the delete group use case
  Future<void> execute(String groupId) async {
    if (groupId.isEmpty) {
      throw Exception('Group ID cannot be empty');
    }

    // TODO: Check if group has enrollments before deleting
    // If it does, prevent deletion or handle cascade delete

    return await _groupRepository.deleteGroup(groupId);
  }
}

