import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/quiz_entity.dart';
import '../../../domain/entities/quiz_attempt_entity.dart';
import '../../../domain/entities/question_entity.dart';
import '../../common/styles/colors.dart';
import '../../providers/quiz_attempt_provider.dart';
import '../../providers/question_provider.dart';
import '../../providers/auth_provider.dart';

/// Screen for taking a quiz
class QuizTakingScreen extends ConsumerStatefulWidget {
  final QuizEntity quiz;
  final QuizAttemptEntity? existingAttempt; // Resume if in progress

  const QuizTakingScreen({super.key, required this.quiz, this.existingAttempt});

  @override
  ConsumerState<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen> {
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _answers = {};
  List<QuestionEntity> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  QuizAttemptEntity? _currentAttempt;
  Timer? _timer;
  DateTime? _endTime;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeQuiz() async {
    try {
      // Load questions for the quiz
      await _loadQuestions();

      // Initialize or resume attempt
      if (widget.existingAttempt != null) {
        // Resume existing attempt
        _currentAttempt = widget.existingAttempt;
        _answers = Map<String, dynamic>.from(_currentAttempt!.answers);
      } else {
        // Create new attempt
        await _createNewAttempt();
      }

      // Start timer if quiz has time limit
      if (widget.quiz.hasTimeLimit && _currentAttempt != null) {
        _startTimer();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadQuestions() async {
    final List<QuestionEntity> allQuestions = [];
    final repository = ref.read(questionRepositoryProvider);

    for (final section in widget.quiz.structure.sections) {
      if (section.usesQuestionBank && section.questionBankId != null) {
        // Load questions from question bank
        final bankQuestions = await repository.getQuestionsByBank(
          section.questionBankId!,
        );

        // Shuffle and take required number
        if (widget.quiz.shuffleQuestions) {
          bankQuestions.shuffle();
        }
        allQuestions.addAll(bankQuestions.take(section.numQuestions));
      } else if (section.usesSpecificQuestions &&
          section.specificQuestionIds != null) {
        // Load specific questions
        for (final questionId in section.specificQuestionIds!) {
          final question = await repository.getQuestionById(questionId);
          if (question != null) {
            allQuestions.add(question);
          }
        }
      }
    }

    // Shuffle questions if enabled
    if (widget.quiz.shuffleQuestions) {
      allQuestions.shuffle();
    }

    _questions = allQuestions;
  }

  Future<void> _createNewAttempt() async {
    final user = ref.read(authProvider).value;
    if (user == null) throw Exception('User not logged in');

    // Count existing attempts
    final attemptCount = await ref
        .read(quizAttemptProvider.notifier)
        .countStudentAttempts(widget.quiz.id, user.uid);

    // Calculate max score
    final maxScore = _questions.fold<double>(0, (sum, q) => sum + q.points);

    final attempt = QuizAttemptEntity(
      id: '',
      quizId: widget.quiz.id,
      studentId: user.uid,
      courseId: widget.quiz.courseId,
      attemptNumber: attemptCount + 1,
      startTime: DateTime.now(),
      answers: {},
      maxScore: maxScore,
      status: QuizAttemptStatus.inProgress,
      autoGraded: true,
    );

    final attemptId = await ref
        .read(quizAttemptProvider.notifier)
        .createAttempt(attempt);

    _currentAttempt = attempt.copyWith(id: attemptId);
  }

  void _startTimer() {
    if (_currentAttempt == null) return;

    final duration = Duration(minutes: widget.quiz.durationMinutes);
    _endTime = _currentAttempt!.startTime.add(duration);
    _remainingTime = _endTime!.difference(DateTime.now());

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime = _endTime!.difference(DateTime.now());
          if (_remainingTime.isNegative) {
            _timer?.cancel();
            _autoSubmitQuiz();
          }
        });
      }
    });
  }

  Future<void> _autoSubmitQuiz() async {
    if (_isSubmitting || _currentAttempt == null) return;
    await _submitQuiz();
  }

  Future<void> _saveProgress() async {
    if (_currentAttempt == null) return;

    try {
      final updatedAttempt = _currentAttempt!.copyWith(
        answers: Map<String, dynamic>.from(_answers),
      );

      await ref
          .read(quizAttemptProvider.notifier)
          .updateAttempt(updatedAttempt);

      _currentAttempt = updatedAttempt;
    } catch (e) {
      // Silently fail on auto-save
    }
  }

  void _answerQuestion(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
    });
    // Auto-save after answering
    _saveProgress();
  }

  Future<void> _submitQuiz() async {
    if (_currentAttempt == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate score for auto-gradable questions
      double score = 0.0;
      for (final question in _questions) {
        final answer = _answers[question.id];
        if (answer == null) continue;

        if (_isAnswerCorrect(question, answer)) {
          score += question.points;
        }
      }

      final updatedAttempt = _currentAttempt!.copyWith(
        endTime: DateTime.now(),
        answers: Map<String, dynamic>.from(_answers),
        score: score,
        status: QuizAttemptStatus.graded,
      );

      await ref
          .read(quizAttemptProvider.notifier)
          .updateAttempt(updatedAttempt);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quiz submitted! Score: ${score.toStringAsFixed(1)}/${updatedAttempt.maxScore}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting quiz: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _isAnswerCorrect(QuestionEntity question, dynamic answer) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return answer == question.correctAnswer;
      case QuestionType.trueFalse:
        return answer.toString().toLowerCase() ==
            question.correctAnswer.toString().toLowerCase();
      case QuestionType.multipleResponse:
        if (answer is! List || question.correctAnswer is! List) return false;
        final answerList = List<int>.from(answer);
        final correctList = List<int>.from(question.correctAnswer);
        if (answerList.length != correctList.length) return false;
        answerList.sort();
        correctList.sort();
        return answerList.toString() == correctList.toString();
      case QuestionType.shortAnswer:
        // Case-insensitive comparison, trim whitespace
        return answer.toString().trim().toLowerCase() ==
            question.correctAnswer.toString().trim().toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            widget.quiz.title,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Text(
            'No questions available',
            style: GoogleFonts.inter(fontSize: 18),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exit Quiz?',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Your progress will be saved. You can continue later.',
              style: GoogleFonts.inter(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: GoogleFonts.inter()),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveProgress();
                  Navigator.of(context).pop(true);
                },
                child: Text('Exit', style: GoogleFonts.inter()),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.quiz.title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            if (widget.quiz.hasTimeLimit)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _remainingTime.inMinutes < 5
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 18,
                        color: _remainingTime.inMinutes < 5
                            ? Colors.red
                            : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_remainingTime),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _remainingTime.inMinutes < 5
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.buttonPrimary,
              ),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildQuestionCard(currentQuestion),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Previous',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (_currentQuestionIndex <
                                  _questions.length - 1) {
                                setState(() {
                                  _currentQuestionIndex++;
                                });
                              } else {
                                _confirmSubmit();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentQuestionIndex < _questions.length - 1
                                  ? 'Next'
                                  : 'Submit Quiz',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuestionEntity question) {
    return Card(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      question.difficulty,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.difficulty.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(question.difficulty),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${question.points} ${question.points == 1 ? "point" : "points"}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question text
            Text(
              question.questionText,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Answer options based on question type
            _buildAnswerOptions(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(QuestionEntity question) {
    final currentAnswer = _answers[question.id];

    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOptions(question, currentAnswer);
      case QuestionType.trueFalse:
        return _buildTrueFalseOptions(question, currentAnswer);
      case QuestionType.multipleResponse:
        return _buildMultipleResponseOptions(question, currentAnswer);
      case QuestionType.shortAnswer:
        return _buildShortAnswerField(question, currentAnswer);
    }
  }

  Widget _buildMultipleChoiceOptions(
    QuestionEntity question,
    dynamic currentAnswer,
  ) {
    final options = widget.quiz.shuffleAnswers
        ? (List<String>.from(question.options)..shuffle())
        : question.options;

    return Column(
      children: List.generate(options.length, (index) {
        final option = options[index];
        final originalIndex = question.options.indexOf(option);
        final isSelected = currentAnswer == originalIndex;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _answerQuestion(question.id, originalIndex),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.buttonPrimary.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.buttonPrimary
                      : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // ignore: deprecated_member_use
                  Radio<int>(
                    value: originalIndex,
                    // ignore: deprecated_member_use
                    groupValue: currentAnswer,
                    // ignore: deprecated_member_use
                    onChanged: (value) => _answerQuestion(question.id, value),
                    activeColor: AppColors.buttonPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTrueFalseOptions(
    QuestionEntity question,
    dynamic currentAnswer,
  ) {
    return Column(
      children: [
        _buildTrueFalseOption(question, 'True', currentAnswer),
        const SizedBox(height: 12),
        _buildTrueFalseOption(question, 'False', currentAnswer),
      ],
    );
  }

  Widget _buildTrueFalseOption(
    QuestionEntity question,
    String option,
    dynamic currentAnswer,
  ) {
    final isSelected =
        currentAnswer?.toString().toLowerCase() == option.toLowerCase();

    return InkWell(
      onTap: () => _answerQuestion(question.id, option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonPrimary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.buttonPrimary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<String>(
              value: option,
              // ignore: deprecated_member_use
              groupValue: currentAnswer?.toString(),
              // ignore: deprecated_member_use
              onChanged: (value) => _answerQuestion(question.id, value),
              activeColor: AppColors.buttonPrimary,
            ),
            const SizedBox(width: 12),
            Text(
              option,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleResponseOptions(
    QuestionEntity question,
    dynamic currentAnswer,
  ) {
    final selectedIndices = currentAnswer is List
        ? List<int>.from(currentAnswer)
        : <int>[];

    final options = widget.quiz.shuffleAnswers
        ? (List<String>.from(question.options)..shuffle())
        : question.options;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select all that apply:',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(options.length, (index) {
          final option = options[index];
          final originalIndex = question.options.indexOf(option);
          final isSelected = selectedIndices.contains(originalIndex);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                final newSelection = List<int>.from(selectedIndices);
                if (isSelected) {
                  newSelection.remove(originalIndex);
                } else {
                  newSelection.add(originalIndex);
                }
                _answerQuestion(question.id, newSelection);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.buttonPrimary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.buttonPrimary
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        final newSelection = List<int>.from(selectedIndices);
                        if (value == true) {
                          newSelection.add(originalIndex);
                        } else {
                          newSelection.remove(originalIndex);
                        }
                        _answerQuestion(question.id, newSelection);
                      },
                      activeColor: AppColors.buttonPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShortAnswerField(
    QuestionEntity question,
    dynamic currentAnswer,
  ) {
    final controller = TextEditingController(
      text: currentAnswer?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      onChanged: (value) => _answerQuestion(question.id, value),
      maxLines: 3,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        hintText: 'Enter your answer...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.buttonPrimary,
            width: 2,
          ),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 16),
    );
  }

  Color _getDifficultyColor(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return Colors.green;
      case QuestionDifficulty.medium:
        return Colors.orange;
      case QuestionDifficulty.hard:
        return Colors.red;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmSubmit() async {
    final unansweredCount = _questions.length - _answers.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Submit Quiz?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          unansweredCount > 0
              ? 'You have $unansweredCount unanswered question(s). Submit anyway?'
              : 'Are you sure you want to submit?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _submitQuiz();
    }
  }
}
