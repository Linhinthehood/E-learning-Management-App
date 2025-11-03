import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/question_bank_entity.dart';
import '../../../domain/entities/question_entity.dart';
import '../../common/styles/colors.dart';
import '../../providers/question_provider.dart';
import 'widgets/question_form_dialog.dart';

/// Screen for managing questions within a question bank
class QuestionBankDetailScreen extends ConsumerStatefulWidget {
  final QuestionBankEntity questionBank;

  const QuestionBankDetailScreen({super.key, required this.questionBank});

  @override
  ConsumerState<QuestionBankDetailScreen> createState() =>
      _QuestionBankDetailScreenState();
}

class _QuestionBankDetailScreenState
    extends ConsumerState<QuestionBankDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(questionProvider.notifier)
            .loadQuestions(widget.questionBank.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.questionBank.name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Question Bank',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: questionsAsync.when(
        data: (questions) {
          return Column(
            children: [
              // Header with stats and add button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.questionBank.description ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stats
                        Wrap(
                          spacing: 24,
                          children: [
                            _buildStat(
                              'Total Questions',
                              questions.length.toString(),
                              Icons.quiz,
                            ),
                            _buildStat(
                              'Easy',
                              questions
                                  .where(
                                    (q) =>
                                        q.difficulty == QuestionDifficulty.easy,
                                  )
                                  .length
                                  .toString(),
                              Icons.circle,
                              color: Colors.green,
                            ),
                            _buildStat(
                              'Medium',
                              questions
                                  .where(
                                    (q) =>
                                        q.difficulty ==
                                        QuestionDifficulty.medium,
                                  )
                                  .length
                                  .toString(),
                              Icons.circle,
                              color: Colors.orange,
                            ),
                            _buildStat(
                              'Hard',
                              questions
                                  .where(
                                    (q) =>
                                        q.difficulty == QuestionDifficulty.hard,
                                  )
                                  .length
                                  .toString(),
                              Icons.circle,
                              color: Colors.red,
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showQuestionDialog(context, null),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            'Add Question',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Questions list
              Expanded(
                child: questions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No questions yet',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add questions to use in your quizzes',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return _buildQuestionCard(
                            context,
                            question,
                            index + 1,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading questions: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(questionProvider.notifier)
                      .loadQuestions(widget.questionBank.id);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    QuestionEntity question,
    int number,
  ) {
    final difficultyColor = _getDifficultyColor(question.difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with number, type, difficulty
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.buttonPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q$number',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.buttonPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getQuestionTypeLabel(question.type),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: difficultyColor),
                      const SizedBox(width: 6),
                      Text(
                        _getDifficultyLabel(question.difficulty),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: difficultyColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${question.points} pts',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                      onTap: () {
                        final navigatorContext = context;
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted && navigatorContext.mounted) {
                            _showQuestionDialog(navigatorContext, question);
                          }
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onTap: () {
                        final navigatorContext = context;
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted && navigatorContext.mounted) {
                            _deleteQuestion(navigatorContext, question);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question text
            Text(
              question.questionText,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Options for multiple choice/response
            if (question.type == QuestionType.multipleChoice ||
                question.type == QuestionType.multipleResponse)
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isCorrect = question.type == QuestionType.multipleChoice
                    ? question.correctAnswerIndex == index
                    : (question.correctAnswer is List &&
                          (question.correctAnswer as List).contains(index));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border.all(
                            color: isCorrect ? Colors.green : AppColors.border,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: isCorrect
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.green,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            // True/False answer
            if (question.type == QuestionType.trueFalse)
              Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Correct Answer: ${question.correctAnswerText}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

            // Short answer
            if (question.type == QuestionType.shortAnswer)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Expected Answer: ${question.correctAnswerText}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Explanation
            if (question.hasExplanation) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.buttonPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.buttonPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.buttonPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.explanation!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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

  String _getDifficultyLabel(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
    }
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True/False';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.multipleResponse:
        return 'Multiple Response';
    }
  }

  void _showQuestionDialog(BuildContext context, QuestionEntity? question) {
    showDialog(
      context: context,
      builder: (context) => QuestionFormDialog(
        questionBank: widget.questionBank,
        question: question,
      ),
    ).then((success) {
      if (mounted && success == true) {
        ref
            .read(questionProvider.notifier)
            .loadQuestions(widget.questionBank.id);
      }
    });
  }

  void _deleteQuestion(BuildContext context, QuestionEntity question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Question',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this question? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(questionProvider.notifier)
                    .deleteQuestion(question.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
