import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/question_bank_model.dart';
import '../../../domain/entities/question_entity.dart';

/// Remote data source for questions and question banks
/// Handles Firestore calls for question banks and questions
abstract class QuestionRemoteDataSource {
  // Question Bank operations

  /// Get all question banks for a course
  Future<List<QuestionBankModel>> getQuestionBanksByCourse(String courseId);

  /// Get a single question bank by ID
  Future<QuestionBankModel?> getQuestionBankById(String questionBankId);

  /// Create a new question bank
  Future<QuestionBankModel> createQuestionBank(QuestionBankModel questionBank);

  /// Update an existing question bank
  Future<QuestionBankModel> updateQuestionBank(QuestionBankModel questionBank);

  /// Delete a question bank
  Future<void> deleteQuestionBank(String questionBankId);

  // Question operations

  /// Get all questions in a question bank
  Future<List<QuestionModel>> getQuestionsByBank(String questionBankId);

  /// Get a single question by ID
  Future<QuestionModel?> getQuestionById(String questionId);

  /// Get questions by difficulty
  Future<List<QuestionModel>> getQuestionsByDifficulty(
    String questionBankId,
    QuestionDifficulty difficulty,
  );

  /// Get questions by type
  Future<List<QuestionModel>> getQuestionsByType(
    String questionBankId,
    QuestionType type,
  );

  /// Get random questions from bank
  Future<List<QuestionModel>> getRandomQuestions(
    String questionBankId,
    int count,
  );

  /// Create a new question
  Future<QuestionModel> createQuestion(QuestionModel question);

  /// Update an existing question
  Future<QuestionModel> updateQuestion(QuestionModel question);

  /// Delete a question
  Future<void> deleteQuestion(String questionId);
}

/// Implementation of QuestionRemoteDataSource using Firestore
class QuestionRemoteDataSourceImpl implements QuestionRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Question Bank operations

  @override
  Future<List<QuestionBankModel>> getQuestionBanksByCourse(
    String courseId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('questionBanks')
          .where('courseId', isEqualTo: courseId)
          .get();

      final questionBanks = querySnapshot.docs
          .map((doc) => QuestionBankModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory to avoid needing a composite index
      questionBanks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return questionBanks;
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

      if (!docSnapshot.exists) {
        return null;
      }

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
      final updatedQuestionBank = QuestionBankModel(
        id: questionBank.id,
        courseId: questionBank.courseId,
        name: questionBank.name,
        description: questionBank.description,
        createdAt: questionBank.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('questionBanks')
          .doc(questionBank.id)
          .update(updatedQuestionBank.toJson());

      return updatedQuestionBank;
    } catch (e) {
      throw Exception('Failed to update question bank: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteQuestionBank(String questionBankId) async {
    try {
      // First, delete all questions in the question bank
      final questionsSnapshot = await _firestore
          .collection('questions')
          .where('questionBankId', isEqualTo: questionBankId)
          .get();

      final batch = _firestore.batch();
      for (final doc in questionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Then delete the question bank itself
      batch.delete(_firestore.collection('questionBanks').doc(questionBankId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete question bank: ${e.toString()}');
    }
  }

  // Question operations

  @override
  Future<List<QuestionModel>> getQuestionsByBank(String questionBankId) async {
    try {
      final querySnapshot = await _firestore
          .collection('questions')
          .where('questionBankId', isEqualTo: questionBankId)
          .get();

      final questions = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory to avoid needing a composite index
      questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return questions;
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

      if (!docSnapshot.exists) {
        return null;
      }

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

      final questions = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory to avoid needing a composite index
      questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return questions;
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

      final questions = querySnapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data(), doc.id))
          .toList();

      // Sort in memory to avoid needing a composite index
      questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return questions;
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
      // Get all questions from the bank
      final allQuestions = await getQuestionsByBank(questionBankId);

      if (allQuestions.isEmpty) {
        return [];
      }

      // If count is greater than available questions, return all
      if (count >= allQuestions.length) {
        return allQuestions;
      }

      // Shuffle and take first N questions
      final shuffled = List<QuestionModel>.from(allQuestions)..shuffle(_random);
      return shuffled.take(count).toList();
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
