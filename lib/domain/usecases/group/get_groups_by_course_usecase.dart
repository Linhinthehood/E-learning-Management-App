import '../../entities/group_entity.dart';
import '../../repositories/i_group_repository.dart';

/// Use case for getting all groups for a course
class GetGroupsByCourseUseCase {
  final IGroupRepository _groupRepository;

  GetGroupsByCourseUseCase(this._groupRepository);

  /// Execute the use case
  /// Returns list of groups for the given course
  Future<List<GroupEntity>> execute(String courseId) async {
    if (courseId.isEmpty) {
      throw Exception('Course ID cannot be empty');
    }

    return await _groupRepository.getGroupsByCourse(courseId);
  }
}
