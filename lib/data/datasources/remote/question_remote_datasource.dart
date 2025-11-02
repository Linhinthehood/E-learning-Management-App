import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_bank_model.dart';
import '../models/question_model.dart';
import '../../../domain/entities/question_entity.dart';

/// Remote data source for questions and question banks
/// Handles Firestore calls for quiz question management
abstract class QuestionRemoteDataSource {
  // Question Bank operations
  Future<List<QuestionBankModel>> getQuestionBanksByCourse(String courseId);
  Future<QuestionBankModel?> getQuestionBankById(String questionBankId);
  Future<QuestionBankModel> createQuestionBank(QuestionBankModel questionBank);
  Future<QuestionBankModel> updateQuestionBank(QuestionBankModel questionBank);
  Future<void> deleteQuestionBank(String questionBankId);

  // Question operations
  Future<List<QuestionModel>> getQuestionsByBank(String questionBankId);
  Future<QuestionModel?> getQuestionById(String questionId);
  Future<List<QuestionModel>> getQuestionsByDifficulty(
    String questionBankId,
    QuestionDifficulty difficulty,
  );
  Future<List<QuestionModel>> getQuestionsByType(
    String questionBankId,
    QuestionType type,
  );
  Future<List<QuestionModel>> getRandomQuestions(
    String questionBankId,
    int count,
  );
  Future<QuestionModel> createQuestion(QuestionModel question);
  Future<QuestionModel> updateQuestion(QuestionModel question);
  Future<void> deleteQuestion(String questionId);
}

/// Implementation of QuestionRemoteDataSource using Firestore
class QuestionRemoteDataSourceImpl implements QuestionRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== Question Bank Operations ====================

  @override
  Future<List<QuestionBankModel>> getQuestionBanksByCourse(
    String courseId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('questionBanks')
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuestionBankModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get question banks: ${e.toString()}');
    }
  }

  @override
  Future<QuestionBankModel?> getQuestionBankById(String questionBankId) async {
    try {
      final docSnapshot = await _firestore
          .collection('questionBanks')
          .doc(questionBankId)
          .get();

      if (!docSnapshot.exists) return null;
      return QuestionBankModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get question bank: ${e.toString()}');
    }
  }

  @override
  Future<QuestionBankModel> createQuestionBank(
    QuestionBankModel questionBank,
  ) async {
    try {
      final docRef = await _firestore
          .collection('questionBanks')
          .add(questionBank.toJson());

      final docSnapshot = await docRef.get();
      return QuestionBankModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create question bank: ${e.toString()}');
    }
  }

  @override
  Future<QuestionBankModel> updateQuestionBank(
    QuestionBankModel questionBank,
  ) async {
    try {
      await _firestore
          .collection('questionBanks')
          .doc(questionBank.id)
          .update(questionBank.toJson());

      return questionBank;
    } catch (e) {
      throw Exception('Failed to update question bank: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteQuestionBank(String questionBankId) async {
    try {
      // Note: This doesn't cascade delete questions
      // Consider adding a check or cascade delete logic if needed
      await _firestore.collection('questionBanks').doc(questionBankId).delete();
    } catch (e) {
      throw Exception('Failed to delete question bank: ${e.toString()}');
    }
  }

  // ==================== Question Operations ====================

  @override
  Future<List<QuestionModel>> getQuestionsByBank(String questionBankId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('questionBankId', isEqualTo: questionBankId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get questions: ${e.toString()}');
    }
  }

  @override
  Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final docSnapshot = await _firestore
          .collection('questions')
          .doc(questionId)
          .get();

      if (!docSnapshot.exists) return null;
      return QuestionModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to get question: ${e.toString()}');
    }
  }

  @override
  Future<List<QuestionModel>> getQuestionsByDifficulty(
    String questionBankId,
    QuestionDifficulty difficulty,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('questionBankId', isEqualTo: questionBankId)
          .where('difficulty', isEqualTo: difficulty.name)
          .get();

      return querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get questions by difficulty: ${e.toString()}');
    }
  }

  @override
  Future<List<QuestionModel>> getQuestionsByType(
    String questionBankId,
    QuestionType type,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('questionBankId', isEqualTo: questionBankId)
          .where('type', isEqualTo: type.name)
          .get();

      return querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get questions by type: ${e.toString()}');
    }
  }

  @override
  Future<List<QuestionModel>> getRandomQuestions(
    String questionBankId,
    int count,
  ) async {
    try {
      // Firestore doesn't have native random sampling, so we fetch all and shuffle
      final allQuestions = await getQuestionsByBank(questionBankId);

      if (allQuestions.isEmpty) return [];

      // Shuffle and take 'count' items
      allQuestions.shuffle();
      return allQuestions.take(count).toList();
    } catch (e) {
      throw Exception('Failed to get random questions: ${e.toString()}');
    }
  }

  @override
  Future<QuestionModel> createQuestion(QuestionModel question) async {
    try {
      final docRef = await _firestore
          .collection('questions')
          .add(question.toJson());

      final docSnapshot = await docRef.get();
      return QuestionModel.fromJson(docSnapshot.data()!, docSnapshot.id);
    } catch (e) {
      throw Exception('Failed to create question: ${e.toString()}');
    }
  }

  @override
  Future<QuestionModel> updateQuestion(QuestionModel question) async {
    try {
      await _firestore
          .collection('questions')
          .doc(question.id)
          .update(question.toJson());

      return question;
    } catch (e) {
      throw Exception('Failed to update question: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
    } catch (e) {
      throw Exception('Failed to delete question: ${e.toString()}');
    }
  }
}
