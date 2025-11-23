import '../../repositories/i_group_repository.dart';
import '../../repositories/i_enrollment_repository.dart';

/// Use case for deleting a group
class DeleteGroupUseCase {
  final IGroupRepository _groupRepository;
  final IEnrollmentRepository _enrollmentRepository;

  DeleteGroupUseCase(this._groupRepository, this._enrollmentRepository);

  /// Execute the delete group use case
  Future<void> execute(String groupId) async {
    if (groupId.isEmpty) {
      throw Exception('Group ID cannot be empty');
    }

    // Check if group has enrollments before deleting
    final enrollments = await _enrollmentRepository.getEnrollmentsByGroup(
      groupId,
    );

    if (enrollments.isNotEmpty) {
      throw Exception(
        'Cannot delete group: Group has ${enrollments.length} student(s) enrolled. '
        'Please remove all students from the group before deleting.',
      );
    }

    return await _groupRepository.deleteGroup(groupId);
  }
}
