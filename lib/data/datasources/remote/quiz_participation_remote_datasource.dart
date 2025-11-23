import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_participation_model.dart';

/// Remote data source for quiz participation tracking
abstract class QuizParticipationRemoteDataSource {
  /// Join quiz (mark student as active participant)
  Future<void> joinQuiz(String quizId, String studentId);

  /// Leave quiz (mark student as inactive)
  Future<void> leaveQuiz(String quizId, String studentId);

  /// Get active participant count for a quiz
  Stream<int> listenToParticipantCount(String quizId);

  /// Get list of active participants
  Stream<List<QuizParticipationModel>> listenToActiveParticipants(
    String quizId,
  );
}

/// Implementation using Firestore
class QuizParticipationRemoteDataSourceImpl
    implements QuizParticipationRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> joinQuiz(String quizId, String studentId) async {
    try {
      final docId = '${quizId}_$studentId';
      await _firestore.collection('quizParticipation').doc(docId).set({
        'quizId': quizId,
        'studentId': studentId,
        'joinedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      throw Exception('Failed to join quiz: ${e.toString()}');
    }
  }

  @override
  Future<void> leaveQuiz(String quizId, String studentId) async {
    try {
      final docId = '${quizId}_$studentId';
      await _firestore.collection('quizParticipation').doc(docId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to leave quiz: ${e.toString()}');
    }
  }

  @override
  Stream<int> listenToParticipantCount(String quizId) {
    try {
      return _firestore
          .collection('quizParticipation')
          .where('quizId', isEqualTo: quizId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      throw Exception('Failed to listen to participant count: ${e.toString()}');
    }
  }

  @override
  Stream<List<QuizParticipationModel>> listenToActiveParticipants(
    String quizId,
  ) {
    try {
      return _firestore
          .collection('quizParticipation')
          .where('quizId', isEqualTo: quizId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map(
                  (doc) => QuizParticipationModel.fromJson(doc.data(), doc.id),
                )
                .toList();
          });
    } catch (e) {
      throw Exception(
        'Failed to listen to active participants: ${e.toString()}',
      );
    }
  }
}
