import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

/// Remote data source for quizzes
/// Handles Firestore calls for quizzes
abstract class QuizRemoteDataSource {
  Future<List<QuizModel>> getQuizzesByCourse(String courseId);
  Future<List<QuizModel>> getQuizzesByGroup(String courseId, String groupId);
  Future<QuizModel?> getQuizById(String quizId);
  Future<List<QuizModel>> getOpenQuizzes(String courseId);
  Future<List<QuizModel>> getUpcomingQuizzes(String courseId, int daysAhead);
  Future<QuizModel> createQuiz(QuizModel quiz);
  Future<QuizModel> updateQuiz(QuizModel quiz);
  Future<void> deleteQuiz(String quizId);
}

/// Implementation of QuizRemoteDataSource using Firestore
class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<QuizModel>> getQuizzesByCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .orderBy('timeOpen', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get quizzes: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizModel>> getQuizzesByGroup(String courseId, String groupId) async {
    try {
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .where('scopedGroupIds', arrayContains: groupId)
          .orderBy('timeOpen', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .toList();
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

      if (!docSnapshot.exists) return null;
      return QuizModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get quiz: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizModel>> getOpenQuizzes(String courseId) async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .where('timeOpen', isLessThanOrEqualTo: now)
          .where('timeClose', isGreaterThanOrEqualTo: now)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get open quizzes: ${e.toString()}');
    }
  }

  @override
  Future<List<QuizModel>> getUpcomingQuizzes(String courseId, int daysAhead) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final querySnapshot = await _firestore
          .collection('quizzes')
          .where('courseId', isEqualTo: courseId)
          .where('timeOpen', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('timeOpen', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
          .orderBy('timeOpen', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => QuizModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming quizzes: ${e.toString()}');
    }
  }

  @override
  Future<QuizModel> createQuiz(QuizModel quiz) async {
    try {
      final docRef = await _firestore
          .collection('quizzes')
          .add(quiz.toJson());

      final docSnapshot = await docRef.get();
      return QuizModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create quiz: ${e.toString()}');
    }
  }

  @override
  Future<QuizModel> updateQuiz(QuizModel quiz) async {
    try {
      await _firestore
          .collection('quizzes')
          .doc(quiz.id)
          .update(quiz.toJson());

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
