import '../../domain/entities/assignment_entity.dart';
import '../../domain/repositories/i_assignment_repository.dart';
import '../datasources/remote/assignment_remote_datasource.dart';
import '../datasources/models/assignment_model.dart';

/// Implementation of IAssignmentRepository
/// Handles conversion between models and entities
class AssignmentRepositoryImpl implements IAssignmentRepository {
  final AssignmentRemoteDataSource remoteDataSource;

  AssignmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AssignmentEntity>> getAssignmentsByCourse(String courseId) async {
    try {
      final assignmentModels = await remoteDataSource.getAssignmentsByCourse(
        courseId,
      );
      return assignmentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AssignmentEntity>> getAssignmentsByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      final assignmentModels = await remoteDataSource.getAssignmentsByGroup(
        courseId,
        groupId,
      );
      return assignmentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AssignmentEntity?> getAssignmentById(String assignmentId) async {
    try {
      final assignmentModel = await remoteDataSource.getAssignmentById(
        assignmentId,
      );
      return assignmentModel?.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AssignmentEntity>> getOpenAssignments(String courseId) async {
    try {
      final assignmentModels = await remoteDataSource.getOpenAssignments(
        courseId,
      );
      return assignmentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<AssignmentEntity>> getUpcomingAssignments(
    String courseId,
    int daysAhead,
  ) async {
    try {
      final assignmentModels = await remoteDataSource.getUpcomingAssignments(
        courseId,
        daysAhead,
      );
      return assignmentModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AssignmentEntity> createAssignment(AssignmentEntity assignment) async {
    try {
      final assignmentModel = AssignmentModel.fromEntity(assignment);
      final createdModel = await remoteDataSource.createAssignment(
        assignmentModel,
      );
      return createdModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AssignmentEntity> updateAssignment(AssignmentEntity assignment) async {
    try {
      final assignmentModel = AssignmentModel.fromEntity(assignment);
      final updatedModel = await remoteDataSource.updateAssignment(
        assignmentModel,
      );
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await remoteDataSource.deleteAssignment(assignmentId);
    } catch (e) {
      rethrow;
    }
  }
}
