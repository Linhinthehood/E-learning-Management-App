import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_attempt_model.dart';
import '../../../domain/entities/quiz_attempt_entity.dart';

/// Remote datasource for quiz attempts
class QuizAttemptRemoteDatasource {
  final FirebaseFirestore _firestore;

  QuizAttemptRemoteDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new attempt
  Future<String> createAttempt(QuizAttemptModel attempt) async {
    try {
      final docRef = await _firestore
          .collection('quizAttempts')
          .add(attempt.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create quiz attempt: ${e.toString()}');
    }
  }

  /// Get a specific attempt
  Future<QuizAttemptModel?> getAttempt(String attemptId) async {
    try {
      final doc = await _firestore
          .collection('quizAttempts')
          .doc(attemptId)
          .get();

      if (!doc.exists) return null;

      return QuizAttemptModel.fromJson(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get quiz attempt: ${e.toString()}');
    }
  }

  /// Get all attempts for a quiz
  Future<List<QuizAttemptModel>> getAttemptsByQuiz(String quizId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizAttempts')
          .where('quizId', isEqualTo: quizId)
          .get();

      final attempts = querySnapshot.docs
          .map((doc) => QuizAttemptModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by start time descending
      attempts.sort((a, b) => b.startTime.compareTo(a.startTime));

      return attempts;
    } catch (e) {
      throw Exception('Failed to get quiz attempts: ${e.toString()}');
    }
  }

  /// Get attempts by a student for a quiz
  Future<List<QuizAttemptModel>> getStudentAttempts(
    String quizId,
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizAttempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .get();

      final attempts = querySnapshot.docs
          .map((doc) => QuizAttemptModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by attempt number
      attempts.sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));

      return attempts;
    } catch (e) {
      throw Exception('Failed to get student attempts: ${e.toString()}');
    }
  }

  /// Get student's latest attempt for a quiz
  Future<QuizAttemptModel?> getLatestAttempt(
    String quizId,
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizAttempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final attempts = querySnapshot.docs
          .map((doc) => QuizAttemptModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by attempt number descending and get first (latest)
      attempts.sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));

      return attempts.first;
    } catch (e) {
      throw Exception('Failed to get latest attempt: ${e.toString()}');
    }
  }

  /// Get student's in-progress attempt for a quiz
  Future<QuizAttemptModel?> getInProgressAttempt(
    String quizId,
    String studentId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizAttempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: QuizAttemptStatus.inProgress.name)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      // Should only be one in-progress attempt
      return QuizAttemptModel.fromJson(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Failed to get in-progress attempt: ${e.toString()}');
    }
  }

  /// Update an attempt
  Future<void> updateAttempt(String attemptId, QuizAttemptModel attempt) async {
    try {
      await _firestore
          .collection('quizAttempts')
          .doc(attemptId)
          .update(attempt.toJson());
    } catch (e) {
      throw Exception('Failed to update quiz attempt: ${e.toString()}');
    }
  }

  /// Delete an attempt
  Future<void> deleteAttempt(String attemptId) async {
    try {
      await _firestore.collection('quizAttempts').doc(attemptId).delete();
    } catch (e) {
      throw Exception('Failed to delete quiz attempt: ${e.toString()}');
    }
  }

  /// Get all attempts by a student across all quizzes
  Future<List<QuizAttemptModel>> getAllStudentAttempts(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizAttempts')
          .where('studentId', isEqualTo: studentId)
          .get();

      final attempts = querySnapshot.docs
          .map((doc) => QuizAttemptModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort by start time descending
      attempts.sort((a, b) => b.startTime.compareTo(a.startTime));

      return attempts;
    } catch (e) {
      throw Exception('Failed to get all student attempts: ${e.toString()}');
    }
  }

  /// Count attempts for a student on a quiz
  Future<int> countStudentAttempts(String quizId, String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizAttempts')
          .where('quizId', isEqualTo: quizId)
          .where('studentId', isEqualTo: studentId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to count student attempts: ${e.toString()}');
    }
  }
}
