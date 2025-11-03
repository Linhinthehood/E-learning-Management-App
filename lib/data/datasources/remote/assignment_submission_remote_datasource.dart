import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_submission_model.dart';

/// Remote datasource for assignment submissions
class AssignmentSubmissionRemoteDatasource {
  final FirebaseFirestore _firestore;

  AssignmentSubmissionRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new submission
  Future<String> createSubmission(AssignmentSubmissionModel submission) async {
    try {
      final docRef = await _firestore
          .collection('assignmentSubmissions')
          .add(submission.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create submission: ${e.toString()}');
    }
  }

  /// Get submissions for an assignment
  Future<List<AssignmentSubmissionModel>> getSubmissionsByAssignment(
    String assignmentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final submissions = querySnapshot.docs
          .map((doc) => AssignmentSubmissionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by submission time descending
      submissions.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));

      return submissions;
    } catch (e) {
      throw Exception('Failed to get submissions: ${e.toString()}');
    }
  }

  /// Get submissions by a student for an assignment
  Future<List<AssignmentSubmissionModel>> getStudentSubmissions(
    String assignmentId,
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .get();

      final submissions = querySnapshot.docs
          .map((doc) => AssignmentSubmissionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by attempt number
      submissions.sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));

      return submissions;
    } catch (e) {
      throw Exception('Failed to get student submissions: ${e.toString()}');
    }
  }

  /// Get a specific submission
  Future<AssignmentSubmissionModel?> getSubmission(String submissionId) async {
    try {
      final doc = await _firestore
          .collection('assignmentSubmissions')
          .doc(submissionId)
          .get();

      if (!doc.exists) return null;

      return AssignmentSubmissionModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get submission: ${e.toString()}');
    }
  }

  /// Update submission (for grading)
  Future<void> updateSubmission(
    String submissionId,
    AssignmentSubmissionModel submission,
  ) async {
    try {
      await _firestore
          .collection('assignmentSubmissions')
          .doc(submissionId)
          .update(submission.toJson());
    } catch (e) {
      throw Exception('Failed to update submission: ${e.toString()}');
    }
  }

  /// Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    try {
      await _firestore
          .collection('assignmentSubmissions')
          .doc(submissionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete submission: ${e.toString()}');
    }
  }

  /// Get student's latest submission for an assignment
  Future<AssignmentSubmissionModel?> getLatestSubmission(
    String assignmentId,
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final submissions = querySnapshot.docs
          .map((doc) => AssignmentSubmissionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by attempt number descending and get the first (latest)
      submissions.sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));

      return submissions.first;
    } catch (e) {
      throw Exception('Failed to get latest submission: ${e.toString()}');
    }
  }

  /// Get all submissions by a student across all assignments
  Future<List<AssignmentSubmissionModel>> getAllStudentSubmissions(
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignmentSubmissions')
          .where('studentId', isEqualTo: studentId)
          .get();

      final submissions = querySnapshot.docs
          .map((doc) => AssignmentSubmissionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by submission time descending
      submissions.sort((a, b) => b.submissionTime.compareTo(a.submissionTime));

      return submissions;
    } catch (e) {
      throw Exception('Failed to get all student submissions: ${e.toString()}');
    }
  }
}
