import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/assignment_remote_datasource.dart';
import '../../data/repositories/assignment_repository_impl.dart';
import '../../domain/entities/assignment_entity.dart';
import '../../domain/repositories/i_assignment_repository.dart';

/// Provider for assignment remote data source
final assignmentRemoteDataSourceProvider = Provider<AssignmentRemoteDataSource>(
  (ref) {
    return AssignmentRemoteDataSourceImpl();
  },
);

/// Provider for assignment repository
final assignmentRepositoryProvider = Provider<IAssignmentRepository>((ref) {
  return AssignmentRepositoryImpl(
    remoteDataSource: ref.read(assignmentRemoteDataSourceProvider),
  );
});

/// Assignment state notifier - manages assignments for a course
class AssignmentNotifier
    extends StateNotifier<AsyncValue<List<AssignmentEntity>>> {
  final IAssignmentRepository _repository;
  String? _currentCourseId;

  AssignmentNotifier(this._repository) : super(const AsyncValue.loading());

  /// Load assignments for a course
  Future<void> loadAssignments(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final assignments = await _repository.getAssignmentsByCourse(courseId);
      state = AsyncValue.data(assignments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load assignments for a specific group
  Future<void> loadGroupAssignments(String courseId, String groupId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final assignments = await _repository.getAssignmentsByGroup(
        courseId,
        groupId,
      );
      state = AsyncValue.data(assignments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load open assignments (currently accepting submissions)
  Future<void> loadOpenAssignments(String courseId) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final assignments = await _repository.getOpenAssignments(courseId);
      state = AsyncValue.data(assignments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Load upcoming assignments
  Future<void> loadUpcomingAssignments(String courseId, int daysAhead) async {
    _currentCourseId = courseId;
    state = const AsyncValue.loading();
    try {
      final assignments = await _repository.getUpcomingAssignments(
        courseId,
        daysAhead,
      );
      state = AsyncValue.data(assignments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new assignment
  /// Returns the created assignment with the generated ID
  Future<AssignmentEntity> createAssignment(AssignmentEntity assignment) async {
    try {
      final createdAssignment = await _repository.createAssignment(assignment);
      if (_currentCourseId != null) {
        await loadAssignments(_currentCourseId!); // Reload list
      }
      return createdAssignment;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing assignment
  Future<void> updateAssignment(AssignmentEntity assignment) async {
    try {
      await _repository.updateAssignment(assignment);
      if (_currentCourseId != null) {
        await loadAssignments(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _repository.deleteAssignment(assignmentId);
      if (_currentCourseId != null) {
        await loadAssignments(_currentCourseId!); // Reload list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh current assignments
  Future<void> refresh() async {
    if (_currentCourseId != null) {
      await loadAssignments(_currentCourseId!);
    }
  }
}

/// Provider for assignment state notifier
final assignmentProvider =
    StateNotifierProvider<
      AssignmentNotifier,
      AsyncValue<List<AssignmentEntity>>
    >((ref) {
      return AssignmentNotifier(ref.read(assignmentRepositoryProvider));
    });

/// Provider for fetching a single assignment by ID
final assignmentByIdProvider = FutureProvider.family<AssignmentEntity?, String>(
  (ref, assignmentId) async {
    final repository = ref.read(assignmentRepositoryProvider);
    return await repository.getAssignmentById(assignmentId);
  },
);
