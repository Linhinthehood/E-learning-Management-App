import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/quiz_entity.dart';
import '../../../../domain/entities/quiz_attempt_entity.dart';

/// Dialog to show detailed quiz answers for a student attempt
class QuizAnswerDetailDialog extends StatelessWidget {
  final QuizEntity quiz;
  final QuizAttemptEntity attempt;

  const QuizAnswerDetailDialog({
    super.key,
    required this.quiz,
    required this.attempt,
  });

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
                      if (attempt.score != null)
                        Text(
                          'Score: ${attempt.score!.toStringAsFixed(1)}/${attempt.maxScore.toStringAsFixed(1)} (${attempt.percentage!.toStringAsFixed(1)}%)',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppColors.buttonPrimary,
                            fontWeight: FontWeight.w600,
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
    // Note: This is a simplified version
    // In a real implementation, you would need to:
    // 1. Load the actual questions from the quiz structure
    // 2. Match student answers with questions
    // 3. Show correct/incorrect indicators

    if (attempt.answers.isEmpty) {
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
      itemCount: attempt.answers.length,
      itemBuilder: (context, index) {
        final entry = attempt.answers.entries.elementAt(index);
        final questionId = entry.key;
        final studentAnswer = entry.value;

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
                    // Note: In real implementation, check if answer is correct
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Question ID: $questionId',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Student Answer: ${studentAnswer.toString()}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Correct Answer: [To be loaded from question bank]',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
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
