import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

/// Remote data source for quizzes
/// Handles Firestore calls for quizzes
abstract class QuizRemoteDataSource {
  /// Get all quizzes for a course
  Future<List<QuizModel>> getQuizzesByCourse(String courseId);

  /// Get quizzes for a specific group
  Future<List<QuizModel>> getQuizzesByGroup(String courseId, String groupId);

  /// Get a single quiz by ID
  Future<QuizModel?> getQuizById(String quizId);

  /// Get open quizzes (currently available)
  Future<List<QuizModel>> getOpenQuizzes(String courseId);

  /// Get upcoming quizzes
  Future<List<QuizModel>> getUpcomingQuizzes(String courseId, int daysAhead);

  /// Create a new quiz
  Future<QuizModel> createQuiz(QuizModel quiz);

  /// Update an existing quiz
  Future<QuizModel> updateQuiz(QuizModel quiz);

  /// Delete a quiz
  Future<void> deleteQuiz(String quizId);
}

/// Implementation of QuizRemoteDataSource using Firestore
class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<QuizModel>> getQuizzesByCourse(String courseId) async {
    try {
      // Get all quizzes for the course (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .get();

      final quizzes = querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory by timeClose
      quizzes.sort((a, b) => a.timeClose.compareTo(b.timeClose));

      return quizzes;
    } catch (e) {
      throw Exception('Failed to get quizzes: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizModel>> getQuizzesByGroup(
    String courseId,
    String groupId,
  ) async {
    try {
      // Get quizzes for the course and group (without orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .where('scopedGroupIds', arrayContains: groupId)
          .get();

      final quizzes = querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory by timeClose
      quizzes.sort((a, b) => a.timeClose.compareTo(b.timeClose));

      return quizzes;
    } catch (e) {
      throw Exception('Failed to get group quizzes: ${e.toString()}');
    }
  }

  @override
  Future<QuizModel?> getQuizById(String quizId) async {
    try {
      final docSnapshot = await _firestore
          .collection('quizzes')
          .doc(quizId)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return QuizModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get quiz: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizModel>> getOpenQuizzes(String courseId) async {
    try {
      final now = DateTime.now();
      final nowTimestamp = Timestamp.fromDate(now);

      // Get quizzes and filter in memory (without complex orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .get();

      final quizzes = querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .where((quiz) {
            final timeOpenTimestamp = Timestamp.fromDate(quiz.timeOpen);
            final timeCloseTimestamp = Timestamp.fromDate(quiz.timeClose);
            return timeOpenTimestamp.compareTo(nowTimestamp) <= 0 &&
                timeCloseTimestamp.compareTo(nowTimestamp) > 0;
          })
          .toList();

      // Sort in memory by timeClose
      quizzes.sort((a, b) => a.timeClose.compareTo(b.timeClose));

      return quizzes;
    } catch (e) {
      throw Exception('Failed to get open quizzes: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizModel>> getUpcomingQuizzes(
    String courseId,
    int daysAhead,
  ) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));
      final nowTimestamp = Timestamp.fromDate(now);
      final futureTimestamp = Timestamp.fromDate(futureDate);

      // Get quizzes and filter in memory (without complex orderBy to avoid index requirement)
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .get();

      final quizzes = querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .where((quiz) {
            final timeOpenTimestamp = Timestamp.fromDate(quiz.timeOpen);
            return timeOpenTimestamp.compareTo(nowTimestamp) > 0 &&
                timeOpenTimestamp.compareTo(futureTimestamp) <= 0;
          })
          .toList();

      // Sort in memory by timeOpen
      quizzes.sort((a, b) => a.timeOpen.compareTo(b.timeOpen));

      return quizzes;
    } catch (e) {
      throw Exception('Failed to get upcoming quizzes: ${e.toString()}');
    }
  }

  @override
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    try {
      final docRef = await _firestore.collection('quizzes').add(quiz.toJson());

      final docSnapshot = await docRef.get();
      return QuizModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create quiz: ${e.toString()}');
    }
  }

  @override
  Future<QuizModel> updateQuiz(QuizModel quiz) async {
    try {
      await _firestore.collection('quizzes').doc(quiz.id).update(quiz.toJson());

      return quiz;
    } catch (e) {
      throw Exception('Failed to update quiz: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).delete();
    } catch (e) {
      throw Exception('Failed to delete quiz: ${e.toString()}');
    }
  }
}
