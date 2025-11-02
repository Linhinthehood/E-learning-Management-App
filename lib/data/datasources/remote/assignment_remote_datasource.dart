import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';

/// Remote data source for assignments
/// Handles Firestore calls for assignments
abstract class AssignmentRemoteDataSource {
  /// Get all assignments for a course
  Future<List<AssignmentModel>> getAssignmentsByCourse(String courseId);

  /// Get assignments for a specific group
  Future<List<AssignmentModel>> getAssignmentsByGroup(
    String courseId,
    String groupId,
  );

  /// Get a single assignment by ID
  Future<AssignmentModel?> getAssignmentById(String assignmentId);

  /// Get open assignments (currently accepting submissions)
  Future<List<AssignmentModel>> getOpenAssignments(String courseId);

  /// Get upcoming assignments
  Future<List<AssignmentModel>> getUpcomingAssignments(
    String courseId,
    int daysAhead,
  );

  /// Create a new assignment
  Future<AssignmentModel> createAssignment(AssignmentModel assignment);

  /// Update an existing assignment
  Future<AssignmentModel> updateAssignment(AssignmentModel assignment);

  /// Delete an assignment
  Future<void> deleteAssignment(String assignmentId);
}

/// Implementation of AssignmentRemoteDataSource using Firestore
class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<AssignmentModel>> getAssignmentsByCourse(String courseId) async {
    try {
      // Get all assignments for the course (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      final assignments = querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory by deadline
      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));

      return assignments;
    } catch (e) {
      throw Exception('Failed to get assignments: ${e.toString()}');
    }
  }

  @override
  Future<List<AssignmentModel>> getAssignmentsByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      // Get assignments for the course and group (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .where('scopedGroupIds', arrayContains: groupId)
          .get();

      final assignments = querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory by deadline
      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));

      return assignments;
    } catch (e) {
      throw Exception('Failed to get group assignments: ${e.toString()}');
    }
  }

  @override
  Future<AssignmentModel?> getAssignmentById(String assignmentId) async {
    try {
      final docSnapshot = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return AssignmentModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get assignment: ${e.toString()}');
    }
  }

  @override
  Future<List<AssignmentModel>> getOpenAssignments(String courseId) async {
    try {
      final now = DateTime.now();
      final nowTimestamp = Timestamp.fromDate(now);

      // Get assignments and filter in memory (without complex orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      final assignments = querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .where((assignment) {
            final startDateTimestamp = Timestamp.fromDate(assignment.startDate);
            final deadlineTimestamp = Timestamp.fromDate(assignment.deadline);
            return startDateTimestamp.compareTo(nowTimestamp) <= 0 &&
                deadlineTimestamp.compareTo(nowTimestamp) > 0;
          })
          .toList();

      // Sort in memory by deadline
      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));

      return assignments;
    } catch (e) {
      throw Exception('Failed to get open assignments: ${e.toString()}');
    }
  }

  @override
  Future<List<AssignmentModel>> getUpcomingAssignments(
    String courseId,
    int daysAhead,
  ) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));
      final nowTimestamp = Timestamp.fromDate(now);
      final futureTimestamp = Timestamp.fromDate(futureDate);

      // Get assignments and filter in memory (without complex orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .get();

      final assignments = querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .where((assignment) {
            final startDateTimestamp = Timestamp.fromDate(assignment.startDate);
            return startDateTimestamp.compareTo(nowTimestamp) > 0 &&
                startDateTimestamp.compareTo(futureTimestamp) <= 0;
          })
          .toList();

      // Sort in memory by startDate
      assignments.sort((a, b) => a.startDate.compareTo(b.startDate));

      return assignments;
    } catch (e) {
      throw Exception('Failed to get upcoming assignments: ${e.toString()}');
    }
  }

  @override
  Future<AssignmentModel> createAssignment(AssignmentModel assignment) async {
    try {
      final docRef = await _firestore
          .collection('assignments')
          .add(assignment.toJson());

      final docSnapshot = await docRef.get();
      return AssignmentModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create assignment: ${e.toString()}');
    }
  }

  @override
  Future<AssignmentModel> updateAssignment(AssignmentModel assignment) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignment.id)
          .update(assignment.toJson());

      return assignment;
    } catch (e) {
      throw Exception('Failed to update assignment: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete assignment: ${e.toString()}');
    }
  }
}
