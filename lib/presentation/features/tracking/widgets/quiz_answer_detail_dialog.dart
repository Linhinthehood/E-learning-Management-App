import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/quiz_entity.dart';
import '../../../../domain/entities/quiz_attempt_entity.dart';
import '../../../../domain/entities/question_entity.dart';
import '../../../providers/question_provider.dart';

/// Dialog to show detailed quiz answers for a student attempt
class QuizAnswerDetailDialog extends ConsumerStatefulWidget {
  final QuizEntity quiz;
  final QuizAttemptEntity attempt;

  const QuizAnswerDetailDialog({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  @override
  ConsumerState<QuizAnswerDetailDialog> createState() =>
      _QuizAnswerDetailDialogState();
}

class _QuizAnswerDetailDialogState
    extends ConsumerState<QuizAnswerDetailDialog> {
  Map<String, QuestionEntity> _questionsMap = {};
  bool _isLoadingQuestions = true;
  Map<String, bool> _isCorrectMap = {};
  double _calculatedScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final repository = ref.read(questionRepositoryProvider);
      final Map<String, QuestionEntity> questionsMap = {};
      double earnedScore = 0.0;

      // Load questions from quiz structure
      for (final section in widget.quiz.structure.sections) {
        if (section.usesQuestionBank && section.questionBankId != null) {
          // Load questions from question bank
          final bankQuestions = await repository.getQuestionsByBank(
            section.questionBankId!,
          );
          for (final question in bankQuestions) {
            questionsMap[question.id] = question;
          }
        } else if (section.usesSpecificQuestions &&
            section.specificQuestionIds != null) {
          // Load specific questions
          for (final questionId in section.specificQuestionIds!) {
            final question = await repository.getQuestionById(questionId);
            if (question != null) {
              questionsMap[question.id] = question;
            }
          }
        }
      }

      // Check answers and calculate score
      final Map<String, bool> isCorrectMap = {};
      for (final entry in widget.attempt.answers.entries) {
        final questionId = entry.key;
        final studentAnswer = entry.value;
        final question = questionsMap[questionId];

        if (question != null) {
          final isCorrect = _checkAnswer(question, studentAnswer);
          isCorrectMap[questionId] = isCorrect;
          if (isCorrect) {
            earnedScore += question.points;
          }
        }
      }

      setState(() {
        _questionsMap = questionsMap;
        _isCorrectMap = isCorrectMap;
        _calculatedScore = earnedScore;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingQuestions = false;
      });
    }
  }

  bool _checkAnswer(QuestionEntity question, dynamic studentAnswer) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        // Student answer should be the index (int)
        if (studentAnswer is int && question.correctAnswer is int) {
          return studentAnswer == question.correctAnswer;
        }
        return false;

      case QuestionType.trueFalse:
        // Student answer should be boolean or string "true"/"false"
        final correctAnswer = question.correctAnswer.toString().toLowerCase();
        final studentAnswerStr = studentAnswer.toString().toLowerCase();
        return correctAnswer == studentAnswerStr ||
            (correctAnswer == 'true' && studentAnswerStr == 'true') ||
            (correctAnswer == 'false' && studentAnswerStr == 'false');

      case QuestionType.shortAnswer:
        // Case-sensitive comparison
        final correctAnswer = question.correctAnswer.toString().trim();
        final studentAnswerStr = studentAnswer.toString().trim();
        return correctAnswer == studentAnswerStr;

      case QuestionType.multipleResponse:
        // Student answer should be List<int>
        if (studentAnswer is List && question.correctAnswer is List) {
          final studentList = studentAnswer.map((e) => e as int).toList()
            ..sort();
          final correctList =
              (question.correctAnswer as List).map((e) => e as int).toList()
                ..sort();
          if (studentList.length != correctList.length) return false;
          for (int i = 0; i < studentList.length; i++) {
            if (studentList[i] != correctList[i]) return false;
          }
          return true;
        }
        return false;
    }
  }

  String _formatCorrectAnswer(QuestionEntity question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        if (question.correctAnswerIndex != null &&
            question.correctAnswerIndex! < question.options.length) {
          return question.options[question.correctAnswerIndex!];
        }
        return 'N/A';

      case QuestionType.trueFalse:
        return question.correctAnswer.toString();

      case QuestionType.shortAnswer:
        return question.correctAnswer.toString();

      case QuestionType.multipleResponse:
        if (question.correctAnswer is List) {
          final indices = (question.correctAnswer as List)
              .map((e) => e as int)
              .toList();
          final answers = indices
              .where((i) => i < question.options.length)
              .map((i) => question.options[i])
              .toList();
          return answers.join(', ');
        }
        return 'N/A';
    }
  }

  String _formatStudentAnswer(QuestionEntity question, dynamic studentAnswer) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        if (studentAnswer is int && studentAnswer < question.options.length) {
          return question.options[studentAnswer];
        }
        return studentAnswer.toString();

      case QuestionType.trueFalse:
        return studentAnswer.toString();

      case QuestionType.shortAnswer:
        return studentAnswer.toString();

      case QuestionType.multipleResponse:
        if (studentAnswer is List) {
          final indices = studentAnswer.map((e) => e as int).toList();
          final answers = indices
              .where((i) => i < question.options.length)
              .map((i) => question.options[i])
              .toList();
          return answers.join(', ');
        }
        return studentAnswer.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quiz Answers',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoadingQuestions
                            ? 'Loading...'
                            : 'Score: ${_calculatedScore.toStringAsFixed(1)}/${widget.attempt.maxScore.toStringAsFixed(1)} (${(_calculatedScore / widget.attempt.maxScore * 100).toStringAsFixed(1)}%)',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.buttonPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.attempt.score != null && !_isLoadingQuestions)
                        Text(
                          'Stored Score: ${widget.attempt.score!.toStringAsFixed(1)}/${widget.attempt.maxScore.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Answers list
            Expanded(child: _buildAnswersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersList() {
    if (_isLoadingQuestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.attempt.answers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No answers available',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.attempt.answers.length,
      itemBuilder: (context, index) {
        final entry = widget.attempt.answers.entries.elementAt(index);
        final questionId = entry.key;
        final studentAnswer = entry.value;
        final question = _questionsMap[questionId];
        final isCorrect = _isCorrectMap[questionId] ?? false;

        if (question == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Question ID: $questionId',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Question not found',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.buttonPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Question ${index + 1}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCorrect ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${question.points.toStringAsFixed(1)} pts',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.questionText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Answer:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatStudentAnswer(question, studentAnswer),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Correct Answer:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCorrectAnswer(question),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
