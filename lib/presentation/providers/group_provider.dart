import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/enrollment_remote_datasource.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/usecases/group/create_group_usecase.dart';
import '../../domain/usecases/group/delete_group_usecase.dart';
import '../../domain/usecases/group/get_groups_by_course_usecase.dart';
import 'enrollment_provider.dart';

/// Provider for enrollment remote data source (used for groups)
final groupRemoteDataSourceProvider = Provider<EnrollmentRemoteDataSource>((
  ref,
) {
  return ref.read(enrollmentRemoteDataSourceProvider);
});

/// Provider for group repository
final groupRepositoryProvider = Provider<GroupRepositoryImpl>((ref) {
  return GroupRepositoryImpl(
    remoteDataSource: ref.read(groupRemoteDataSourceProvider),
  );
});

/// Provider for create group use case
final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  return CreateGroupUseCase(ref.read(groupRepositoryProvider));
});

/// Provider for delete group use case
final deleteGroupUseCaseProvider = Provider<DeleteGroupUseCase>((ref) {
  return DeleteGroupUseCase(ref.read(groupRepositoryProvider));
});

/// Provider for get groups by course use case
final getGroupsByCourseUseCaseProvider = Provider<GetGroupsByCourseUseCase>((
  ref,
) {
  return GetGroupsByCourseUseCase(ref.read(groupRepositoryProvider));
});

/// Group state notifier - manages groups for a course
class GroupNotifier extends StateNotifier<AsyncValue<List<GroupEntity>>> {
  final GetGroupsByCourseUseCase _getGroupsByCourseUseCase;
  final CreateGroupUseCase _createGroupUseCase;
  final DeleteGroupUseCase _deleteGroupUseCase;

  GroupNotifier(
    this._getGroupsByCourseUseCase,
    this._createGroupUseCase,
    this._deleteGroupUseCase,
  ) : super(const AsyncValue.loading());

  /// Load groups for a course
  Future<void> loadGroups(String courseId) async {
    state = const AsyncValue.loading();
    try {
      final groups = await _getGroupsByCourseUseCase.execute(courseId);
      state = AsyncValue.data(groups);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new group
  Future<void> createGroup(GroupEntity group) async {
    try {
      await _createGroupUseCase.execute(group);
      await loadGroups(group.courseId); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a group
  Future<void> deleteGroup(String groupId, String courseId) async {
    try {
      await _deleteGroupUseCase.execute(groupId);
      await loadGroups(courseId); // Reload list
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for group state notifier
final groupProvider =
    StateNotifierProvider<GroupNotifier, AsyncValue<List<GroupEntity>>>((ref) {
      return GroupNotifier(
        ref.read(getGroupsByCourseUseCaseProvider),
        ref.read(createGroupUseCaseProvider),
        ref.read(deleteGroupUseCaseProvider),
      );
    });
