import '../entities/assignment_entity.dart';

/// Assignment repository interface
/// This defines the contract that data layer must implement
abstract class IAssignmentRepository {
  /// Get all assignments for a course
  Future<List<AssignmentEntity>> getAssignmentsByCourse(String courseId);

  /// Get assignments for a specific group
  Future<List<AssignmentEntity>> getAssignmentsByGroup(
    String courseId,
    String groupId,
  );

  /// Get a single assignment by ID
  Future<AssignmentEntity?> getAssignmentById(String assignmentId);

  /// Get open assignments (currently accepting submissions)
  Future<List<AssignmentEntity>> getOpenAssignments(String courseId);

  /// Get upcoming assignments
  Future<List<AssignmentEntity>> getUpcomingAssignments(
    String courseId,
    int daysAhead,
  );

  /// Create a new assignment
  Future<AssignmentEntity> createAssignment(AssignmentEntity assignment);

  /// Update an existing assignment
  Future<AssignmentEntity> updateAssignment(AssignmentEntity assignment);

  /// Delete an assignment
  Future<void> deleteAssignment(String assignmentId);
}
