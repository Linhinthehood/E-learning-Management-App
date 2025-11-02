import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';

/// Remote data source for assignments
/// Handles Firestore calls for assignments
abstract class AssignmentRemoteDataSource {
  Future<List<AssignmentModel>> getAssignmentsByCourse(String courseId);
  Future<List<AssignmentModel>> getAssignmentsByGroup(
    String courseId,
    String groupId,
  );
  Future<AssignmentModel?> getAssignmentById(String assignmentId);
  Future<List<AssignmentModel>> getOpenAssignments(String courseId);
  Future<List<AssignmentModel>> getUpcomingAssignments(
    String courseId,
    int daysAhead,
  );
  Future<AssignmentModel> createAssignment(AssignmentModel assignment);
  Future<AssignmentModel> updateAssignment(AssignmentModel assignment);
  Future<void> deleteAssignment(String assignmentId);
}

/// Implementation of AssignmentRemoteDataSource using Firestore
class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<AssignmentModel>> getAssignmentsByCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .orderBy('deadline', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .toList();
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
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .where('scopedGroupIds', arrayContains: groupId)
          .orderBy('deadline', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .toList();
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

      if (!docSnapshot.exists) return null;
      return AssignmentModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get assignment: ${e.toString()}');
    }
  }

  @override
  Future<List<AssignmentModel>> getOpenAssignments(String courseId) async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('deadline', isGreaterThanOrEqualTo: now)
          .get();

      return querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .toList();
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

      final querySnapshot = await _firestore
          .collection('assignments')
          .where('courseId', isEqualTo: courseId)
          .where('deadline', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where(
            'deadline',
            isLessThanOrEqualTo: Timestamp.fromDate(futureDate),
          )
          .orderBy('deadline', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AssignmentModel.fromJson(doc.data(), doc.id))
          .toList();
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
