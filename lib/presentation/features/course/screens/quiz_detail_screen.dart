import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/styles/colors.dart';
import '../../../../domain/entities/course_entity.dart';
import '../../../../domain/entities/quiz_entity.dart';
import '../../../providers/quiz_attempt_provider.dart';
import '../../../providers/auth_provider.dart';

/// Quiz Detail Screen for Students - View attempt history and scores
class QuizDetailScreen extends ConsumerStatefulWidget {
  final CourseEntity course;
  final QuizEntity quiz;

  const QuizDetailScreen({
    super.key,
    required this.course,
    required this.quiz,
  });

  @override
  ConsumerState<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends ConsumerState<QuizDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userId = ref.read(authProvider).value?.uid;
        if (userId != null) {
          ref.read(quizAttemptProvider.notifier).loadStudentAttempts(
            widget.quiz.id,
            userId,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.read(authProvider);
    final currentUserId = userAsync.value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: currentUserId == null
          ? const Center(child: Text('Please log in'))
          : ref.watch(quizAttemptProvider).when(
              data: (allAttempts) {
                // Filter attempts for current student
                final attempts = allAttempts
                    .where((a) => a.studentId == currentUserId)
                    .toList()
                  ..sort((a, b) => b.attemptNumber.compareTo(a.attemptNumber));
                final bestAttempt = attempts.isNotEmpty
                    ? attempts.reduce((a, b) =>
                        (a.score ?? 0) > (b.score ?? 0) ? a : b)
                    : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quiz info
                      Card(
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
                              Text(
                                widget.quiz.title,
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.quiz.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.quiz.isOpen
                                              ? Colors.green.withValues(alpha: 0.1)
                                              : widget.quiz.isClosed
                                                  ? Colors.red.withValues(alpha: 0.1)
                                                  : Colors.orange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          widget.quiz.isOpen
                                              ? 'Open'
                                              : widget.quiz.isClosed
                                                  ? 'Closed'
                                                  : 'Upcoming',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: widget.quiz.isOpen
                                                ? Colors.green
                                                : widget.quiz.isClosed
                                                    ? Colors.red
                                                    : Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Closes: ${_formatDateTime(widget.quiz.timeClose)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.quiz,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.quiz.structure.totalQuestions} questions',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Best score summary
                      if (bestAttempt != null) ...[
                        Card(
                          color: Colors.blue.withValues(alpha: 0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.blue),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events, size: 32, color: Colors.blue),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Best Score',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${bestAttempt.score?.toStringAsFixed(1)} / ${bestAttempt.maxScore} (${bestAttempt.percentage?.toStringAsFixed(1)}%)',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Attempts list
                      Text(
                        'Attempt History (${attempts.length})',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (attempts.isEmpty)
                        Card(
                          color: AppColors.cardBackground,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 48,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No attempts yet',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...attempts.map((attempt) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppColors.cardBackground,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            attempt.isGraded
                                                ? Icons.grading
                                                : attempt.isInProgress
                                                    ? Icons.pending
                                                    : Icons.check_circle,
                                            color: attempt.isGraded
                                                ? Colors.blue
                                                : attempt.isInProgress
                                                    ? Colors.orange
                                                    : Colors.green,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Attempt ${attempt.attemptNumber}',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (attempt.score != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: attempt.isGraded
                                                ? Colors.blue.withValues(alpha: 0.1)
                                                : Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${attempt.score!.toStringAsFixed(1)} / ${attempt.maxScore}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: attempt.isGraded
                                                  ? Colors.blue
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        attempt.endTime != null
                                            ? 'Submitted: ${_formatDateTime(attempt.endTime!)}'
                                            : 'Started: ${_formatDateTime(attempt.startTime)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (attempt.endTime != null && attempt.durationMinutes != null) ...[
                                        const SizedBox(width: 16),
                                        Text(
                                          'Duration: ${attempt.durationMinutes} min',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (attempt.percentage != null) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: attempt.percentage! / 100,
                                      backgroundColor: AppColors.background,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        attempt.isGraded ? Colors.blue : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${attempt.percentage!.toStringAsFixed(1)}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (attempt.feedback != null && attempt.feedback!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Feedback:',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            attempt.feedback!,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
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
                        }),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading attempts'),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(quizAttemptProvider.notifier).loadStudentAttempts(
                          widget.quiz.id,
                          currentUserId,
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

